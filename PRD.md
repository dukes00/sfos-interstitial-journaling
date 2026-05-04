# ilog — Product Requirements Document

**Version:** 0.2 — Phase 1 Specified
**Date:** 2026-05-04
**Author:** Solo developer (sole user)
**Platform:** SailfishOS (QML + C++/Silica)

---

## 1. Purpose

A personal interstitial journaling tool designed to manage ADHD through frictionless capture and analytically-driven review. The app prioritises **speed from intention to typing** above all else, with review and analysis handled as a separate pipeline via a home server and local LLM.

This is **symbiosisware** — software where the developer and sole user are the same person. Discoverability, onboarding, multi-user accessibility, and app-store compliance are non-goals.

---

## 2. Core Problem

Interstitial journaling requires capturing transition moments in real-time. Any friction in the path from "I want to note something" to "I am typing" causes the action to be abandoned. Existing tools — iOS journaling apps, Notes, physical journals — all introduce friction chains (finding the app, navigating to a section, opening a notebook) that are long enough to lose ADHD users at the executive function bottleneck.

**Target: under one second from intention to active text cursor.**

---

## 3. Users

One. The developer. No multi-user support, no accessibility auditing, no localization, no responsive design for other screen sizes, no onboarding flow, no error handling for misuse patterns.

---

## 4. Design Principles

| Principle | Rationale |
|---|---|
| **Open → cursor → type** | The app opens directly to a focused text input with keyboard visible. No home screen, no list, no "new entry" button. |
| **No streaks, no shame, no gamification** | Streaks create anxiety spirals for ADHD users. Returning after a month of silence must feel identical to opening the app for the first time. |
| **No decisions at capture time** | No folder, tag, category, or classification required when writing. Timestamp is the only automatic metadata. |
| **Single append-only stream** | One chronological log. All organisation, tagging, and pattern analysis happens at review time, separately. |
| **Offline-first, no network calls** | The app works in airplane mode. No analytics, telemetry, or third-party dependencies. Architecturally incapable of phoning home. |
| **Plain-text storage** | Trivially parseable by pandas, grep, cat, or any future tool. The data outlives the app. |
| **Present-tense only** | The prompt (if any) is "what are you doing right now?" — no retrospective or prospective framing. |

---

## 5. Architecture Overview

```
┌──────────────────────────────────────────────┐
│            SailfishOS Device                  │
│                                               │
│  ┌─────────┐    ┌──────────────────────────┐  │
│  │  ilog   │───▶│ journal.txt (XDG dir)    │  │
│  │ (QML+   │    │ append-only, plain text  │  │
│  │  Silica) │    └──────────┬───────────────┘  │
│  └─────────┘               │                  │
│           ┌────────────────┘                  │
│           ▼                                   │
│  rsync/scp (hourly) ──────────────────────┐   │
│           ▲                               │   │
│           │                               │   │
│  D-Bus notification ◄──── ssh from server │   │
│  (Nemo.Notifications)                     │   │
└──────────────────────────────────────────────┘
                        │
                        ▼
┌──────────────────────────────────────────────┐
│              Home Server                      │
│                                               │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐  │
│  │ SQL DB   │   │ Weekly   │   │ Delivery │  │
│  │ (mirror) │──▶│ LLM      │──▶│ - push   │  │
│  │          │   │ summary  │   │ - email  │  │
│  └──────────┘   └──────────┘   └──────────┘  │
└──────────────────────────────────────────────┘
```

**Capture** lives on the phone. **Intelligence** lives on the home server. The data format is the contract between them.

---

## 6. Data Format

### 6.1 Primary Storage — `journal.txt`

Append-only plain text. One entry per line. ISO 8601 timestamps.

```
2026-05-03T11:42:00 finished the standup, feeling okay about the sprint scope
2026-05-03T12:05:00 energy dropping, should eat something
2026-05-03T14:30:00 😴 back from lunch, kinda sluggish
```

Markers are emoji-based (e.g. ⚡ for energy, 😴 for tired, 😡 for angry). These are plain Unicode characters in the text — no special syntax, no app-enforced format. Parsed by downstream scripts at review time.

### 6.2 Server-Side Mirror — SQL DB

Hourly rsync of `journal.txt` to home server. A parse script imports new lines into a SQL table:

```
| timestamp (PK) | text | energy | location | project |
|----------------|------|--------|----------|---------|
| ISO 8601       | TEXT | INT?   | TEXT?    | TEXT?   |
```

Structured fields are extracted from emoji markers at parse time, not at capture time.

