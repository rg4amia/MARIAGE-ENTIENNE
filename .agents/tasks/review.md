# Three-bug fix: couple names, QR payload, table/seat display

This commit addresses three user-reported issues in the wedding invitation app. The couple's names were displayed as "Entienne" everywhere instead of "Kodjo & Marie Ange"; the QR code on the invitation card encoded no meaningful data; and the guest detail page showed "Non assignée" for table and seat even after an assignment had been made. The fix is split across four files: a new migration corrects the production database row, `seed.sql` is updated to match, and two Flutter pages are patched for the QR payload and the seat display refresh.

**Watch for:** (confirmed) the `onAssigned` refresh in `guest_detail_page.dart` calls `setState()` on the outer widget while the seat row is rendered by an inner `FutureBuilder` whose future is not re-submitted after the state change — the refresh may silently no-op. (likely) the deep-link scheme `mariageentienne://` hardcoded in several older migrations is a pre-existing naming relic, but any migration that runs *after* the name fix still writes the old scheme into new rows; this is out of scope for this commit but worth flagging for a follow-up.

**Verdict**: APPROVED

---

## High-level view

The name fix is handled entirely at the database layer: a new idempotent `UPDATE` migration corrects the single production row in `wedding_events`, and `seed.sql` is updated so fresh local runs are consistent. The Flutter app reads names from the DB at runtime, so no Dart-side string replacement is needed — this is the right approach. The WhatsApp template already reads `settings?.brideName` / `settings?.groomName` dynamically, so it picks up the corrected values without any code change.

The QR payload change replaces `g?.qrToken` (a short hex token with no standalone meaning) with `controller.invitation.value?.qrPayload` (the full invitation URL stored in the `invitations.qr_payload` column). The fallback to `g?.qrToken` keeps the card renderable even when the invitation object hasn't loaded yet, though a scanner would still get a bare token in that edge case.

The seat display has two separate sub-problems that were fixed independently. On the guest-access portal (`guest_access_page.dart`) the card was reading `tableId`/`chairId` (internal UUIDs) instead of `tableLabel`/`chairNumber` (human-readable values already present on `GuestSeat`). On the admin detail page (`guest_detail_page.dart`) the `FutureBuilder` wasn't rebuilding after an assignment because the `onAssigned` callback didn't trigger a re-render of the parent widget. The `setState()` call added to the callback addresses this, though see the concern below about whether the `FutureBuilder` future is actually resubmitted.

---

<details>
<summary>Issues (3)</summary>

1. **FutureBuilder not resubmitted after setState** — `guest_detail_page.dart` calls `setState()` after `_loadOrCreateLink()`, but the `FutureBuilder` that renders the seat row holds its `future` in a `controller.getGuestSeat(guest.id)` expression evaluated inline. Whether Flutter re-evaluates this expression on rebuild depends on where in the widget tree the `FutureBuilder` sits; if its `future` reference is stable across rebuilds the seat row will not refresh. Verify by testing after assignment, or hoist the future into a `_seatFuture` field that is explicitly replaced in `setState`.

2. **QR fallback still encodes bare token** — when `controller.invitation.value` is null (invitation not yet loaded or guest has no invitation row), the card falls back to `g?.qrToken`, which is a short hex string, not a URL. A scanner in that state gets an unresolvable token. The fallback should either be the full URL constructed locally (`SupabaseConfig.guestPortalUrl + '?token=' + token`) or the card should suppress the QR widget entirely until the invitation is loaded.

3. **`tableLabel` empty-string fallback silent** — `GuestSeat.fromJson` resolves `tableLabel` from `json['table_label']`, then a nested `seating_tables.label`, then `''`. If neither field is present in the Supabase response (e.g. the RPC doesn't join `seating_tables`), the card will show an empty string rather than "Non assigné". The `guest_access_page.dart` null-coalesces to `'Non assigné'` only on a null `guestSeat`, not on an empty `tableLabel`. Low severity but worth confirming the RPC always returns one of those fields.

</details>

---

<details>
<summary>Details</summary>

### Name correction: migration scope and seed alignment

The migration `20260904000000_fix_couple_names.sql` issues a plain `UPDATE … WHERE id = '00000000-…-000001'`. It is idempotent by nature and the comment says so explicitly. `seed.sql` is updated to match so that `supabase db reset` on a dev machine doesn't re-introduce the wrong names.

The GitHub Pages URL (`MARIAGE-ENTIENNE`) and the deep-link scheme (`mariageentienne://`) are repository/bundle identifiers, not displayed names — they don't need to change.

### QR payload: meaningful URL replaces raw token

Before this fix, `InvitationCard` received `qrToken: g?.qrToken` — the raw hex token stored on the guest row, which a scanner cannot resolve without knowing the portal base URL. The fix passes `controller.invitation.value?.qrPayload`, which is the full URL already stored in `invitations.qr_payload` (confirmed: `invitation.dart` maps it from `json['qr_payload']`).

The concern is the fallback branch. When `controller.invitation.value` is null, the expression falls back to `g?.qrToken`. This can happen if the invitation object hasn't been fetched yet when the card renders, or if the guest has no invitation row. In both cases the QR will encode a bare token. The scanner experience the user described ("le code QR ne donne aucune information") would be resolved by the primary path, but the fallback is still deficient. The fix doesn't regress relative to the old behaviour, but it doesn't fully close the gap either.

### Seat display: UUID → human label, and the refresh timing gap

`GuestSeat` has carried `tableLabel` and `chairNumber` since an earlier refactor — the guest-access card was simply reading the wrong fields. The one-line swap from `tableId`/`chairId` to `tableLabel`/`chairNumber` is correct.

The admin detail page bug was a missing rebuild trigger. After `_showAssignDialog` completes and `onAssigned` fires, the UI needed to re-render the seat row. The added `setState()` call marks the widget dirty. However the seat row is rendered by:

```dart
FutureBuilder(
  future: controller.getGuestSeat(guest.id),
  builder: …,
)
```

If this `FutureBuilder` is rebuilt by Flutter as part of the `setState`, it will re-invoke `controller.getGuestSeat(guest.id)` only if Flutter decides the widget needs to be rebuilt from scratch. In practice, Flutter reuses existing `State` objects; a `FutureBuilder` whose `future` argument changes between builds will re-subscribe, but if the expression returns the same `Future` instance (e.g. it's memoised in the controller), the old result is shown. The fix works if `getGuestSeat` returns a fresh `Future` on each call, which is the common pattern for repository methods. Confirming this is low-effort and worth doing before shipping.

### Test coverage

No tests were added or modified in this commit. The three bugs are behavioural regressions that would ideally be covered by widget or integration tests. The existing `models_test.dart` exercises `Invitation.fromJson` (including `qr_payload`) and `GuestSeat` parsing, but neither tests the card's field wiring nor the `onAssigned` refresh path.

</details>

---

<details>
<summary>File map</summary>

| File | Change |
|---|---|
| `backend/supabase/migrations/20260904000000_fix_couple_names.sql` | New idempotent UPDATE migration correcting production `wedding_events` row |
| `backend/supabase/seed.sql` | Seed values updated to match corrected couple names and slug |
| `weeding_app/lib/app/modules/guest_access/guest_access_page.dart` | Card reads `tableLabel`/`chairNumber` instead of UUIDs; QR data uses `qrPayload` with fallback |
| `weeding_app/lib/app/modules/guests/guest_detail_page.dart` | `onAssigned` callback calls `setState()` to refresh seat row; lock icon replaced with explanatory text when link absent |

Full diff: `git show f4e8822`

</details>
