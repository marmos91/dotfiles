/**
 * gcal-personal-block — mirror Family calendar events onto the work calendar
 * as opaque "Personal Commitment" blocks.
 *
 * Apps Script port of the previous python/launchd implementation. Runs as the
 * signed-in work account with Google's own hourly trigger: no OAuth client,
 * no consent screen, no verification, no token expiry.
 *
 * Deploy once (script.google.com, signed in as the work account):
 *   1. New project → paste this file → rename "gcal-personal-block"
 *   2. Services (left sidebar) ➜ add the "Google Calendar API" service
 *   3. Project Settings → Script Properties → add:
 *        familyCalendarId = <Family calendar ID>
 *   4. Triggers (clock icon) → Add trigger → syncMirror → hourly
 *   5. Run syncMirror once from the editor to approve the permission dialog
 *
 * Only the work primary calendar is written; Family is read-only here.
 * Placeholders are keyed by the Family event's instance id via
 * extendedProperties.private.familyMirrorId, so moves/deletes replay cleanly
 * instead of leaving stale blocks. Idempotent; safe to run hourly.
 */

const TITLE = '🏠 Personal Commitment';
const COLOR_ID = '4'; // flamingo — the shade reclaim used
// Google silently drops private ext-property keys > 41 chars
const KEY = 'familyMirrorId';
const DESCRIPTION =
  'Marco has a personal commitment and is busy at this time.\n' +
  'Please find another time to avoid scheduling conflicts.\n\n' +
  '--\nPowered by Mimir';
const LOOKAHEAD_DAYS = 60;
const WIPE_BEHIND_DAYS = 30; // placeholders whose Family event vanished get removed
const NO_REMIND = { useDefault: false, overrides: [] }; // zero notifications

/** Hourly entry point. Uses the advanced Calendar service (Calendar.Events)
 *  because the simple CalendarApp cannot set extendedProperties or colorId. */
function syncMirror() {
  const familyId = PropertiesService.getScriptProperties().getProperty('familyCalendarId');
  if (!familyId) throw new Error('script property familyCalendarId is not set');

  const now = new Date();
  const tmin = now.toISOString();
  const tmax = new Date(now.getTime() + LOOKAHEAD_DAYS * 86400000).toISOString();
  const past = new Date(now.getTime() - WIPE_BEHIND_DAYS * 86400000).toISOString();

  // 1. family events ahead — singleEvents expands recurrences into instances,
  // each with a unique id, so each occurrence gets its own placeholder
  const fam = listEvents(familyId, { timeMin: tmin, timeMax: tmax })
    .filter(e => e.status !== 'cancelled' && e.summary);
  console.log('family events in window: ' + fam.length);

  const want = {};
  for (const e of fam) {
    want[e.id] = {
      summary: TITLE,
      description: DESCRIPTION,
      start: e.start,
      end: e.end,
      transparency: 'opaque',
      colorId: COLOR_ID,
      reminders: NO_REMIND,
      extendedProperties: { private: { [KEY]: e.id } },
    };
  }

  // 2. existing placeholders on the work calendar (key-presence filter is
  // client-side: server-side empty-value ext-property filters return nothing).
  // timeMax is mandatory: singleEvents expands endless recurrences (daily
  // standups, weeklies) into instances forever, and an unbounded list OOMs
  // Apps Script — placeholders can only exist inside [past, tmax] anyway,
  // since that's the same window we create them in.
  const have = {};
  for (const e of listEvents('primary', { timeMin: past, timeMax: tmax, wantKey: KEY })) {
    have[e.extendedProperties.private[KEY]] = e;
  }

  let created = 0, patched = 0, removed = 0, errors = 0;
  // every mutation is try/caught so one bad event can't abort the run and
  // starve the events after it — that's one way stale blocks survived reruns
  for (const [fid, e] of Object.entries(have)) {
    if (fid in want) continue;
    try {
      Calendar.Events.remove('primary', e.id, { sendUpdates: 'none' });
      removed++;
    } catch (err) {
      errors++;
      console.error(`remove ${e.id}: ${err}`);
    }
  }

  // patch existing placeholders unconditionally instead of diffing against
  // the API echo: drift detection proved unreliable (a shortened family
  // event left a stale block), and a write per family event per hour is
  // harmless — sendUpdates: none, no attendee mail, trivial quota.
  // NOTE: this reverts manual edits to a mirrored block (times, color,
  // description) within the hour — adjust the Family event instead.
  for (const [fid, body] of Object.entries(want)) {
    const cur = have[fid];
    try {
      if (!cur) {
        Calendar.Events.insert(body, 'primary', { sendUpdates: 'none' });
        created++;
      } else {
        Calendar.Events.patch(
          { start: body.start, end: body.end, description: DESCRIPTION,
            colorId: COLOR_ID, reminders: NO_REMIND },
          'primary', cur.id, { sendUpdates: 'none' });
        patched++;
      }
    } catch (err) {
      errors++;
      console.error(`${cur ? 'patch' : 'insert'} ${fid}: ${err}`);
    }
  }
  console.log(`created ${created}, patched ${patched}, removed ${removed}, errors ${errors}`);
}

/** Paged Events.list wrapper. opts: timeMin, timeMax, wantKey (client-side
 *  presence filter on the private ext property). */
function listEvents(cal, opts) {
  const out = [];
  let token;
  do {
    const args = { singleEvents: true, orderBy: 'startTime', maxResults: 2500 };
    if (opts.timeMin) args.timeMin = opts.timeMin;
    if (opts.timeMax) args.timeMax = opts.timeMax;
    if (token) args.pageToken = token;
    const res = Calendar.Events.list(cal, args);
    let evs = res.items || [];
    if (opts.wantKey) {
      evs = evs.filter(
        e => e.extendedProperties && e.extendedProperties.private &&
             opts.wantKey in e.extendedProperties.private);
    }
    out.push.apply(out, evs);
    token = res.nextPageToken;
  } while (token);
  return out;
}
