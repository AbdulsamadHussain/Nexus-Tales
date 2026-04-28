ALTER TABLE canonical_state
ADD COLUMN IF NOT EXISTS ambiguity_tracker JSONB NOT NULL DEFAULT '{
  "count": 0,
  "last_scene": null,
  "last_route": null
}'::jsonb;