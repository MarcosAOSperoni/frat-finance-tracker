-- Payment Plans Schema
-- Run this SQL in your Supabase SQL Editor

-- ============================================
-- PAYMENT PLANS TABLE
-- ============================================
-- Stores the payment plan configuration for each brother's dues
CREATE TABLE IF NOT EXISTS payment_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  brother_dues_id UUID NOT NULL REFERENCES brother_dues(id) ON DELETE CASCADE,
  total_payments INTEGER NOT NULL CHECK (total_payments >= 1 AND total_payments <= 10),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Ensure only one payment plan per brother_dues
  CONSTRAINT unique_payment_plan_per_dues UNIQUE (brother_dues_id)
);

-- ============================================
-- SCHEDULED PAYMENTS TABLE
-- ============================================
-- Stores individual scheduled payments within a payment plan
CREATE TABLE IF NOT EXISTS scheduled_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_plan_id UUID NOT NULL REFERENCES payment_plans(id) ON DELETE CASCADE,
  payment_number INTEGER NOT NULL CHECK (payment_number >= 1),
  scheduled_amount DECIMAL(10, 2) NOT NULL CHECK (scheduled_amount > 0),
  scheduled_date DATE NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'skipped')),
  paid_amount DECIMAL(10, 2) DEFAULT 0 CHECK (paid_amount >= 0),
  paid_date TIMESTAMP WITH TIME ZONE,
  payment_id UUID REFERENCES payments(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  -- Ensure payment number is unique within a payment plan
  CONSTRAINT unique_payment_number_per_plan UNIQUE (payment_plan_id, payment_number)
);

-- ============================================
-- INDEXES
-- ============================================
CREATE INDEX IF NOT EXISTS idx_payment_plans_brother_dues ON payment_plans(brother_dues_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_payments_payment_plan ON scheduled_payments(payment_plan_id);
CREATE INDEX IF NOT EXISTS idx_scheduled_payments_status ON scheduled_payments(status);
CREATE INDEX IF NOT EXISTS idx_scheduled_payments_date ON scheduled_payments(scheduled_date);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS
ALTER TABLE payment_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_payments ENABLE ROW LEVEL SECURITY;

-- Payment Plans: Brothers can view their own payment plans
CREATE POLICY "Brothers can view own payment plans"
  ON payment_plans FOR SELECT
  USING (
    brother_dues_id IN (
      SELECT id FROM brother_dues WHERE brother_id = auth.uid()
    )
  );

-- Payment Plans: Brothers can create payment plans for their own dues
CREATE POLICY "Brothers can create own payment plans"
  ON payment_plans FOR INSERT
  WITH CHECK (
    brother_dues_id IN (
      SELECT id FROM brother_dues WHERE brother_id = auth.uid()
    )
  );

-- Payment Plans: Brothers can update their own payment plans
CREATE POLICY "Brothers can update own payment plans"
  ON payment_plans FOR UPDATE
  USING (
    brother_dues_id IN (
      SELECT id FROM brother_dues WHERE brother_id = auth.uid()
    )
  );

-- Payment Plans: Brothers can delete their own payment plans
CREATE POLICY "Brothers can delete own payment plans"
  ON payment_plans FOR DELETE
  USING (
    brother_dues_id IN (
      SELECT id FROM brother_dues WHERE brother_id = auth.uid()
    )
  );

-- Payment Plans: VP can view all payment plans
CREATE POLICY "VP can view all payment plans"
  ON payment_plans FOR SELECT
  USING (
    auth.uid() IN (SELECT id FROM users WHERE role = 'vp_finance')
  );

-- Scheduled Payments: Brothers can view their own scheduled payments
CREATE POLICY "Brothers can view own scheduled payments"
  ON scheduled_payments FOR SELECT
  USING (
    payment_plan_id IN (
      SELECT pp.id FROM payment_plans pp
      JOIN brother_dues bd ON pp.brother_dues_id = bd.id
      WHERE bd.brother_id = auth.uid()
    )
  );

-- Scheduled Payments: Brothers can create scheduled payments for their own plans
CREATE POLICY "Brothers can create own scheduled payments"
  ON scheduled_payments FOR INSERT
  WITH CHECK (
    payment_plan_id IN (
      SELECT pp.id FROM payment_plans pp
      JOIN brother_dues bd ON pp.brother_dues_id = bd.id
      WHERE bd.brother_id = auth.uid()
    )
  );

-- Scheduled Payments: VP can view all scheduled payments
CREATE POLICY "VP can view all scheduled payments"
  ON scheduled_payments FOR SELECT
  USING (
    auth.uid() IN (SELECT id FROM users WHERE role = 'vp_finance')
  );

-- ============================================
-- TRIGGERS
-- ============================================

-- Update updated_at timestamp on payment_plans
CREATE OR REPLACE FUNCTION update_payment_plan_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER payment_plans_updated_at
  BEFORE UPDATE ON payment_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_payment_plan_updated_at();

-- Update updated_at timestamp on scheduled_payments
CREATE TRIGGER scheduled_payments_updated_at
  BEFORE UPDATE ON scheduled_payments
  FOR EACH ROW
  EXECUTE FUNCTION update_payment_plan_updated_at();

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to get payment plan summary
CREATE OR REPLACE FUNCTION get_payment_plan_summary(plan_id UUID)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_payments', COUNT(*),
    'paid_payments', COUNT(*) FILTER (WHERE status = 'paid'),
    'pending_payments', COUNT(*) FILTER (WHERE status = 'pending'),
    'total_scheduled', SUM(scheduled_amount),
    'total_paid', SUM(paid_amount),
    'next_payment_date', MIN(scheduled_date) FILTER (WHERE status = 'pending'),
    'next_payment_amount', MIN(scheduled_amount) FILTER (WHERE status = 'pending')
  )
  INTO result
  FROM scheduled_payments
  WHERE payment_plan_id = plan_id;

  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- COMMENTS
-- ============================================

COMMENT ON TABLE payment_plans IS 'Payment plan configurations for brother dues';
COMMENT ON TABLE scheduled_payments IS 'Individual scheduled payments within a payment plan';
COMMENT ON COLUMN payment_plans.total_payments IS 'Total number of payments in the plan (1-10)';
COMMENT ON COLUMN scheduled_payments.payment_number IS 'Sequential payment number (1, 2, 3, ...)';
COMMENT ON COLUMN scheduled_payments.scheduled_amount IS 'Amount scheduled for this payment';
COMMENT ON COLUMN scheduled_payments.scheduled_date IS 'Date when this payment is scheduled';
COMMENT ON COLUMN scheduled_payments.status IS 'Status: pending, paid, or skipped';
COMMENT ON COLUMN scheduled_payments.paid_amount IS 'Actual amount paid (may differ from scheduled)';
COMMENT ON COLUMN scheduled_payments.payment_id IS 'Link to actual payment record when paid';
