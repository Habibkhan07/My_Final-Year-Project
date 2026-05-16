# Customer Profile Feature
**Layer status**: Domain ✅ · Data ✅ · Presentation ✅

---

## Overview
The customer-side identity surface. Owns the bottom-nav Profile tab and four pushed screens behind it:

| Surface | Route | Push from |
|---|---|---|
| Profile tab | (embedded at `IndexedStack` index 3 of `HomeScreen`) | bottom-nav tap |
| Edit profile | `/customer/profile/edit` | Profile header card |
| My addresses | `/customer/addresses` | Profile menu tile |
| About Karigar | `/customer/about` | Profile menu tile |
| Terms & Privacy | `/customer/legal` | Profile menu tile |

**Backend endpoints consumed:**
| Operation | Method | URL |
| :--- | :--- | :--- |
| Read profile | `GET` | `/api/accounts/me/` |
| Update profile | `PATCH` | `/api/accounts/me/` |
| Sign out | `POST` | `/api/accounts/logout/` (wired through `AuthRepository`, not the profile repo) |

---

## Domain Layer

### Entity — `CustomerProfileEntity`
`lib/features/customer/profile/domain/entities/customer_profile_entity.dart`

Freezed immutable. Fed by `GET /api/accounts/me/`. Same shape returned by `PATCH /api/accounts/me/` so the FE notifier swaps state directly from the PATCH response (no second GET round-trip).

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `int` | `auth.User.id`. Stable primary key. |
| `phone` | `String` | E.164 PK number. **Read-only** — changing requires the re-OTP flow. |
| `isTechnician` | `bool` | Sourced from `UserProfile.is_technician`. **Read-only** — flips only when admin approves a TechnicianProfile. |
| `firstName` | `String?` | Empty strings from the backend normalise to `null` at the model boundary so widgets can do `firstName?.isEmpty ?? true`. |
| `lastName` | `String?` | Same null-normalisation. |

---

### Failures — `ProfileFailure` (sealed class)
`lib/features/customer/profile/domain/failures/profile_failure.dart`

All repository methods throw a subclass of `ProfileFailure`. The presentation layer pattern-matches exhaustively. `toString()` returns only the message.

| Class | Trigger |
| :--- | :--- |
| `ProfileNetworkFailure` | `SocketException` + local cache empty (GET); any `SocketException` (PATCH, no write-through cache) |
| `ProfileServerFailure` | Non-2xx HTTP response other than 401. Carries `errors` map from the standard envelope for field-level highlighting. |
| `ProfileUnauthorizedFailure` | 401 from the backend OR missing/empty token in secure storage. Triggers a forced sign-out via the presentation layer. |
| `ProfileParsingFailure` | `FormatException` on JSON decode. |

---

### Repository Interface — `IProfileRepository`

| Method | Returns | Throws |
| :--- | :--- | :--- |
| `getMe()` | `CustomerProfileEntity` | Any `ProfileFailure` |
| `updateMe({firstName, lastName})` | `CustomerProfileEntity` (fresh post-update state) | Any `ProfileFailure` |

---

### Use Cases
`lib/features/customer/profile/domain/use_cases/`

Thin delegates — they exist to keep the presentation layer decoupled from the repository interface and to give us easy provider override points in tests.

| Use Case | Delegates to |
| :--- | :--- |
| `GetMeUseCase` | `repository.getMe()` |
| `UpdateMeUseCase` | `repository.updateMe(...)` |

---

## Data Layer

### Model — `CustomerProfileModel`
`lib/features/customer/profile/data/models/customer_profile_model.dart`

JSON ↔ Dart mapping for both `GET` and `PATCH /me/`.
- `fromJson()` normalises empty strings (`""`) to `null` for `firstName` / `lastName` so the UI's null-vs-non-null branching stays clean.
- `toJson()` is used only for cache serialisation; outgoing PATCH bodies are constructed in the remote data source directly (only two fields are writeable).
- `toEntity()` is the single conversion point — the domain layer never sees the wire-format model.

---

### Data Sources

#### `ProfileRemoteDataSource`
`lib/features/customer/profile/data/data_sources/profile_remote_data_source.dart`

| Method | HTTP | Notes |
| :--- | :--- | :--- |
| `getMe(token)` | `GET /api/accounts/me/` | `Authorization: Token <token>` |
| `updateMe({token, firstName, lastName})` | `PATCH /api/accounts/me/` | JSON body `{"first_name": ..., "last_name": ...}` |

