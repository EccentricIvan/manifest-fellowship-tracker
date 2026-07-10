# Google Form → Firestore sync

Syncs the [Victoria Registration Form](https://docs.google.com/forms/d/1H3cdNo27BXWQCLO8pj51bLd98sfqklU0So-P_-SN3v8/viewform)
into Firestore on every submission:

- Upserts a `/members` doc, matched by phone number (`Contact`), so repeat
  submissions update the same person instead of duplicating them.
- If `First Timer` is `Yes`, also creates a pending `/assignments` doc
  (`reason: firstTimer`) — the same record shape the app itself writes, so it
  shows up in the Admin Dashboard's "Pending First-Timer Follow-ups" and can
  be assigned to a caller from the app as normal.

No Cloud Functions and no billing-plan change: the script authenticates as a
service account and calls the Firestore REST API directly from Apps Script.

`residence`, `wantsToServe`, and `wantsTransport` are also written and are
surfaced in the app's Member model, Members Register list, and the member
add/edit form.

## One-time setup

### 1. Create a service account

In the [GCP Console](https://console.cloud.google.com/iam-admin/serviceaccounts?project=manifest-fellowship-tracker)
for the `manifest-fellowship-tracker` project:

1. Create service account (e.g. `form-sync`).
2. Grant it the **Cloud Datastore User** role (`roles/datastore.user`) —
   sufficient for Firestore reads/writes, nothing broader.
3. Open the new account → **Keys** → **Add key** → **Create new key** → JSON.
   Download it.

### 2. Bind the script to the Form

1. Open the [Form](https://docs.google.com/forms/d/1H3cdNo27BXWQCLO8pj51bLd98sfqklU0So-P_-SN3v8/edit)
   in edit mode → ⋮ menu → **Script editor**. This creates a form-bound
   Apps Script project.
2. Delete the default empty function and paste in the contents of
   [`Code.gs`](Code.gs).

### 3. Set script properties

In the script editor: **Project Settings** (gear icon) → **Script Properties** → add:

| Property | Value |
|---|---|
| `FIRESTORE_PROJECT_ID` | `manifest-fellowship-tracker` |
| `SERVICE_ACCOUNT_EMAIL` | `client_email` from the downloaded JSON key |
| `SERVICE_ACCOUNT_PRIVATE_KEY` | `private_key` from the downloaded JSON key, pasted as-is (including the `-----BEGIN/END PRIVATE KEY-----` lines) |
| `ADMIN_ALERT_EMAIL` *(optional)* | an email to notify if a sync fails |

### 4. Test the connection

Select the `testConnection` function in the toolbar dropdown and click Run.
Approve the OAuth permission prompt (this is Apps Script asking for
`UrlFetchApp`/`PropertiesService` access — not Firestore access, that's the
service account). Check **Executions** in the left sidebar for the logged
result; it should print a Firestore document list (or an empty `{}` if
`/members` is empty), not an error.

### 5. Install the trigger

In the script editor: **Triggers** (clock icon) → **Add Trigger**:

- Function: `onFormSubmit`
- Event source: **From form**
- Event type: **On form submit**

### 6. Verify end-to-end

Submit a test response on the live form, then check the `members` (and, if
you answered "First Timer: Yes", `assignments`) collection in the
[Firestore console](https://console.firebase.google.com/project/manifest-fellowship-tracker/firestore)
for the new/updated doc. Check **Executions** in the script editor if
nothing shows up.
