# Debugging Technician Profile Navigation

## The Problem
You reported that tapping a `TechnicianCard` on the Discovery Results screen just scrolls and doesn't bring up the profile, even though the Django server logs show successful `HTTP 200` responses for the `GET /api/customers/technician-profile/{id}/` endpoint.

## The Root Causes

### 1. JSON Parsing Crash (The `icon_name` bug)
I intercepted the server response for the technician profile and noticed something critical in your seed data:
```json
  "skills": [
    {
      "name": "Freon Gas Top-up",
      "icon_name": null
    }
  ]
```
The backend is sending `null` for `icon_name`. However, our Flutter data models (`TechnicianSkillModel` and `TechnicianSkillEntity`) strictly expect a non-null `String`. 

When Riverpod successfully fetches the `HTTP 200` response and tries to parse it via `.fromJson()`, Dart throws a silent `TypeError` (null is not a subtype of String). This immediately throws the `TechnicianProfileNotifier` into an `AsyncError` state.

### 2. Missing Hot Restart
Because we added a brand new top-level route (`/technician-profile/:id`) to `app_router.dart`, Flutter's `GoRouter` requires a **Full Hot Restart** (or completely stopping and rebuilding the app) to register the new route tree. If you only hot reloaded, `context.push()` might silently fail or get swallowed.

---

## How to Fix It (Step-by-Step)

When you return from university, follow these steps to fix the issue:

### Step 1: Make `iconName` Nullable in the Entity
Open `frontend/lib/features/booking/domain/entities/booking_entities.dart` and change `TechnicianSkillEntity`:
```dart
@freezed
abstract class TechnicianSkillEntity with _$TechnicianSkillEntity {
  const factory TechnicianSkillEntity({
    required String name,
    required String? iconName, // <-- ADD QUESTION MARK HERE
  }) = _TechnicianSkillEntity;
}
```

### Step 2: Make `iconName` Nullable in the Model
Open `frontend/lib/features/booking/data/models/booking_models.dart` and change `TechnicianSkillModel`:
```dart
@freezed
abstract class TechnicianSkillModel with _$TechnicianSkillModel {
  const factory TechnicianSkillModel({
    required String name,
    @JsonKey(name: 'icon_name') required String? iconName, // <-- ADD QUESTION MARK HERE
  }) = _TechnicianSkillModel;

  // ... (keep fromJson and the rest) ...

  TechnicianSkillEntity toEntity() => TechnicianSkillEntity(
        name: name,
        iconName: iconName,
      );
}
```

### Step 3: Re-run Code Generation
Because we modified `@freezed` models, you must regenerate the `.freezed.dart` and `.g.dart` files. Open your terminal and run:
```bash
cd frontend
dart run build_runner build --delete-conflicting-outputs
```

### Step 4: Fix the UI to handle null icons
Open `frontend/lib/features/booking/presentation/screens/technician_profile_screen.dart`. Scroll down to where the skills are rendered (around the `_InfoListTile` or wherever skills are mapped) and ensure you aren't forcing a null `iconName` into an SVG renderer without a fallback.

### Step 5: Full Restart
Stop the Flutter app completely (`Shift + F5` or `Stop` in VSCode) and run it again to ensure `GoRouter` picks up the new `/technician-profile/:id` route.

---
Once these are done, tapping the card will successfully parse the JSON and transition you into the technician's profile! Have a great time at university!