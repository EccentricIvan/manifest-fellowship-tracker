/**
 * Manifest Fellowship Tracker — Google Form → Firestore sync.
 *
 * Bind this script to the Registration Form (Form menu ⋮ > Script editor).
 * On every submission it upserts a /members doc (matched by phone number)
 * and, for first-timers, creates a pending /assignments doc so the
 * follow-up shows up in the Admin Dashboard / Call Centre — the same shape
 * the app itself writes from FirstTimerQuickAddScreen / create_assignment_screen.
 *
 * Auth: signs a JWT with a service account key and exchanges it for an
 * OAuth token (Utilities.computeRsaSha256Signature), then calls the
 * Firestore REST API directly. No Cloud Functions, no billing plan change —
 * service-account calls authenticate via Google Cloud IAM and bypass
 * firestore.rules entirely (those rules only gate Firebase Auth clients).
 *
 * One-time setup: see README.md next to this file.
 */

const FIRESTORE_SCOPE = 'https://www.googleapis.com/auth/datastore';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';

function firestoreBaseUrl_() {
  const projectId = getProp_('FIRESTORE_PROJECT_ID');
  return `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;
}

function getProp_(key) {
  const value = PropertiesService.getScriptProperties().getProperty(key);
  if (!value) throw new Error(`Missing script property: ${key}`);
  return value;
}

/** Signs a service-account JWT and exchanges it for a short-lived OAuth access token. */
function getAccessToken_() {
  const cached = CacheService.getScriptCache().get('access_token');
  if (cached) return cached;

  const email = getProp_('SERVICE_ACCOUNT_EMAIL');
  const privateKey = getProp_('SERVICE_ACCOUNT_PRIVATE_KEY').replace(/\\n/g, '\n');

  const nowSec = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claimSet = {
    iss: email,
    scope: FIRESTORE_SCOPE,
    aud: TOKEN_URL,
    exp: nowSec + 3600,
    iat: nowSec,
  };
  const encode = (obj) =>
    Utilities.base64EncodeWebSafe(JSON.stringify(obj)).replace(/=+$/, '');
  const toSign = `${encode(header)}.${encode(claimSet)}`;
  const signatureBytes = Utilities.computeRsaSha256Signature(toSign, privateKey);
  const signature = Utilities.base64EncodeWebSafe(signatureBytes).replace(/=+$/, '');
  const jwt = `${toSign}.${signature}`;

  const response = UrlFetchApp.fetch(TOKEN_URL, {
    method: 'post',
    payload: {
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    },
    muteHttpExceptions: true,
  });
  const body = JSON.parse(response.getContentText());
  if (!body.access_token) {
    throw new Error(`Token exchange failed: ${response.getContentText()}`);
  }
  CacheService.getScriptCache().put('access_token', body.access_token, body.expires_in - 60);
  return body.access_token;
}

function firestoreFetch_(path, method, body) {
  const options = {
    method: method || 'get',
    headers: { Authorization: `Bearer ${getAccessToken_()}` },
    contentType: 'application/json',
    muteHttpExceptions: true,
  };
  if (body) options.payload = JSON.stringify(body);
  const response = UrlFetchApp.fetch(`${firestoreBaseUrl_()}${path}`, options);
  const code = response.getResponseCode();
  if (code >= 300) {
    throw new Error(`Firestore ${method} ${path} failed (${code}): ${response.getContentText()}`);
  }
  const text = response.getContentText();
  return text ? JSON.parse(text) : null;
}

/** Converts a JS value to a Firestore REST "Value" object. */
function toFirestoreValue_(v) {
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return { integerValue: String(Math.trunc(v)) };
  if (Array.isArray(v)) {
    return { arrayValue: { values: v.map(toFirestoreValue_) } };
  }
  return { stringValue: String(v) };
}

function toFirestoreFields_(obj) {
  const fields = {};
  Object.keys(obj).forEach((k) => {
    fields[k] = toFirestoreValue_(obj[k]);
  });
  return fields;
}

/** Reads a Firestore REST field value back into a plain JS value. */
function fromFirestoreValue_(v) {
  if (!v) return null;
  if ('stringValue' in v) return v.stringValue;
  if ('integerValue' in v) return Number(v.integerValue);
  if ('booleanValue' in v) return v.booleanValue;
  if ('timestampValue' in v) return new Date(v.timestampValue);
  if ('arrayValue' in v) return (v.arrayValue.values || []).map(fromFirestoreValue_);
  return null;
}

/** Finds a /members doc by exact phone match. Returns {id, fields} or null. */
function findMemberByPhone_(phone) {
  const result = firestoreFetch_(':runQuery', 'post', {
    structuredQuery: {
      from: [{ collectionId: 'members' }],
      where: {
        fieldFilter: {
          field: { fieldPath: 'phone' },
          op: 'EQUAL',
          value: { stringValue: phone },
        },
      },
      limit: 1,
    },
  });
  const hit = (result || []).find((r) => r.document);
  if (!hit) return null;
  const id = hit.document.name.split('/').pop();
  const fields = {};
  Object.keys(hit.document.fields || {}).forEach((k) => {
    fields[k] = fromFirestoreValue_(hit.document.fields[k]);
  });
  return { id, fields };
}

function createDoc_(collection, data) {
  const created = firestoreFetch_(`/${collection}`, 'post', { fields: toFirestoreFields_(data) });
  return created.name.split('/').pop();
}

function patchDoc_(collection, id, data) {
  const mask = Object.keys(data).map((k) => `updateMask.fieldPaths=${encodeURIComponent(k)}`).join('&');
  firestoreFetch_(`/${collection}/${id}?${mask}`, 'patch', { fields: toFirestoreFields_(data) });
}

/** "Year 1".."Year 5" -> 1..5, "Alumni" -> status alumni, everything else -> 0/'Other' tag. */
function parseYear_(raw) {
  const match = /(\d+)/.exec(raw || '');
  if (match) return { yearOfStudy: Number(match[1]), status: 'active' };
  if (/alumni/i.test(raw || '')) return { yearOfStudy: 0, status: 'alumni' };
  return { yearOfStudy: 0, status: 'active' };
}

function getAnswer_(itemResponses, titleContains) {
  const item = itemResponses.find((r) =>
    r.getItem().getTitle().toLowerCase().includes(titleContains.toLowerCase())
  );
  return item ? String(item.getResponse()).trim() : '';
}

/** Installable "On form submit" trigger target — see README.md for setup. */
function onFormSubmit(e) {
  try {
    syncResponse_(e.response);
  } catch (err) {
    Logger.log(`Sync failed: ${err}`);
    const adminEmail = PropertiesService.getScriptProperties().getProperty('ADMIN_ALERT_EMAIL');
    if (adminEmail) {
      MailApp.sendEmail(adminEmail, 'Manifest form sync failed', String(err));
    }
    throw err;
  }
}

function syncResponse_(formResponse) {
  const items = formResponse.getItemResponses();

  const name = getAnswer_(items, 'Name');
  const phone = getAnswer_(items, 'Contact');
  const course = getAnswer_(items, 'Course');
  const yearRaw = getAnswer_(items, 'Year');
  const residence = getAnswer_(items, 'Residence');
  const isFirstTimer = getAnswer_(items, 'First Timer').toLowerCase() === 'yes';
  const wantsToServe = getAnswer_(items, 'serve').toLowerCase() === 'yes';
  const wantsTransport = getAnswer_(items, 'transportation').toLowerCase() === 'yes';

  if (!name || !phone) {
    throw new Error(`Response missing name/phone: ${JSON.stringify(items.map((i) => i.getResponse()))}`);
  }

  const { yearOfStudy, status } = parseYear_(yearRaw);
  const existing = findMemberByPhone_(phone);

  const existingTags = (existing && existing.fields.tags) || [];
  const tags = new Set(existingTags);
  if (isFirstTimer) tags.add('firstTimer');

  const memberData = {
    name,
    phone,
    course,
    yearOfStudy,
    campus: 'victoria', // this form is Victoria-campus-specific; see README if reused for Makerere
    status,
    tags: Array.from(tags),
    residence,
    wantsToServe,
    wantsTransport,
  };

  let memberId;
  if (existing) {
    patchDoc_('members', existing.id, memberData);
    memberId = existing.id;
  } else {
    memberData.dateJoined = new Date();
    memberId = createDoc_('members', memberData);
  }

  if (isFirstTimer) {
    const dueDate = new Date();
    dueDate.setDate(dueDate.getDate() + 3);
    createDoc_('assignments', {
      memberId,
      assignedTo: '',
      reason: 'firstTimer',
      status: 'pending',
      dueDate,
    });
  }
}

/** Run manually from the script editor to sanity-check credentials/config. */
function testConnection() {
  const result = firestoreFetch_('/members?pageSize=1', 'get');
  Logger.log(JSON.stringify(result));
}
