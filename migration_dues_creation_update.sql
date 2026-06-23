-- Migration: Dues Creation Update
-- Run this in Supabase SQL Editor (safe to re-run)
--
-- Changes:
-- 1. Drop auto-assign trigger (VP now selects brothers manually)
-- 2. Add INSERT policy on brother_dues for VP
-- 3. Add start_date column to dues_periods
-- 4. Migrate deLettered/alumni statuses to inactive
-- 5. Add INSERT policies on payment_plans and scheduled_payments for VP
-- 6. Add UPDATE and SELECT policies on scheduled_payments and payment_plans

-- =====================================================
-- 1. Drop the auto-assign trigger
-- =====================================================
DROP TRIGGER IF EXISTS auto_assign_dues_on_period_create ON dues_periods;
DROP FUNCTION IF EXISTS auto_assign_dues_to_brothers();

-- =====================================================
-- 2. Add INSERT policy on brother_dues for VP
-- =====================================================
DROP POLICY IF EXISTS "VP of Finance can insert brother dues" ON brother_dues;
CREATE POLICY "VP of Finance can insert brother dues"
    ON brother_dues FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'vp_finance'
        )
    );

-- =====================================================
-- 3. Add start_date column to dues_periods
-- =====================================================
ALTER TABLE dues_periods ADD COLUMN IF NOT EXISTS start_date DATE;

-- Set default start_date for existing rows to created_at date
UPDATE dues_periods SET start_date = created_at::date WHERE start_date IS NULL;

-- =====================================================
-- 4. Migrate deLettered/alumni statuses to inactive
-- =====================================================
UPDATE users SET brother_status = 'inactive' WHERE brother_status IN ('deLettered', 'alumni');

-- =====================================================
-- 5. Add INSERT policies on payment_plans and scheduled_payments for VP
-- =====================================================
DROP POLICY IF EXISTS "VP of Finance can insert payment plans" ON payment_plans;
CREATE POLICY "VP of Finance can insert payment plans"
    ON payment_plans FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'vp_finance'
        )
    );

DROP POLICY IF EXISTS "VP of Finance can insert scheduled payments" ON scheduled_payments;
CREATE POLICY "VP of Finance can insert scheduled payments"
    ON scheduled_payments FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'vp_finance'
        )
    );

-- =====================================================
-- 6. Add UPDATE and SELECT policies on scheduled_payments and payment_plans
-- =====================================================
DROP POLICY IF EXISTS "VP of Finance can update scheduled payments" ON scheduled_payments;
CREATE POLICY "VP of Finance can update scheduled payments"
    ON scheduled_payments FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'vp_finance'
        )
    );

DROP POLICY IF EXISTS "VP of Finance can view scheduled payments" ON scheduled_payments;
CREATE POLICY "VP of Finance can view scheduled payments"
    ON scheduled_payments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'vp_finance'
        )
    );

DROP POLICY IF EXISTS "VP of Finance can view payment plans" ON payment_plans;
CREATE POLICY "VP of Finance can view payment plans"
    ON payment_plans FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'vp_finance'
        )
    );

DROP POLICY IF EXISTS "Brothers can view their own payment plans" ON payment_plans;
CREATE POLICY "Brothers can view their own payment plans"
    ON payment_plans FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM brother_dues
            WHERE brother_dues.id = payment_plans.brother_dues_id
            AND brother_dues.brother_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Brothers can view their own scheduled payments" ON scheduled_payments;
CREATE POLICY "Brothers can view their own scheduled payments"
    ON scheduled_payments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM payment_plans
            JOIN brother_dues ON brother_dues.id = payment_plans.brother_dues_id
            WHERE payment_plans.id = scheduled_payments.payment_plan_id
            AND brother_dues.brother_id = auth.uid()
        )
    );

-- =====================================================
-- 7. Add DELETE policies for VP of Finance
-- =====================================================
DROP POLICY IF EXISTS "VP of Finance can delete brother dues" ON brother_dues;
CREATE POLICY "VP of Finance can delete brother dues"
    ON brother_dues FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'vp_finance'
        )
    );

DROP POLICY IF EXISTS "VP of Finance can delete payment plans" ON payment_plans;
CREATE POLICY "VP of Finance can delete payment plans"
    ON payment_plans FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'vp_finance'
        )
    );

DROP POLICY IF EXISTS "VP of Finance can delete scheduled payments" ON scheduled_payments;
CREATE POLICY "VP of Finance can delete scheduled payments"
    ON scheduled_payments FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'vp_finance'
        )
    );

DROP POLICY IF EXISTS "VP of Finance can delete payments" ON payments;
CREATE POLICY "VP of Finance can delete payments"
    ON payments FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'vp_finance'
        )
    );

-- =====================================================
-- DONE!
-- =====================================================
