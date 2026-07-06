# T9 — Supabase → Make → Google Sheet + Brevo (setup guide)

## Status: prepared, blocked on Sonia's Make access

The Make MCP in the current session belongs to a different client (Lee). To build this,
reconnect Sonia's Make account (team 902191, org 2270790, akinpros@gmail.com member) or
build manually in her Make UI.

## Make scenario (Option A from the master document)

1. **Webhook** (gateway:CustomWebHook) — name: "FOV — New Submission"
2. **Google Sheets — Add a Row** (connection: akinpros Google conn 14332612 or Sonia's)
   - Spreadsheet: `1733f3tvHcPStBevY0uYMnn-UfPv6mVAc-qzwQEsSUYo`, first tab (gid=0)
   - Columns (A–I): Date (Europe/Madrid) · Full name · Email · Category · Social handle ·
     Status · Newsletter opt-in YES/NO · Consent terms version · Submission ID
   - Mapping from webhook payload `record`:
     A `{{formatDate(1.record.created_at; "DD/MM/YYYY HH:mm"; "Europe/Madrid")}}`
     B `{{1.record.full_name}}` C `{{1.record.email}}` D `{{1.record.category}}`
     E `{{1.record.social_handle}}` F `{{1.record.status}}`
     G `{{if(1.record.newsletter_opt_in; "YES"; "NO")}}`
     H `{{1.record.consent_terms_version}}` I `{{1.record.id}}`
3. **Router**
   - Route 1 filter: `1.record.newsletter_opt_in` = true →
     **Brevo — Create/Update a Contact** (Brevo connection already in team 902191)
     - List: "Future of Voices" (create in Brevo if missing)
     - Email: `{{1.record.email}}`; attributes: FIRSTNAME (first word of full_name),
       FULLNAME, CATEGORY, SOCIAL_HANDLE, SUBMISSION_DATE, STATUS
     - Update-if-exists = yes (no duplicates)
   - Route 2: no filter (fallthrough, nothing else needed)
4. Scheduling: immediately. Failures must not block the form (they can't — webhook is async).

## Supabase side (run AFTER creating the Make webhook, replacing <MAKE_WEBHOOK_URL>)

```sql
create extension if not exists pg_net;

create or replace function notify_new_submission()
returns trigger language plpgsql security definer as $fn$
begin
  perform net.http_post(
    url := '<MAKE_WEBHOOK_URL>',
    body := jsonb_build_object('type','INSERT','table','submissions','record', to_jsonb(NEW)),
    headers := '{"Content-Type":"application/json"}'::jsonb
  );
  return NEW;
exception when others then
  return NEW; -- never block the form
end;
$fn$;

drop trigger if exists on_new_submission on submissions;
create trigger on_new_submission
  after insert on submissions
  for each row execute function notify_new_submission();
```

Same trigger pattern can later call Resend (T8) via an Edge Function or a second Make route.
