alter table public.chapter_summaries
  add column if not exists campaign_id text,
  add column if not exists summary_type text,
  add column if not exists summary_text text,
  add column if not exists events_covered jsonb default '[]';

-- Map existing columns to new names if content/trigger exist
update public.chapter_summaries
  set summary_text = content,
      summary_type = trigger
  where summary_text is null;