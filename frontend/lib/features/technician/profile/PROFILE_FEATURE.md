# Technician Profile Feature
**Layer status**: Domain ✅ · Data ✅ · Presentation ✅

---

## Overview
The technician-side identity surface. Owns the bottom-nav Profile tab (pushed from `TechnicianDashboardScreen`) and three child routes: the My Skills CRUD list, the Add Skill picker, and the existing Work Location picker / Wallet / Customer-mode switch which are linked from the menu.

| Surface | Route | Push from |
|---|---|---|
| Tech Profile tab | `/technician/profile` | bottom-nav index 3 tap on `TechnicianDashboardScreen` |
| My Skills | `/technician/profile/skills` | Profile menu "My Skills" tile |
| Add Skill | `/technician/profile/skills/add` | My Skills app-bar `+` action |
| Edit name | `/customer/profile/edit` | Profile header card (reuses customer screen) |
| Work Location | `/technician/work-location` | Profile menu (existing route) |
| Wallet | `/technician/wallet` | Profile menu (existing route) |
| About Karigar | `/customer/about` | Profile menu (reuses customer route) |
| Terms & Privacy | `/customer/legal` | Profile menu (reuses customer route) |
| Customer Mode | `/home` | Profile menu — routes back to customer shell |

**Backend endpoints consumed:**
| Operation | Method | URL |
|---|---|---|
| List my skills | `GET` | `/api/technicians/me/skills/` |
| Add a skill | `POST` | `/api/technicians/me/skills/` |
| Remove a skill | `DELETE` | `/api/technicians/me/skills/<sub_service_id>/` |
| Picker catalog | `GET` | `/api/technicians/me/service-categories/` (category-gated) |
| Profile read/write | `GET / PATCH` | `/api/accounts/me/` (reused via customer's `profileProvider`) |

---

## Architectural decisions

### 1. Identity is role-agnostic — reuse the customer profile provider
`/api/accounts/me/` returns the same shape for customers and technicians. The tech profile tab consumes the customer-side `profileProvider` directly and pushes `/customer/profile/edit` for name editing. This avoids parallel state and keeps a single source of truth for the auth user's display name across both shells.

### 2. About / Terms routes are reused, not duplicated
`/customer/about` and `/customer/legal` render brand-neutral content. The tech tile pushes those routes verbatim. Renaming them to `/karigar/about` / `/karigar/legal` is tracked under [[project_ui_cleanup_planned]] — not bundled with this slice because it touches the customer feature too.

### 3. Skills is a feature, identity reuse is a tile
The skill CRUD surface is the only net-new feature here; everything else on the tab is a tile that pushes to an existing screen. The feature directory at `lib/features/technician/profile/` therefore contains skills-shaped layers; the tab screen itself is a thin presentation file at the top of `presentation/screens/`.

### 4. Delete keys by `sub_service_id`, not by skill PK
`/api/technicians/me/skills/<sub_service_id>/` mirrors the user's mental model: "remove this specialty from my skills". The bridge-row PK is an implementation detail the FE never needs.

### 5. labor_rate is NOT collected on add
The backend writes `labor_rate=NULL` on rows created via this endpoint. The column stays on the model for back-compat with `bookings.pricing_selector` (which still reads `TechnicianSkill.labor_rate` for Scenario B labor gigs). The onboarding-refactor session will decide whether to drop the column or migrate it to a per-quote field. See [[project_tech_onboarding_refactor]].

### 6. years_of_experience defaults to 0, hidden from UI
Same reasoning: simpler add flow, and the field isn't surfaced read-side. The onboarding flow still writes a real value; this CRUD endpoint just doesn't ask.

### 7. Skills CRUD is category-gated by `TechnicianServiceLicense`
A tech may only add sub-services whose parent service is one they opted into at onboarding — encoded by their `TechnicianServiceLicense` row set. The Add Skill picker fetches `GET /api/technicians/me/service-categories/` (services filtered to the tech's licenses) and the backend `POST /me/skills/` enforces the same gate as defence-in-depth — emitting `403 category_not_allowed` if the picker cache is stale. Closes the bypass where any approved tech could silently jump categories without admin re-evaluation.

`TechnicianServiceLicense` is the **source of truth** for "categories this tech can work in":
- One row per parent service the tech picked skills under (auto-created at onboarding finalize).
- `license_picture` is optional — admin can attach the legal document later, or a future "request verification" flow can populate it. Row existence is the gate; picture existence is documentation.
- A tech who drops every skill under a category still sees that category in the picker — the license row survives skill churn. "What categories did I opt into" is decoupled from "what skills do I currently offer."

Copy is intentionally neutral: snackbars and the "no categories" empty state name the rule without promising a self-serve "request a new category" flow the platform does not yet implement.

---

## Domain Layer

### Entities (`domain/entities/`)
- `TechnicianSkillEntity` — one row in My Skills, with nested `SubServiceRef` → `ParentServiceRef`. Used by the My Skills screen for service-grouped rendering.
- `AvailableServiceEntity` / `AvailableSubServiceEntity` — Add Skill picker's catalog tree, fed by the onboarding metadata endpoint.

### Failures — `SkillsFailure` (sealed, `domain/failures/skills_failure.dart`)
| Class | Trigger |
|---|---|
| `SkillsNetworkFailure` | `SocketException` + cache empty (list); `SocketException` (mutations, no write-through cache) |
| `SkillsUnauthorizedFailure` | 401 or missing token. Triggers forced sign-out via the presentation layer. |
| `SkillsNotATechnicianFailure` | 403 `permission_denied`. Should never happen inside the tech shell but the contract has the case. |
| `SkillsDuplicateFailure` | POST 409 `duplicate_skill`. Filtered out client-side by the picker; backend is source of truth. |
| `SkillsLastSkillFailure` | DELETE 400 `last_skill_required`. UX nudge: "add a new one before removing this". |
| `SkillsCategoryNotAllowedFailure` | POST 403 `category_not_allowed`. Carries `serviceName` for the snackbar. Defence-in-depth — the picker hides services without a `TechnicianServiceLicense` row, so this fires only on stale picker cache or mid-flight admin revocation of a license row. |
| `SkillsServerFailure` | Catch-all non-2xx; carries the envelope's `errors` map. |
| `SkillsParsingFailure` | `FormatException` on JSON decode. |

### Repository Interface — `ISkillsRepository`
| Method | Returns | Notes |
|---|---|---|
| `listMySkills()` | `List<TechnicianSkillEntity>` | Offline-first. |
| `addSkill({subServiceId})` | `TechnicianSkillEntity` | No write-through cache; clears cache on success. |
| `removeSkill({subServiceId})` | `void` | No write-through cache; clears cache on success. |
| `listAvailableServices()` | `List<AvailableServiceEntity>` | Online-only. |

### Use Cases — `domain/use_cases/`
Thin delegates: `ListMySkillsUseCase`, `AddSkillUseCase`, `RemoveSkillUseCase`, `ListAvailableServicesUseCase`. They exist to keep the notifier off the repository interface and to give tests easy override points.

---

## Data Layer

### Models (`data/models/`)
Plain Dart wire DTOs (not Freezed) — matches the customer profile pattern. `TechnicianSkillModel` and the `AvailableServiceModel` / `AvailableSubServiceModel` pair each carry their own `fromJson`, `toJson`, and `toEntity`.

### Data Sources
- `SkillsRemoteDataSource` — HTTP via `package:http`. Non-2xx responses parsed into `HttpFailure(statusCode, code, message, errors)` from the project's standard envelope. Mirrors the parser shape of every other authenticated remote DS.
- `SkillsLocalDataSource` — Tier 2 `SharedPreferences` cache under a single key `cached_tech_skills`. Mutations invalidate the cache (no optimistic write-through).

### Repository — `SkillsRepositoryImpl`
Single arbitration point. Per CLAUDE.md offline-first pattern:
- `listMySkills` — remote → cache on success; on `SocketException` fall back to cache → `SkillsNetworkFailure` if miss.
- `addSkill` / `removeSkill` — remote-first; clear local cache on success; never optimistic.
- `listAvailableServices` — online-only (the picker is transient and the catalog list is small).
- `_mapHttp` translates the envelope's `code` field to the sealed failure subclasses (`duplicate_skill`, `last_skill_required`, `unauthorized`, `permission_denied`).

---

## Presentation Layer

### Providers (`presentation/providers/`)
`dependency_injection.dart` wires the chain identically to the customer profile feature:
```
skillsHttpClient / skillsSecureStorage
    ↓
skillsRemoteDataSource / skillsLocalDataSource (shared SharedPreferences)
    ↓
skillsRepository
    ↓
list / add / remove / listAvailableServices use cases
    ↓
skillsProvider (Skills notifier — @Riverpod(keepAlive: true))
```

### `Skills` notifier (`skills_notifier.dart`)
- `build()` — fetches via `ListMySkillsUseCase`.
- `refresh()` — pull-to-refresh on My Skills. Preserves previous data on failure (no AsyncLoading flash).
- `addSkill({subServiceId})` — calls the use case, merges the returned row into the in-memory list with the same service-then-name sort the backend uses, returns the entity.
- `removeSkill({subServiceId})` — calls the use case, drops the row by sub_service id.

### Screens
- `TechnicianProfileTabScreen` — mirrors `ProfileTabScreen` (customer side). Header card → `/customer/profile/edit`. ACCOUNT tiles: My Skills, Work Location, Wallet, Customer Mode. ABOUT tiles: About Karigar, Terms & Privacy. Sign out + version footer. Uses the same brand-blue tokens (`#0051AE` / `#151C24` / `#424753` / `#727785`) as the customer surface.
- `MySkillsScreen` — service-grouped list. Each row has an SVG icon (via `IconAssets.path`), name, optional "Fixed-price gig" sub-label, and a trailing `X` icon-button that fires an `AlertDialog` confirm before calling `removeSkill`. `SkillsLastSkillFailure` surfaces as a snackbar; `SkillsUnauthorizedFailure` triggers `authProvider.notifier.logout()`.
- `AddSkillScreen` — two-step picker. Step 1 is a 3-column grid of services. Step 2 is a list of sub-services under the chosen service, filtered against the current `skillsProvider` so duplicates are never offered. Tap → POST → snackbar "Added X to your skills" → pop.

### Routing
`lib/core/routing/app_router.dart` registers three new routes (`/technician/profile`, `/technician/profile/skills`, `/technician/profile/skills/add`). `TechnicianDashboardScreen`'s bottom-nav `onTap` now handles index 3 by pushing `/technician/profile`.

---

## Tests
`test/features/technician/profile/`

| Test file | Coverage |
|---|---|
| `data/repositories/skills_repository_impl_test.dart` | 13 cases. `listMySkills` offline-first paths; auth/permission mapping; mutations never optimistic; `duplicate_skill` / `last_skill_required` → typed failures. |
| `presentation/providers/skills_notifier_test.dart` | 6 cases. `build` Data/Error transitions, `addSkill` merge + sort + state-preserved-on-failure, `removeSkill` drop + state-preserved-on-LastSkill. `ProviderContainer`-based per CLAUDE.md (no widget mounting). |

Widget tests are deliberately skipped per the CLAUDE.md viva-sprint policy.

---

## Visual consistency
Tech profile screens duplicate the literal color tokens from the customer profile feature (which itself mirrors `AddressSelectorSheet`). When the design-system pass lands ([[project_ui_cleanup_planned]]) all three surfaces consolidate onto one token set. Until then they all pin to the same literal hex so they stay in lockstep.
