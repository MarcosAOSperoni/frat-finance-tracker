# Database Schema - Fraternity Finance Tracker

## Updated Requirements
- VP of Finance sends invitations to brothers
- Brothers self-register and fill in their own info
- Only VP of Finance can mark dues as paid
- Support payment plans (partial payments tracked)
- Record each payment with amount and date

---

## Proposed Schema

### 1. `users` (Supabase Auth + Custom Profile)
Stores user accounts and profiles.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key (references auth.users) |
| `email` | text | Email address (from auth) |
| `full_name` | text | Brother's full name |
| `phone` | text | Phone number (optional) |
| `role` | enum | Either 'brother' or 'vp_finance' |
| `profile_completed` | boolean | True after brother fills in their info |
| `created_at` | timestamp | Account creation timestamp |
| `updated_at` | timestamp | Last updated timestamp |

**Notes:**
- Brothers fill in `full_name`, `phone` after accepting invitation
- VP of Finance account is pre-created (first account = VP by default)

---

### 2. `invitations`
Tracks invitation links sent by VP of Finance.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `email` | text | Brother's email to invite |
| `invitation_code` | text | Unique code for registration link |
| `invited_by` | uuid | Foreign key -> users.id (VP of Finance) |
| `status` | enum | 'pending', 'accepted', 'expired' |
| `expires_at` | timestamp | Invitation expiration (7 days) |
| `accepted_at` | timestamp | When brother registered (nullable) |
| `created_at` | timestamp | When invitation was sent |

**Notes:**
- VP creates invitation with brother's email
- System generates unique `invitation_code`
- Brother clicks link: `app.com/signup?code=ABC123`
- After registration, status changes to 'accepted'

---

### 3. `dues_periods`
Defines dues periods (e.g., "Fall 2024 Dues", "Spring 2025 Dues").

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `name` | text | e.g., "Fall 2024 Dues" |
| `semester` | text | e.g., "Fall 2024" |
| `total_amount` | decimal | Full dues amount (e.g., $500.00) |
| `due_date` | date | Final due date |
| `created_by` | uuid | Foreign key -> users.id (VP of Finance) |
| `created_at` | timestamp | When dues period was created |
| `updated_at` | timestamp | Last updated |

**Notes:**
- VP of Finance creates dues periods
- Default amount applies to all brothers (can be overridden per brother)
- All brothers get assigned this dues period automatically

---

### 4. `brother_dues`
Links brothers to dues periods with their specific amounts.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `brother_id` | uuid | Foreign key -> users.id |
| `dues_period_id` | uuid | Foreign key -> dues_periods.id |
| `total_amount` | decimal | Amount this brother owes (can differ from default) |
| `amount_paid` | decimal | Total paid so far (sum of payments) |
| `status` | enum | 'pending', 'partial', 'paid', 'overdue' |
| `due_date` | date | Due date (can be customized per brother) |
| `notes` | text | Notes about payment plan (optional) |
| `created_at` | timestamp | When assigned |
| `updated_at` | timestamp | Last updated (recalculated on payment) |

**Notes:**
- When VP creates a dues period, all brothers get a `brother_dues` record
- `amount_paid` is auto-calculated from `payments` table
- `status` is auto-calculated:
  - `pending`: amount_paid = 0
  - `partial`: 0 < amount_paid < total_amount
  - `paid`: amount_paid >= total_amount
  - `overdue`: status = pending/partial AND due_date < today

---

### 5. `payments`
Records individual payment transactions.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `brother_dues_id` | uuid | Foreign key -> brother_dues.id |
| `amount` | decimal | Amount paid in this transaction |
| `payment_date` | date | Date payment was made |
| `payment_method` | text | e.g., "Venmo", "Cash", "Check #123" (optional) |
| `notes` | text | Additional notes (optional) |
| `recorded_by` | uuid | Foreign key -> users.id (VP of Finance who recorded it) |
| `created_at` | timestamp | When payment was recorded |

**Notes:**
- Only VP of Finance can create payment records
- Each payment updates `brother_dues.amount_paid` (via database trigger or app logic)
- Supports payment plans: multiple payments for one dues period

---

### 6. `notification_preferences`
User notification settings.

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `user_id` | uuid | Foreign key -> users.id |
| `push_enabled` | boolean | Enable push notifications (default true) |
| `email_enabled` | boolean | Enable email reminders (default true) |
| `reminder_days` | int[] | Days before due date to send reminders [7, 3, 1] |
| `created_at` | timestamp | Created timestamp |
| `updated_at` | timestamp | Last updated |

**Notes:**
- Created when brother completes profile
- Brothers can update their own preferences

---

## Relationships Diagram

```
users (VP of Finance)
  |
  ├─> invitations (sends invitations)
  |
  ├─> dues_periods (creates dues periods)
  |
  └─> payments (records payments)

users (Brother)
  |
  ├─> brother_dues (assigned dues)
  |      └─> payments (payment history)
  |
  └─> notification_preferences (their settings)
```

