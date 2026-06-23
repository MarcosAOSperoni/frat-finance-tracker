-- Frat Finance Tracker - Supabase Database Setup
-- Run this in Supabase SQL Editor after creating your project

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create ENUM types
CREATE TYPE user_role AS ENUM ('brother', 'vp_finance');
CREATE TYPE brother_status AS ENUM ('active', 'inactive', 'deLettered', 'alumni');
CREATE TYPE invitation_status AS ENUM ('pending', 'accepted', 'expired');
CREATE TYPE dues_status AS ENUM ('pending', 'partial', 'paid', 'overdue');

-- =====================================================
-- TABLES
-- =====================================================

-- 1. Users Profile Table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT,
    phone TEXT,
    role user_role NOT NULL DEFAULT 'brother',
    profile_completed BOOLEAN DEFAULT FALSE,
    must_change_password BOOLEAN DEFAULT FALSE,
    brother_status brother_status DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Invitations Table
CREATE TABLE IF NOT EXISTS invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT NOT NULL,
    invitation_code TEXT NOT NULL UNIQUE,
    invited_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status invitation_status DEFAULT 'pending',
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '7 days'),
    accepted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Dues Periods Table
CREATE TABLE IF NOT EXISTS dues_periods (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    semester TEXT NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    due_date DATE NOT NULL,
    created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Brother Dues Table
CREATE TABLE IF NOT EXISTS brother_dues (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brother_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    dues_period_id UUID NOT NULL REFERENCES dues_periods(id) ON DELETE CASCADE,
    total_amount DECIMAL(10, 2) NOT NULL,
    amount_paid DECIMAL(10, 2) DEFAULT 0,
    status dues_status DEFAULT 'pending',
    due_date DATE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(brother_id, dues_period_id)
);

-- 5. Payments Table
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brother_dues_id UUID NOT NULL REFERENCES brother_dues(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    payment_date DATE NOT NULL,
    payment_method TEXT,
    notes TEXT,
    recorded_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Notification Preferences Table
CREATE TABLE IF NOT EXISTS notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    push_enabled BOOLEAN DEFAULT TRUE,
    email_enabled BOOLEAN DEFAULT TRUE,
    reminder_days INTEGER[] DEFAULT ARRAY[7, 3, 1],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- FUNCTIONS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update brother_dues amount_paid and status when payment is added
CREATE OR REPLACE FUNCTION update_brother_dues_on_payment()
RETURNS TRIGGER AS $$
DECLARE
    total_paid DECIMAL(10, 2);
    total_owed DECIMAL(10, 2);
BEGIN
    -- Calculate total paid for this brother_dues
    SELECT COALESCE(SUM(amount), 0) INTO total_paid
    FROM payments
    WHERE brother_dues_id = NEW.brother_dues_id;

    -- Get total amount owed
    SELECT total_amount INTO total_owed
    FROM brother_dues
    WHERE id = NEW.brother_dues_id;

    -- Update brother_dues
    UPDATE brother_dues
    SET
        amount_paid = total_paid,
        status = CASE
            WHEN total_paid >= total_owed THEN 'paid'::dues_status
            WHEN total_paid > 0 THEN 'partial'::dues_status
            ELSE 'pending'::dues_status
        END,
        updated_at = NOW()
    WHERE id = NEW.brother_dues_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to auto-assign dues to all brothers when new dues_period is created
CREATE OR REPLACE FUNCTION auto_assign_dues_to_brothers()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO brother_dues (brother_id, dues_period_id, total_amount, amount_paid, status, due_date)
    SELECT
        u.id,
        NEW.id,
        NEW.total_amount,
        0,
        'pending'::dues_status,
        NEW.due_date
    FROM users u
    WHERE u.role = 'brother' AND u.profile_completed = TRUE;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to update overdue status
CREATE OR REPLACE FUNCTION update_overdue_status()
RETURNS void AS $$
BEGIN
    UPDATE brother_dues
    SET status = 'overdue'::dues_status
    WHERE status IN ('pending'::dues_status, 'partial'::dues_status)
    AND due_date < CURRENT_DATE;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS
-- =====================================================

-- Trigger: Update updated_at on users
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger: Update updated_at on dues_periods
CREATE TRIGGER update_dues_periods_updated_at
    BEFORE UPDATE ON dues_periods
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger: Update updated_at on brother_dues
CREATE TRIGGER update_brother_dues_updated_at
    BEFORE UPDATE ON brother_dues
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger: Update updated_at on notification_preferences
CREATE TRIGGER update_notification_preferences_updated_at
    BEFORE UPDATE ON notification_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger: Update brother_dues when payment is added
CREATE TRIGGER update_brother_dues_after_payment
    AFTER INSERT ON payments
    FOR EACH ROW
    EXECUTE FUNCTION update_brother_dues_on_payment();

-- Trigger: Auto-assign dues to brothers when new dues_period is created
CREATE TRIGGER auto_assign_dues_on_period_create
    AFTER INSERT ON dues_periods
    FOR EACH ROW
    EXECUTE FUNCTION auto_assign_dues_to_brothers();

-- =====================================================
-- ROW LEVEL SECURITY (RLS)
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE dues_periods ENABLE ROW LEVEL SECURITY;
ALTER TABLE brother_dues ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_preferences ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can view their own profile"
    ON users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "VP of Finance can view all users"
    ON users FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'vp_finance'
        )
    );

