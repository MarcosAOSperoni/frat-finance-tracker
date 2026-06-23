# Testing Guide - Frat Finance Tracker

## Setup Test Accounts

### Step 1: Create VP of Finance Account

1. **In the app**, try to log in with your VP email (e.g., `vp@test.com`). It will fail because the account doesn't exist yet.

2. **Go to Supabase Dashboard** → SQL Editor

3. **Run this SQL** to create the VP account:
```sql
-- First, manually create a user in Supabase Auth
-- Go to Authentication → Users → Add User
-- Email: vp@test.com
-- Password: test123
-- Confirm password: test123
-- Then run this SQL:

UPDATE users
SET role = 'vp_finance',
    profile_completed = true,
    full_name = 'VP Test User'
WHERE email = 'vp@test.com';
```

**Alternative - Direct insert into users table:**
```sql
-- Get the auth user ID from Supabase Auth first, then:
INSERT INTO users (id, email, full_name, role, profile_completed)
VALUES (
  'your-auth-user-id-here',  -- Replace with actual UUID from Supabase Auth
  'vp@test.com',
  'VP Test User',
  'vp_finance',
  true
);
```

4. **Log in as VP** with `vp@test.com` / `test123`

### Step 2: Create Invitation for Brother

1. **As VP**, you'll need to create an invitation in Supabase:

```sql
INSERT INTO invitations (invitation_code, email, expires_at, status)
VALUES (
  'TEST123',  -- Simple code for testing
  'brother@test.com',
  NOW() + INTERVAL '7 days',
  'pending'
);
```

2. **In the app**, sign up as a brother:
   - Email: `brother@test.com`
   - Invitation Code: `TEST123`
   - Full Name: `Test Brother`
   - Password: `test123`

### Step 3: Create Test Dues Period

1. **Log in as VP** (`vp@test.com`)

2. **Click the "Create Dues" button** (floating action button)

3. **Fill in the form:**
   - Dues Period Name: `Fall 2024 Dues`
   - Total Amount: `500.00`
   - Due Date: Select a date 30 days from now
   - Notes: `Semester dues for Fall 2024`
   - Keep "Assign to all brothers" checked

4. **Click "Create"**

5. **You should see:**
   - The new dues period appears in the dashboard
   - All brothers are assigned with status "Pending"

### Step 4: Test Brother View

1. **Log out** and **log in as brother** (`brother@test.com`)

2. **You should see:**
   - Personalized greeting: "Hello, Test Brother"
   - Dues card showing:
     - Fall 2024 Dues
     - Status: Pending (gray badge)
     - Total: $500.00
     - Paid: $0.00
     - Remaining: $500.00 (red)
     - Due date
   - Empty payment history

### Step 5: Test Recording a Payment

1. **Log in as VP** (`vp@test.com`)

2. **Tap on "Test Brother"** in the brothers list

3. **Click "Record Payment"** on the Fall 2024 Dues card

4. **Fill in the payment form:**
   - Amount: `150.00` (partial payment)
   - Date: Select today's date
   - Payment Method: `Venmo`
   - Notes: `First installment`

5. **Click "Record Payment"**

6. **You should see:**
   - Dues card updates:
     - Status: Partial (orange badge)
     - Paid: $150.00 (green)
     - Remaining: $350.00 (red)

7. **Log in as brother** to verify:
   - Same dues amounts shown
   - Payment history shows $150.00 payment with Venmo method

### Step 6: Test Creating Dues for Specific Brothers

1. **Create a second brother account** (repeat Step 2 with different email)

2. **Log in as VP**

3. **Click "Create Dues"**

4. **Uncheck "Assign to all brothers"**

5. **Select only one brother** from the list

6. **Create the dues period**

7. **Verify:**
   - Only the selected brother sees the new dues
   - Other brothers don't see it

## Common Test Scenarios

### Scenario 1: Full Payment
- Record payment for exact remaining amount
- Status should change to "Paid" (green)
- "Record Payment" button should be disabled

### Scenario 2: Multiple Partial Payments
- Record several partial payments
- Each payment appears in payment history
- Amounts update correctly after each payment

### Scenario 3: Overdue Dues
- Create dues with a past due date
- Status should show "Overdue" (red)

### Scenario 4: Multiple Dues Periods
- Create multiple dues periods (Fall, Spring, etc.)
- Verify all show up for each brother
- Verify totals are calculated correctly across all periods

## Quick SQL Snippets

### Delete all test data:
```sql
-- Delete in this order to respect foreign keys
DELETE FROM payments;
DELETE FROM brother_dues;
DELETE FROM dues_periods;
DELETE FROM invitations;
DELETE FROM users WHERE email LIKE '%test.com';
```

### View all data:
```sql
-- See all brothers
SELECT id, email, full_name, role FROM users WHERE role = 'brother';

-- See all dues
SELECT * FROM dues_periods;

-- See all brother_dues with status
SELECT
  u.full_name,
  dp.name as dues_period,
  bd.total_amount,
  bd.amount_paid,
  bd.status,
  bd.due_date
FROM brother_dues bd
JOIN users u ON bd.brother_id = u.id
JOIN dues_periods dp ON bd.dues_period_id = dp.id
ORDER BY bd.due_date;

-- See all payments
SELECT
  u.full_name,
  p.amount,
  p.payment_date,
  p.payment_method
FROM payments p
JOIN brother_dues bd ON p.brother_dues_id = bd.id
JOIN users u ON bd.brother_id = u.id
ORDER BY p.payment_date DESC;
```

## Features to Test

- [x] VP login
- [x] Brother signup with invitation
- [x] Brother login
- [x] Create dues period (all brothers)
- [x] Create dues period (specific brothers)
- [x] View dues as brother
- [x] View all brothers as VP
- [x] Record payment (partial)
- [x] Record payment (full)
- [x] Payment history
- [x] Status updates (Pending → Partial → Paid)
- [x] Pull to refresh
- [x] Logout

## Expected App Flow

1. **First Time Setup:**
   - Manually create VP account in Supabase
   - VP creates invitations (via SQL for now)
   - Brothers sign up with invitation codes
   - VP creates first dues period

2. **Regular Usage:**
   - VP creates dues periods each semester
   - Brothers view their dues and payment history
   - Brothers pay outside the app (Venmo, cash, etc.)
   - VP records payments manually in the app
   - Everyone sees real-time updates
