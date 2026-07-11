# T9 — Supabase → Make → Google Sheet + Brevo

## Built so far (in Sonia's Make, team 902191)
- **Webhook** "FOV — New Submission" — hook id **4252719**
  URL: `https://hook.eu2.make.com/6e9ems14lf7o7tbxtvw4r3rfn8hn9l3g`
- **Scenario** "FOV — Submission → Sheet + Brevo" — id **9510567**, folder 514331, INACTIVE.
  Currently: Webhook → Google Sheets Add a Row (conn 14332612, akinpros Google).
  Column mapping A–I matches Annex E: Date(Europe/Madrid) · Full name · Email · Category ·
  Social handle · Status · Newsletter opt-in(YES/NO) · Consent terms version · Submission ID.

## BLOCKERS (access — flagged to Sonia, citing T9)
1. **Google Sheet not shared** with `akinpros@gmail.com` → Sheets API returns **403 PERMISSION_DENIED**
   for sheet `1733f3tvHcPStBevY0uYMnn-UfPv6mVAc-qzwQEsSUYo`. Sonia must share it as **Editor**.
   After sharing: confirm the first tab's real name (blueprint assumes "Sheet1") and that row 1
   has the exact Annex E headers; then activate + live-test.
2. **Brevo** → both connections (13318387 "Brevo Main", 13106513) return **403** on the lists/contacts
   endpoint, and `sendinblue:CreateUser` rejected connection 13318387 as "not compatible".
   Needs, on Sonia's Brevo: (a) an API key with **Contacts** permission, (b) the list
   **"Future of Voices"** created, (c) custom contact attributes FULLNAME, CATEGORY, SOCIAL_HANDLE,
   SUBMISSION_DATE, STATUS (FIRSTNAME already standard). Then add the Brevo "Create/Update a contact"
   module in a Router branch filtered on `newsletter_opt_in = true`.

## Supabase trigger (apply at go-live, after the sheet is shared + scenario active)
Run in Supabase SQL editor (replace nothing — webhook URL already inlined):
```sql
create extension if not exists pg_net;

create or replace function notify_new_submission()
returns trigger language plpgsql security definer as $fn$
begin
  perform net.http_post(
    url := 'https://hook.eu2.make.com/6e9ems14lf7o7tbxtvw4r3rfn8hn9l3g',
    body := jsonb_build_object('type','INSERT','table','submissions','record', to_jsonb(NEW)),
    headers := '{"Content-Type":"application/json"}'::jsonb
  );
  return NEW;
exception when others then
  return NEW; -- never block the form (T9 rule: failures don't block submission)
end;
$fn$;

drop trigger if exists on_new_submission on submissions;
create trigger on_new_submission
  after insert on submissions
  for each row execute function notify_new_submission();
```

## Go-live checklist (one short session once access is granted)
1. Sonia shares the Sheet with akinpros@gmail.com (Editor) + fixes Brevo (key + list + attributes).
2. Confirm tab name + headers; fix the addRow mapping to header-keyed if needed.
3. Add Brevo module (Router branch, opt-in filter).
4. Apply the Supabase trigger above.
5. Activate scenario 9510567; submit a real test WITH opt-in → row in Sheet + contact in Brevo;
   one WITHOUT opt-in → row in Sheet only. Verify no Brevo duplicates on repeat email.
