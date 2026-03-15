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
- No iOS support planned at this time
- min SDK version 26 (Android 8)
- target SDK version 35/36
- Target platforms : Android
- Database: Hive (local-only)

---

## Current Project State

- Flutter project scaffold created
- Git repository initialized
- Project structure will follow a feature-based architecture
- Core Logging: 3 tier emotion selection implemented
- Visual Reflection: Monthly calendar with "Emotion Pie Chart" markers and intensity-based opacity
- Staged Unlocking: Sequential reveal of emotion tiers based on usage to prevent overwhelm
- Settings: Ability to skip unlocking for advanced users/ testing
- Architecture: Feature-based architecture with local service-based data management
- Revision System: "Correction" vs. "Reflection" flow with a visual timeline of emotional growth
- Reminders added, using Alarm Channel on phone to override "Silent" mode on phone
- Custom colours added to settings 
- Custom Emotions added
- Dark Mode added
- Date Format settings added
- Journal read only screen added

---

## Planned Features (Roadmap)

### Phase 1 – Foundations Emotion check-ins [DONE]
#### Core emotion tracking
- Emotion entries with:
  - timestamp (date+time)
  - selected emotion(s)
- Predefined emotion options in three tiers
- unlimited manual entries per day
- Soft reminders (~3x daily), configurable (push notification or alarm)
- Monthly calendar View:
  - each day visualized as a segmented circle
  - Segments represent individual entries
  - Colours represent emotions
  - opacity shows intensity
  - orange circle shows trigger journal was used at least once
  - dot represents Journal Entry
#### Entry integrity and meaning over time [DONE]
- Entries represent emotional moments, not mutable records
- Past entries are never overwritten
- Any change creates a revision, not a replacement
- Each entry consists of:
  - an original snapshot
  - a list of revisions applied over time
- Revisions can be:
  - Corrections (fixing mistakes, mis-taps, typos)
  - Reflection (later reinterpretation of the same moment)
- Revisions:
  - Store only the changed fields (delta-based)
  - are timestamped
  - are listable and explorable by the user
  - allow users to observe how their understanding evolved
#### Editing UX philosophy [DONE]
- Editing an entry triggers a lightweight choice:
  - Correction
  - Reflection
- Implemented via a non-intrusive snackbar
- Reflection does not imply a new emotional moment
- New emotional moments should be recorded as new entries
- Lightweight choice between Correction or Reflection
#### Locking logic [DONE]
- Entries for past dates:
  - asks before Entry can be made
  - show date of when entry was made and which date the entry refers to
- Only entries on current date can be newly created without the snackbar
- This preserves:
  - authenticity of past states
  - freedom to gain insight later
  - protection against emotional "rewriting"
  - only edits possible via Reflection or Correction dialogue
  - delete via swipe
#### Unlocking logic (use-based, not time based) [DONE]
- granular Unlocking can be done via settings
- Tier 1 emotions available from start
- Unlock tier 2 emotions after tier 1 emotions used 7 times
- Unlock tier 3 emotions after tier 2 emotions used 7 times
- Unlock intensity after tier 3 emotions used 7 times
- optional settings:
  - enable all features immediately
  - or use staged unlocking (explained clearly during onboarding)
- After unlocking all tiers, per-entry selection allows:
  - only tier 1 emotion
  - tier 1, tier 2 and tier 3 emotion
  - tier 1 and tier 3 emotion
  - Tier 2 and tier 3 include a custom/ free-text option
### Phase 2 – Intensity and Visual Reflection [DONE]
- Intensity between 0-3
- stored per entry
- visualized as opacity in calendar view
- Intensity is optional and may remain 0
- Intensity usage counts toward unlock only when >0
#### Body awareness [DONE]
- Prompt "Where in the body do you feel that emotion"
- Interactive, zoomable body map (SVG-based, male, neutral, female)
- Normalized coordinate paths stored
- Emotion-to-body associations
- Optional per entry
- Thumbnail in History screen
- History Entry clickable, Read only mode
#### Unlocking logic: [DONE]
- Body map unlocks after Intensity used 7 times
- Intro screen explain body map usage
### Phase 3 – Trigger prompts [DONE]
- Optional Prompt "Do you want to note what influenced this?"
- short free-text input or keywords
- never mandatory
- Visual indicator on calendar when trigger exists (font of date number different colour?)
#### Unlocking logic: [DONE]
- Trigger prompts unlock after Body Map used 3 times
### Phase 4 – Free journal [DONE]
- Long-form text entries
- Date-based, not forced daily
- can reference emotions automatically
- new data model
- not behind unlocking anymore but toggled via settings
- reflection/correction like emotion entry
- new "add" model to just add to an entry without editing the early text
- optional journaling prompts (maybe added later)
### Phase 5 – Data Export 
- Export entries (full or partial) as PDF
- User-controlled scope and date ranges

---

## Privacy Philosophy

This app is designed to work **entirely offline**.
All data stays on the user’s device.

No accounts.  
No analytics.  
No external servers.
No hidden data flows.

---

## Status

This project is under active development.
The README will evolve as features are implemented.

---

## License

To be decided.


