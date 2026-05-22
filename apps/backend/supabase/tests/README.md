# Integration & Latency Tests

## Setup

Set env vars before running:

```
SUPABASE_URL=https://kayizabwbigamywwmscv.supabase.co
SVC_ROLE_KEY=<service role key>
QA_USER_ID=<user_id of a seeded test character>
QA_USER_ID_B=<a second user_id for cross-user isolation tests>
```

`QA_USER_ID` must have a row in `canonical_state` and at least one row in `manual_saves`.

## Run unit tests (no network required)

```
deno test --allow-env supabase/functions/
```

## Run integration tests

```
deno test --allow-env --allow-net supabase/tests/integration.test.ts
```

## Run latency tests

```
deno test --allow-env --allow-net supabase/tests/latency.test.ts
```

Latency tests print timing per run and fail if any single run exceeds the §14 budget.