---

## Key Workflows

### 1. VP of Finance Invites Brother
```sql
-- VP creates invitation
INSERT INTO invitations (email, invitation_code, invited_by, status, expires_at)
VALUES ('brother@email.com', 'ABC123XYZ', [vp_id], 'pending', NOW() + INTERVAL '7 days');

-- System sends email with link: app.com/signup?code=ABC123XYZ
```

### 2. Brother Accepts Invitation & Registers
```sql
-- Brother clicks link, creates account in Supabase Auth
-- Then completes profile:
INSERT INTO users (id, email, full_name, phone, role, profile_completed)
VALUES ([auth_user_id], 'brother@email.com', 'John Doe', '555-1234', 'brother', true);

-- Mark invitation as accepted
UPDATE invitations
SET status = 'accepted', accepted_at = NOW()
WHERE invitation_code = 'ABC123XYZ';
```

### 3. VP Creates Dues Period
```sql
-- Create dues period
INSERT INTO dues_periods (name, semester, total_amount, due_date, created_by)
VALUES ('Fall 2024 Dues', 'Fall 2024', 500.00, '2024-09-30', [vp_id]);

-- Auto-assign to all brothers
INSERT INTO brother_dues (brother_id, dues_period_id, total_amount, amount_paid, status, due_date)
SELECT u.id, [new_dues_period_id], 500.00, 0, 'pending', '2024-09-30'
FROM users u
WHERE u.role = 'brother';
```

### 4. VP Records Payment (Supports Payment Plans)
```sql
-- Brother pays $200 (first installment of $500 dues)
INSERT INTO payments (brother_dues_id, amount, payment_date, recorded_by)
VALUES ([brother_dues_id], 200.00, '2024-09-01', [vp_id]);

-- Update brother_dues amount_paid
UPDATE brother_dues
SET amount_paid = amount_paid + 200.00,
    status = CASE
      WHEN amount_paid + 200.00 >= total_amount THEN 'paid'
      WHEN amount_paid + 200.00 > 0 THEN 'partial'
      ELSE 'pending'
    END
WHERE id = [brother_dues_id];

-- Brother still owes $300, status = 'partial'
```

### 5. Brother Views Their Dues
```sql
-- Brother sees their dues and payment history
SELECT
  dp.name,
  bd.total_amount,
  bd.amount_paid,
  bd.status,
  bd.due_date,
  (bd.total_amount - bd.amount_paid) as amount_remaining
FROM brother_dues bd
JOIN dues_periods dp ON bd.dues_period_id = dp.id
WHERE bd.brother_id = [current_user_id];

-- Brother sees payment history
SELECT amount, payment_date, payment_method
FROM payments p
JOIN brother_dues bd ON p.brother_dues_id = bd.id
WHERE bd.brother_id = [current_user_id]
ORDER BY payment_date DESC;
```

### 6. VP Views All Dues
```sql
-- VP sees all brothers and their payment status
SELECT
  u.full_name,
  u.email,
  dp.name as dues_period,
  bd.total_amount,
  bd.amount_paid,
  (bd.total_amount - bd.amount_paid) as amount_remaining,
  bd.status,
  bd.due_date
FROM brother_dues bd
JOIN users u ON bd.brother_id = u.id
JOIN dues_periods dp ON bd.dues_period_id = dp.id
ORDER BY bd.status, bd.due_date;
```

---

## Row Level Security (RLS) Policies

### `users`
- **Brothers:** Read their own row only
- **VP of Finance:** Read all rows

### `invitations`
- **VP of Finance:** Full access (create, read, update)
- **Brothers:** No access

### `dues_periods`
- **Everyone:** Read all
- **VP of Finance:** Create, update, delete

### `brother_dues`
- **Brothers:** Read only their own dues
- **VP of Finance:** Read all, update all

### `payments`
- **Brothers:** Read only their own payments
- **VP of Finance:** Full access

### `notification_preferences`
- **Users:** Read and update their own preferences only

---

## Questions for Approval:

1. **Does this schema capture all your requirements?**
   - Invitations system ✓
   - Brother self-registration ✓
   - Payment plans (multiple payments per dues period) ✓
   - Payment tracking with amount and date ✓

2. **Should we track payment method?** (Venmo, Cash, Check, etc.)
   - Currently optional in `payments.payment_method`

3. **Do you want to support multiple semesters at once?**
   - This schema supports it (create multiple dues_periods)

4. **Should brothers be able to see other brothers' names?**
   - Or should it be 100% private (only VP sees all)?

5. **Do you want to track late fees?**
   - Not currently in schema, but could add `late_fee` to `brother_dues`

6. **Should there be a "grace period" after due date?**
   - Before status changes to 'overdue'?

---

**Please review and let me know if this works or if we need to adjust anything!**
