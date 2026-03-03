# Emotion Tracker

A Flutter-based personal emotion tracking app with a strong focus on privacy, self-awareness, and visual reflection.

This project is currently in early development and serves both as a learning project and a foundation for a thoughtfully designed mental health–adjacent tool.

---

## Project Goals

- Track emotions over time in a simple, low-friction way
- Offer visual tools (such as body maps) to reflect where emotions are felt
- Preserve emotional snapshots and their later reinterpretations
- Keep all data **local-only** (no accounts, no cloud, no tracking)
- Build a calm, respectful UI that does not overwhelm the user

---

## Tech Stack

- **Flutter**
- Target platforms: Android, Windows, Linux, macOS
- Database: **Hive** (Local-only)

---

## Current Project State

- **Core Logging**: 3-tier emotion selection implemented.
- **Visual Reflection**: Monthly calendar with "Emotion Pie Chart" markers and intensity-based opacity.
- **Staged Unlocking**: Sequential reveal of emotion tiers based on usage to prevent overwhelm.
- **Settings**: Ability to skip unlocking for advanced users/testing.
- **Architecture**: Feature-based architecture with local service-based data management.

---

## Planned Features (Roadmap)

### Phase 1 – Foundations Emotion check-ins
#### Core emotion tracking [DONE]
- Emotion entries with timestamp, tiers, and intensity.
- Monthly calendar View with segmented color circles.
#### Entry integrity and meaning over time [UP NEXT]
- Revisions (Corrections vs. Reflections) instead of simple overwriting.
- Delta-based storage for changes.
#### Editing UX philosophy
- Lightweight choice between Correction, Reflection, or New Entry.
#### Locking logic
- Historical entries protected from "rewriting" while allowing for later insight.
#### Unlocking logic [DONE]
- Sequential tier unlocking based on logs.
- Global "Skip" setting implemented.

... (rest of roadmap) ...
