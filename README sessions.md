# Karigar Real-Time Events — 4-Session Execution Plan

## Why 4 sessions

The original single-prompt version was ~9000 tokens of specification. Feeding it all at once to Claude Code is possible but wasteful — by the time the agent is generating session 4 files, it's still carrying session 1's exhaustive domain specs in context, which you've already paid for across every intermediate tool call. Splitting into 4 sessions means each session carries only the spec it needs, and the previous sessions' context comes from **reading the actual generated files** — which is both cheaper and more accurate than re-reading a spec.

## How to run each session

Open Claude Code in your monorepo root. Start a fresh session for each one — do NOT carry conversation history between sessions. The generated files are the handoff.

### Session 1 — Domain Layer
- File: `session_1_domain.md`
- Output: 6 files in `lib/core/domain/`
- No build_runner needed
- End with `dart analyze` passing

### Session 2 — Data Layer
- File: `session_2_data.md`
- Output: 5 files in `lib/core/data/` + `lib/core/network/http_failure.dart` if missing
- Run `dart run build_runner build --delete-conflicting-outputs`
- End with `dart analyze` passing

### Session 3 — Presentation Layer (heaviest)
- File: `session_3_presentation.md`
- Output: 10 files across `lib/core/presentation/`
- Run `dart run build_runner build --delete-conflicting-outputs`
- End with `dart analyze` passing
- Also register `firebaseMessagingBackgroundHandler` in `main.dart`

### Session 4 — Orchestrator, Docs, Test Plan
- File: `session_4_orchestrator_docs_tests.md`
- Output: Orchestrator widget + `REALTIME_EVENTS_FEATURE.md` + test suite proposal
- Tests are NOT written this session — you approve the plan and write them in a follow-up

## Before each session

Claude Code auto-reads `CLAUDE.md` from the repo root — you don't paste it. Each session prompt already tells the agent to read the previous session's generated files before starting. That's the handoff mechanism.

## The scratchpad rule

Every session starts with the agent outputting a `<scratchpad>` plan. Per your `CLAUDE.md`: never approve code generation without first reviewing the plan. If the plan misses something or misinterprets a spec, correct it before the agent writes a single line.

## Token footprint (approximate)

| Session | Spec tokens | Notes |
|---------|-------------|-------|
| 1 | ~1800 | Lightest — pure enums and classes |
| 2 | ~2800 | Medium — DataSources + Repository |
| 3 | ~4200 | Heaviest — all notifiers + router + FCM |
| 4 | ~2500 | Orchestrator + doc + test plan |

Compared to a single ~9000-token prompt executed across 4 implicit stages, this saves roughly 40-60% of input tokens depending on how much of the previous file content the agent needs to re-read.
