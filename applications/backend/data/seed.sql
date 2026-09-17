INSERT INTO products (name, category, price, description)
VALUES
  ('Green Ceramic Bottle', 'Lifestyle', 34, 'Reusable ceramic bottle'),
  ('Everyday Candle', 'Home', 18, 'Warm scented candle'),
  ('Desk Lamp', 'Office', 42, 'Minimal desk lamp'),
  ('Glow Skin Kit', 'Beauty', 29, 'Daily skincare kit'),
  ('Daily Cotton Set', 'Lifestyle', 26, 'Soft cotton essentials'),
  ('Minimal Chair', 'Home', 76, 'Compact lounge chair'),
  ('Focus Journal', 'Office', 14, 'A110 page journal'),
  ('Harvest Basket', 'Home', 38, 'Reusable woven basket')
ON CONFLICT DO NOTHING;