Non-2xx responses are parsed into `HttpFailure(statusCode, code, message, errors)` and re-thrown. The `code` field drives the repository's failure mapping. Mirrors the parser shape of `AuthRemoteDataSource` so all authenticated surfaces stay consistent.

#### `ProfileLocalDataSource`
`lib/features/customer/profile/data/data_sources/profile_local_data_source.dart`

- Backed by `SharedPreferences` (Tier 2 cache per CLAUDE.md).
- Single key `"cached_profile_me"`. We do not key by user id — the auth local cache is the source of truth for "who is logged in", and its `clearAll()` runs on logout via `AuthRepositoryImpl.logout()`.
- `getCachedProfile()` returns `null` on miss OR corrupted JSON. Never throws.

---

### Repository Implementation — `ProfileRepositoryImpl`
`lib/features/customer/profile/data/repositories/profile_repository_impl.dart`

The single arbitration point between remote, local cache, and the secure-storage token.

**`getMe()` — offline-first**:
1. Read token from `FlutterSecureStorage`. Missing → `ProfileUnauthorizedFailure`.
2. Hit remote. Success → cache the model + return entity.
3. `SocketException` → fall back to cache. Hit → return cached entity. Miss → `ProfileNetworkFailure`.
4. `HttpFailure` → `_mapHttp(e)` translates `code` to the sealed domain failure.
5. `FormatException` → `ProfileParsingFailure`.

**`updateMe()` — no write-through cache**:
1. Read token. Missing → `ProfileUnauthorizedFailure`.
2. Hit remote. Success → refresh cache from the post-update state + return entity.
3. `SocketException` → `ProfileNetworkFailure("Cannot save changes while offline.")`. Mutations never optimistically write.
4. Other paths same as `getMe()`.

---

## Presentation Layer

### Providers
`lib/features/customer/profile/presentation/providers/dependency_injection.dart`

Wiring order:
```
profileHttpClient / profileSecureStorage
    ↓
profileRemoteDataSource / profileLocalDataSource
    ↓
profileRepository
    ↓
getMeUseCase / updateMeUseCase
    ↓
profileProvider (ProfileNotifier — keepAlive)
```

