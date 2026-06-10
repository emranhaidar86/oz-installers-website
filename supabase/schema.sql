-- ============================================================
-- Oz Installers — App Settings Schema
-- Run this in Supabase > SQL Editor
-- ============================================================

CREATE TABLE IF NOT EXISTS public.app_settings (
  key          TEXT PRIMARY KEY,
  value        JSONB NOT NULL,
  label        TEXT NOT NULL,
  description  TEXT,
  category     TEXT NOT NULL DEFAULT 'general',
  data_type    TEXT NOT NULL DEFAULT 'json'
                 CHECK (data_type IN ('string', 'number', 'boolean', 'json')),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_by   TEXT NOT NULL DEFAULT 'system'
);

CREATE INDEX IF NOT EXISTS idx_app_settings_category
  ON public.app_settings(category);

-- Auto-touch updated_at on every UPDATE
CREATE OR REPLACE FUNCTION public.touch_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE OR REPLACE TRIGGER trg_app_settings_touch
  BEFORE UPDATE ON public.app_settings
  FOR EACH ROW EXECUTE FUNCTION public.touch_updated_at();

-- Row Level Security
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename  = 'app_settings'
      AND policyname = 'Public can read settings'
  ) THEN
    CREATE POLICY "Public can read settings"
      ON public.app_settings FOR SELECT
      USING (true);
  END IF;
END $$;

DO $$ BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename  = 'app_settings'
      AND policyname = 'Service role full access'
  ) THEN
    CREATE POLICY "Service role full access"
      ON public.app_settings FOR ALL
      USING (auth.role() = 'service_role');
  END IF;
END $$;


-- ============================================================
-- SEED: initial values matching the current hardcoded prices
-- ON CONFLICT DO NOTHING — safe to re-run
-- ============================================================

INSERT INTO public.app_settings (key, value, label, description, category, data_type) VALUES

-- TV Mounting
('pricing.tv.small',   '{"label":"TV under 43 inches installation","price":120}',         'TV: Small (under 43")',   'Wall mount for small/bedroom screens',             'pricing', 'json'),
('pricing.tv.medium',  '{"label":"TV 44 to 65 inches installation","price":150}',         'TV: Medium (44–65")',     'Most common living-room install',                  'pricing', 'json'),
('pricing.tv.large',   '{"label":"TV 66 inches and above installation","price":200}',     'TV: Large (66"+)',        'Oversized screens — 75", 85", 98"',                'pricing', 'json'),

-- Other Services
('pricing.antenna',    '{"label":"Antenna / Starlink installation","price":160}',         'Antenna / Starlink',      'Per item — use qty for multiple dishes/points',     'pricing', 'json'),
('pricing.security',   '{"label":"Smart home security installation","price":180}',        'Smart Home Security',     'Per item — cameras, locks, doorbells',              'pricing', 'json'),
('pricing.furniture',  '{"label":"Furniture assembly","price":110}',                     'Furniture Assembly',      'Per item — IKEA, flat-pack, wardrobes',             'pricing', 'json'),

-- Whitegoods
('pricing.whitegoods.standard', '{"label":"Standard appliance installation","price":130}','Whitegoods: Standard',   'Freestanding washer, dryer, basic dishwasher',      'pricing', 'json'),
('pricing.whitegoods.complex',  '{"label":"Complex / integrated appliance installation","price":180}','Whitegoods: Complex','Integrated units, stacked pairs, built-in fridge','pricing', 'json'),

-- Travel Surcharges
('pricing.travel.metro', '{"label":"Adelaide metro travel","price":0}',                  'Travel: Metro',           'CBD and metro — no surcharge',                      'pricing', 'json'),
('pricing.travel.outer', '{"label":"Outer metro travel surcharge","price":25}',          'Travel: Outer Metro',     'Salisbury, Mawson Lakes, Tea Tree Gully',           'pricing', 'json'),
('pricing.travel.hills', '{"label":"Adelaide Hills / regional surcharge","price":50}',   'Travel: Hills/Regional',  'Stirling, Hahndorf, Mount Barker',                  'pricing', 'json'),

-- Complexity Extras
('pricing.extra.cable_inwall',     '{"label":"In-wall cable concealment","price":120}',  'Extra: In-wall Cabling',  'Premium hidden cable finish',                       'pricing', 'json'),
('pricing.extra.cable_trunking',   '{"label":"External cable trunking","price":55}',     'Extra: Cable Trunking',   'Surface-mounted cable channel',                     'pricing', 'json'),
('pricing.extra.ceiling_access',   '{"label":"Ceiling space access","price":65}',        'Extra: Ceiling Access',   'Roof cavity access for cabling or signal work',     'pricing', 'json'),
('pricing.extra.starlink_upgrade', '{"label":"Starlink roof mount upgrade","price":150}','Extra: Starlink Roof Mount','Full bracket, weather seal, cable run',           'pricing', 'json'),
('pricing.extra.packaging',        '{"label":"Packaging removal","price":35}',           'Extra: Packaging Removal','Cardboard and heavy packaging removed from site',   'pricing', 'json'),

-- Booking Speed
('pricing.urgency.standard', '{"label":"Standard booking window","price":0}',            'Urgency: Standard',       'Next available appointment',                        'pricing', 'json'),
('pricing.urgency.priority', '{"label":"Priority same-day request","price":45}',         'Urgency: Priority',       'Urgent Adelaide metro same-day jobs',               'pricing', 'json'),

-- Multi-service discount (flat number, not JSON object)
('pricing.multiDiscount', '20', 'Multi-Service Discount ($)', 'Dollar amount off when 2+ paid service items are booked', 'pricing', 'number'),

-- System Flags
('system.maintenanceMode',    'false',
  'Maintenance Mode',    'Show a red sitewide maintenance banner',       'system', 'boolean'),
('system.bookingsEnabled',    'true',
  'Bookings Enabled',    'Allow new bookings to be submitted',           'system', 'boolean'),
('system.maintenanceMessage', '"We are currently performing scheduled maintenance. We will be back shortly!"',
  'Maintenance Message', 'Text shown in the maintenance banner',         'system', 'string'),

-- Promotional Banner
('banner.promo.enabled', 'false',
  'Promo Banner: Active', 'Show the global promo banner sitewide',      'banner', 'boolean'),
('banner.promo.text',    '"Book this week and get $20 off any multi-service visit!"',
  'Promo Banner: Text',   'Message shown in the promo banner',          'banner', 'string'),
('banner.promo.color',   '"#f59e0b"',
  'Promo Banner: Colour', 'Background hex colour for the promo banner', 'banner', 'string')

ON CONFLICT (key) DO NOTHING;