---

## 7. Features

### 7.1 Phase 1 — The Writing Instrument (SPECIFIED)

#### Layout

- **Single-page app**: writing and history are the same view
- **Chat-style layout**: input field pinned at bottom, entries scroll above
- **Portrait only**: locked orientation
- **No navigation**: no page stack, no separate history screen

#### Input

- **Single-line entries**: one line per entry, no multi-line support
- **Auto-focus on launch**: text input has focus immediately, keyboard appears
- **Dismissable keyboard**: swipe down to dismiss, tap input to bring back
- **Placeholder prompt**: dimmed text, randomly selected from a pool of 5-6 variations (e.g. "what are you doing right now?", "what's happening?", "what just happened?")
- **Tap-to-save**: tap a save button/area to save the entry

#### Save Behavior

- **Clear + flash**: input clears immediately, new entry appears in the list with a brief background highlight (1-2 second fade)
- **Timestamp at save time**: ISO 8601 timestamp generated when the user taps save
- **Keyboard stays up**: ready for the next entry immediately

#### Entry Display

- **Monospace font**: PragmataPro preferred, system monospace as fallback
- **Time-only per entry**: `14:30 back from lunch`
- **Day dividers**: `──── YYYY-MM-DD ────` between entries from different days
- **Pure plain text**: no rich text, no special rendering, emojis display as Unicode
- **Last 100 entries loaded**: lazy-load more on scroll

#### Cover

- **Cover action**: single `CoverAction` that opens the app directly into writing mode
- **Cover content**: minimal (app name/icon), content TBD after real-world use

#### Storage

- **Location**: `QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)`
- **Path**: `/home/nemo/.local/share/org.duke/ilog/journal.txt`
- **Format**: ISO 8601 timestamp + space + text, one entry per line
- **Append-only**: entries are never modified or deleted

#### Localization

- **None**: English only, translation files removed

### 7.2 Phase 2 — Access & Export

| Feature | Description |
|---|---|
| Text export | "Dump everything to a text file" — full journal to a single file, trivially copyable via `scp`. |
| Search | Full-text search over journal entries. |
| Optional quick-tap markers | Tappable emoji icons (⚡😴😡) that auto-prepend a mood indicator to the current entry. Optional, not required. |
| Cover content | Show last entry or summary data point on the cover. |
| Hardware button mapping | Investigate mapping a long-press volume button or power double-tap to launch/focus the app. |

### 7.3 Phase 3 — Pattern Discovery (Heatmap & Review)

| Feature | Description |
|---|---|
| Activity heatmap — day-of-month | Shows macro rhythm: which weeks/months are more active. GitHub-style grid, current year. |
| Activity heatmap — hour-of-day | Shows daily rhythm: active hours and attention windows. Current week. |
| Activity heatmap — quarter-hour | Shows micro rhythm: session length, burst patterns. Last 3 days. |
| Gap duration encoding | Heatmap cells encode "how long since last entry" not just "how many entries." |
| Entry length overlay | Cells can reflect total word count per time bucket, indicating cognitive engagement. |
| Mood/energy overlay | If energy markers are captured, heatmap shows average energy per cell. |
| Anomaly annotation | Ability to annotate unusual patterns (e.g. 3am burst, unexpected silence) at review time. |
| Rescue/sink model | Swipe to rescue an insight to the top, swipe to archive. Uses present-moment attention as the filter. |

### 7.4 Phase 4 — LLM Integration (Server-Side)

| Feature | Description |
|---|---|
| Weekly summary cron | Weekly batch job on home server. Feeds the week's entries + structured data to a local LLM. |
| Pattern recognition | Identify energy trends, topic avoidance, emotional arcs, recurring themes. |
| Vagueness detection | Flag entries like "do laundry" that are likely multi-step, suggest breakdown at review time. |
| Entry linking | Semantic similarity across entries ("this is related to what you wrote last Tuesday about X"). |
| Push notification delivery | `dbus-send` over SSH to fire a SailfishOS notification with summary teaser. Tap-through to full analysis. |
| Email delivery | Parallel delivery of full weekly summary via email as fallback. |

---

## 8. Out of Scope (Explicit Non-Goals)

- Rich text formatting
- Image/voice attachments (may revisit far future)
- Multiple journals or streams
- Cloud sync (only self-hosted, Syncthing-compatible file format if ever)
- Sharing or social features
- Reminders or notifications *to write* (creates guilt)
- Streak tracking or writing statistics surfaced as performance
- Onboarding flow
- Customisable themes (pick one, ship it)
- Public distribution (dump as-is if ever open-sourced)
- Localization (English only)