CREATE POLICY "Users can update their own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id);

-- Invitations table policies
CREATE POLICY "VP of Finance can manage invitations"
    ON invitations FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'vp_finance'
        )
    );

CREATE POLICY "Anyone can view invitation by code (for signup)"
    ON invitations FOR SELECT
    USING (TRUE);

-- Dues periods table policies
CREATE POLICY "Everyone can view dues periods"
    ON dues_periods FOR SELECT
    USING (TRUE);

CREATE POLICY "VP of Finance can manage dues periods"
    ON dues_periods FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'vp_finance'
        )
    );

-- Brother dues table policies
CREATE POLICY "Brothers can view their own dues"
    ON brother_dues FOR SELECT
    USING (auth.uid() = brother_id);

CREATE POLICY "VP of Finance can view all dues"
    ON brother_dues FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'vp_finance'
        )
    );

CREATE POLICY "VP of Finance can update brother dues"
    ON brother_dues FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'vp_finance'
        )
    );

-- Payments table policies
CREATE POLICY "Brothers can view their own payments"
    ON payments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM brother_dues
            WHERE id = payments.brother_dues_id AND brother_id = auth.uid()
        )
    );

CREATE POLICY "VP of Finance can view all payments"
    ON payments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'vp_finance'
        )
    );

CREATE POLICY "VP of Finance can create payments"
    ON payments FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'vp_finance'
        )
    );

-- Notification preferences table policies
CREATE POLICY "Users can view their own notification preferences"
    ON notification_preferences FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notification preferences"
    ON notification_preferences FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own notification preferences"
    ON notification_preferences FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- INDEXES for Performance
-- =====================================================

CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_invitations_code ON invitations(invitation_code);
CREATE INDEX idx_invitations_email ON invitations(email);
CREATE INDEX idx_brother_dues_brother_id ON brother_dues(brother_id);
CREATE INDEX idx_brother_dues_status ON brother_dues(status);
CREATE INDEX idx_payments_brother_dues_id ON payments(brother_dues_id);

-- =====================================================
-- SEED DATA (Optional - Create first VP of Finance)
-- =====================================================

-- After creating your first user via Supabase Auth, run this:
-- UPDATE users SET role = 'vp_finance' WHERE email = 'your-vp-email@example.com';

-- =====================================================
-- DONE!
-- =====================================================

-- To verify everything is set up correctly, run:
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
