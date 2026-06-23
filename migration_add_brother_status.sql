-- Migration: Add brother_status and must_change_password to users table
-- Run this on existing databases that don't have these columns

-- Create brother_status enum if it doesn't exist
DO $$ BEGIN
    CREATE TYPE brother_status AS ENUM ('active', 'inactive', 'deLettered', 'alumni');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Add must_change_password column if it doesn't exist
DO $$ BEGIN
    ALTER TABLE users ADD COLUMN must_change_password BOOLEAN DEFAULT FALSE;
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

-- Add brother_status column if it doesn't exist
DO $$ BEGIN
    ALTER TABLE users ADD COLUMN brother_status brother_status DEFAULT 'active';
EXCEPTION
    WHEN duplicate_column THEN null;
END $$;

-- Set all existing users to active status
UPDATE users SET brother_status = 'active' WHERE brother_status IS NULL;
UPDATE users SET must_change_password = FALSE WHERE must_change_password IS NULL;

-- Verify the changes
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'users'
AND column_name IN ('must_change_password', 'brother_status');