---

## 9. Technical Stack

| Layer | Technology |
|---|---|
| UI | QML + Sailfish Silica components |
| Logic/Storage | C++ (performance-sensitive), QML (UI bindings) |
| On-device storage | Plain text file + optional SQLite index |
| Backup transport | `rsync` over SSH (hourly cron) |
| Server-side storage | SQL DB (append-only mirror) |
| Analysis | Python (pandas, matplotlib/seaborn/plotly for heatmaps) |
| LLM | Local model on home server (weekly cron job) |
| Notification delivery | D-Bus via `dbus-send` over SSH, or `Nemo.Notifications` QML type |

### 9.1 SailfishOS Technical Notes

From documentation research:

- **Silica components**: `ApplicationWindow`, `Page`, `SilicaFlickable`, `TextField`, `Label`, `CoverBackground`, `CoverActionList`, `CoverAction`
- **App architecture**: `SailfishApp::main()` in C++ entry point loads `qml/ilog.qml` which defines `ApplicationWindow` with `initialPage` and `cover`
- **XDG paths**: `QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)` resolves to `/home/nemo/.local/share/<OrganizationName>/<ApplicationName>/`
- **Sailjail**: app runs in sandbox, no special permissions needed for own data directory
- **Cover actions**: defined in `CoverBackground` > `CoverActionList` > `CoverAction` (max 2 actions)
- **Keyboard focus**: `TextField` within `Page` auto-scrolls to stay visible when keyboard appears; use `focus: true` and `Component.onCompleted: forceActiveFocus()` for auto-focus
- **Nemo.Notifications**: QML import `Nemo.Notifications 1.0` available for Phase 4 push notifications
- **Allowed QML imports**: `Sailfish.Silica 1.0`, `Nemo.Notifications 1.0`, `Nemo.DBus 2.0`, `QtQuick 2.x`, `QtQml 2.x`
- **Coding conventions**: follow Qt/QML style, use `Theme` properties for colors/sizes, no semicolons in QML JS

### Reference Projects

- **[jolla-notes](https://github.com/sailfishos/jolla-notes)** — QML/Silica patterns for text input and storage
- **[Captain's Log](https://github.com/ichthyosaurus/harbour-captains-log)** — Diary app architecture, SQLite model, export patterns (GPL-3.0)
- **[Gravity Notes](https://www.gravitynotes.app/)** — THE append/review note taking app

---

## 10. Project Configuration

| Setting | Value |
|---|---|
| App name | `ilog` |
| OrganizationName | `org.duke` |
| ApplicationName | `ilog` |
| Sailjail permissions | None |
| Allowed orientations | Portrait only |
| Translations | None (English only) |
| Build target | Emulator first, device when available |

---

## 11. Risks & Mitigations

| Risk | Mitigation |
|---|---|
| **SailfishOS keyboard latency** | Pre-focus text input, render it first, load everything else lazily. Test aggressively on real hardware. |
| **Aggressive background killing** | Investigate keeping the process alive. At minimum, ensure cold-start-to-cursor is architecturally instantaneous. |
| **Hyperfocus on building vs. using** | Ship Phase 1 as fast as possible. Use it for two weeks before building anything else. Follow motivation but constrain scope to "does this help me write?" |
| **Phone unreachable for server push** | Phone-initiated pull model as fallback (phone cron checks server for new summaries). |
| **Scope creep (LLM, heatmaps, etc. before capture works)** | Phase 1 is the writing instrument only. Everything else requires accumulated data from actual use. |

---

## 12. Success Criteria

The app is successful if:

1. **Time from unlock to first keystroke is under 2 seconds** (including app launch, keyboard appearance).
2. **Entries per day increases** compared to previous journaling attempts.
3. **After a multi-week gap, the user opens the app and writes immediately** — no friction from guilt or disorientation.
4. **After one month of use**, the heatmap and/or LLM summary surfaces at least one genuinely surprising pattern the user wasn't consciously aware of.

---

## 13. Immediate Next Steps

1. **Build Phase 1.** Ship the writing instrument this weekend.
2. **Use it for two weeks.** Accumulate real data. Note every moment of friction or desire for a missing feature.
3. **Build the heatmap Python script.** Start with hour-of-day, current week. Run against your own data.
4. **Set up the hourly rsync to home server.** Begin mirroring data to SQL.
5. **Decide Phase 2 priorities** based on what you actually needed during those two weeks, not what seemed cool in planning.