The `profileLocalDataSource` reuses the global `sharedPreferencesProvider` defined in the technician onboarding DI (overridden in `main.dart`'s `ProviderScope` at boot).

### `ProfileNotifier`
`lib/features/customer/profile/presentation/providers/profile_notifier.dart`

`@Riverpod(keepAlive: true)`. The profile is read across multiple unrelated screens (tab header, edit screen, etc.) so we keep it warm.

| Method | Behaviour |
| :--- | :--- |
| `build()` | Fetches `GET /me/` via the use case. Offline-first via the repo. |
| `refresh()` | Re-fetches from remote; surfaced for pull-to-refresh. |
| `updateName({firstName, lastName})` | PATCHes `/me/`. On success **also** calls `authProvider.notifier.updateProfileNames(...)` so widgets reading `authProvider.user.firstName` (dashboard greeting, etc.) reflect the new value without a second invalidation. |

Logout-invalidation is implicit: `AuthRepositoryImpl.logout()` clears the secure-storage token, which causes the next `getMe()` to throw `ProfileUnauthorizedFailure`. The presentation layer handles that by triggering another `logout()` — idempotent — and bouncing through go_router's redirect to `/login`.

---

### Screens

#### `ProfileTabScreen`
`lib/features/customer/profile/presentation/screens/profile_tab_screen.dart`

The Profile tab body. Embedded in `HomeScreen`'s lazy `IndexedStack` at index 3.

Layout (matches the visual language of `AddressSelectorSheet` for consistency):
1. **Header card** — tappable, pushes `/customer/profile/edit`. Avatar circle (initials), full name, phone, "CUSTOMER" chip, trailing chevron.
2. **ACCOUNT** section — `My addresses`, `Technician Mode`.
3. **ABOUT** section — `About Karigar`, `Terms & Privacy`.
4. **Sign out** outlined-red button + version footer (`Karigar · v1.0.0`).

**Pull-to-refresh** re-runs `profileProvider.notifier.refresh()`.

**Error state**: `ProfileUnauthorizedFailure` triggers a forced sign-out via `WidgetsBinding.addPostFrameCallback`; everything else renders a centred "Retry" CTA.

#### `_TechnicianModeTile` — single smart-routing button
Reads `technicianStatusProvider` + cached `user.isTechnician`. Routes are:
- `!isTechnician` → `/technician/onboarding`
- `TechnicianStatusPending | TechnicianStatusRejected` → `/technician/pending`
- `TechnicianStatusApproved` → `/technician/dashboard`
- Status `AsyncLoading` (cold cache) → trailing spinner, tap is a no-op until resolved

No three-variant labels — the destination screen is itself the state surface (the holding screen renders pending/rejected; the dashboard renders approved).

#### `EditProfileScreen`
`lib/features/customer/profile/presentation/screens/edit_profile_screen.dart`

Pushed from the header card.
- AppBar back arrow + "Edit profile" title.
- Phone field is **read-only** (lock icon, greyed). Subtitle: "Phone changes require a re-verification (coming soon)."
- Two `TextFormField`s (first/last) pre-filled from `profileProvider`.
- Save button: 56h, 16-rad, `#0051AE`, matches the `AddressSelectorSheet` footer chrome exactly. Disabled + shows a spinner while the PATCH is in flight.
- Field-level errors from `errors['first_name']` / `errors['last_name']` surface as form-validator messages (red border + inline text).

#### `CustomerAddressesScreen`
`lib/features/customer/profile/presentation/screens/customer_addresses_screen.dart`

Full-page address list. Reuses `addressesProvider` from the addresses feature; mirrors the visual chrome of `AddressSelectorSheet`'s `_AddressTile` so the sheet and screen feel identical.

- Tap a row → set as default (calls `UpdateAddressUseCase(isDefault: true)`, then invalidates `addressesProvider`).
- Swipe-to-delete → calls `DeleteAddressUseCase` + invalidates.
- AppBar `+` action → pushes `/addresses/map-picker` (the **only** create flow — never duplicated).
- Empty state has a brand-blue CTA that also pushes the map picker.

#### `AboutKarigarScreen` / `TermsAndPrivacyScreen`
Static screens for viva-defensibility. App version is hardcoded `1.0.0` for now (see `flag.md` — `package_info_plus` is not yet on `pubspec`).

---

## Auth Repository — server-side logout wiring

The customer Profile feature triggers logout, but the wiring lives in the auth feature.

`AuthRemoteDataSource.logout(token)` — POSTs `/api/accounts/logout/` with `Authorization: Token <token>`. Throws `HttpFailure` on non-2xx.

`AuthRepositoryImpl.logout()` — now:
1. Reads token from secure storage.
2. Calls `remote.logout(token)` inside a try/catch — offline / 401 failures are swallowed (the local clear below is the source of truth).
3. Calls `local.clearAll()` unconditionally.

The order matters: token must be in storage when `remote.logout()` runs (its Authorization header needs it). Local clear happens regardless so a network failure never traps the user in a logged-in shell.

`AuthNotifier.logout()` ordering (auth_notifier.dart:142–144) is unchanged:
1. `AppLifecycleOrchestrator.teardownOnLogout(ref)` — FCM device unregister (needs token).
2. `repository.logout()` — server-side token invalidation + local clear (this slice's change).
3. `state = AsyncData(AuthState())` — go_router's `user == null` redirect bounces to `/login`.

---

## Tests
`test/features/customer/profile/`

| Test file | Coverage |
| :--- | :--- |
| `data/repositories/profile_repository_impl_test.dart` | 9 cases. Full error-pipeline mapping for `getMe()` and `updateMe()`: cache hit/miss on `SocketException`, 401 → `Unauthorized`, 400 → `ServerFailure(errors)`, missing token guard, mutations never write-through cache on offline. |
| `presentation/providers/profile_notifier_test.dart` | 5 cases. State machine: `build()` Data + Error transitions, `updateName()` Loading → Data + Loading → Error (with `errors` map preserved), `refresh()` re-fetches. `ProviderContainer`-based per CLAUDE.md (no widget mounting). |

Widget tests are deliberately skipped for the viva sprint — UI is hand-verified.

---

## Visual consistency

Profile-feature screens duplicate the literal color tokens from `AddressSelectorSheet` (`#0051AE`, `#151C24`, `#424753`, `#727785`) rather than reading from `AppColors`. This is intentional and tracked under [[project_ui_cleanup_planned]] — when the design-system pass lands the two surfaces consolidate onto one token set. Until then, both surfaces pin to the same literal hex so they stay in lockstep.
