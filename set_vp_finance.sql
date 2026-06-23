-- Insert user profile and set as VP of Finance
INSERT INTO users (id, email, full_name, role, profile_completed, brother_status)
SELECT
  '86166a8e-d429-47ad-95f8-b3acc0ebcb5f',
  email,
  COALESCE(raw_user_meta_data->>'full_name', 'Marcos Speroni'),
  'vp_finance',
  true,
  'active'
FROM auth.users
WHERE id = '86166a8e-d429-47ad-95f8-b3acc0ebcb5f'
ON CONFLICT (id) DO UPDATE
SET role = 'vp_finance', brother_status = 'active', profile_completed = true;
