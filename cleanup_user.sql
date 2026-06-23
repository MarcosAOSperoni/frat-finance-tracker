-- Cleanup: Remove user and all associated data
-- Run this in Supabase SQL Editor

-- 1. Delete scheduled payments (via payment plans linked to this user's dues)
DELETE FROM scheduled_payments
WHERE payment_plan_id IN (
    SELECT pp.id FROM payment_plans pp
    JOIN brother_dues bd ON bd.id = pp.brother_dues_id
    WHERE bd.brother_id = (SELECT id FROM users WHERE email = 'speronimarcos@gmail.com')
);

-- 2. Delete payment plans
DELETE FROM payment_plans
WHERE brother_dues_id IN (
    SELECT id FROM brother_dues
    WHERE brother_id = (SELECT id FROM users WHERE email = 'speronimarcos@gmail.com')
);

-- 3. Delete payments
DELETE FROM payments
WHERE brother_dues_id IN (
    SELECT id FROM brother_dues
    WHERE brother_id = (SELECT id FROM users WHERE email = 'speronimarcos@gmail.com')
);

-- 4. Delete brother dues
DELETE FROM brother_dues
WHERE brother_id = (SELECT id FROM users WHERE email = 'speronimarcos@gmail.com');

-- 5. Delete from public users table
DELETE FROM users WHERE email = 'speronimarcos@gmail.com';

-- 6. Delete from auth (fully removes login)
DELETE FROM auth.users WHERE email = 'speronimarcos@gmail.com';
