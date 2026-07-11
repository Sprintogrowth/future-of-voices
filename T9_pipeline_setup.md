# T9 — Supabase -> Make -> Google Sheet + Brevo  (DONE, live-tested 2026-07-11)

Scenario **9510567** "FOV — Submission → Sheet + Brevo" (team 902191, folder 514331) — ACTIVE.
Webhook hook 4252719: https://hook.eu2.make.com/6e9ems14lf7o7tbxtvw4r3rfn8hn9l3g
Supabase trigger on_new_submission (pg_net) POSTs every INSERT to the webhook.

Flow: Webhook -> Google Sheets Add a Row (conn 14332612, sheet 1zhmvu81BQmUF0BI9nDKOBmeBqLu79e35BC7vqTEj8uM tab Sheet1, header-mapped A-I)
      -> Router -> [filter newsletter_opt_in = true] Brevo Create/Update Contact (conn 13318387, list 74 "Future of voices", updateEnabled=true, FIRSTNAME).

KEY FIX: Brevo connections are type account:sendinblue2 -> use sendinblue app VERSION 2 modules (v1 was rejected as incompatible / 403).

Verified: opt-in -> Sheet + Brevo (3 ops); non-opt-in -> Sheet only (2 ops). No duplicates (updateEnabled).

CLEANUP before handover: delete sheet rows 2-5 (test data) + Brevo list 74 contact optin-test@futureofvoices.org.
Optional enrichment: create Brevo custom attributes FULLNAME/SOCIAL_HANDLE/SUBMISSION_DATE/STATUS then map them in CreateContact.
Handover: transfer the Google Sheet ownership to Sonia (created under akinpros to enable testing).
