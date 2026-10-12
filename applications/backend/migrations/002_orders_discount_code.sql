-- Orders v2: optional discount_code. Additive only, so old code keeps working.
ALTER TABLE orders ADD COLUMN IF NOT EXISTS discount_code VARCHAR(50);