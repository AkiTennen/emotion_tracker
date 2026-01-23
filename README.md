# Emotion Tracker

A Flutter-based personal emotion tracking app with a strong focus on privacy, self-awareness, and visual reflection.

This project is currently in early development and serves both as a learning project and a foundation for a thoughtfully designed mental health–adjacent tool.

---

## Project Goals

- Track emotions over time in a simple, low-friction way
- Offer visual tools (such as body maps) to reflect where emotions are felt
- Keep all data **local-only** (no accounts, no cloud, no tracking)
- Build a calm, respectful UI that does not overwhelm the user

---

## Tech Stack

- **Flutter**
- Target platforms:
    - Android
    - Desktop (Windows, Linux, macOS)
- No iOS support planned at this time
- min SDK version 26 (Android 8)
- target SDK version 34/35
- do need 36?

---

## Current Project State

- Flutter project scaffold created
- Git repository initialized
- No UI or feature logic implemented yet
- Project structure will follow a feature-based architecture

---

## Planned Features (Roadmap)

### Phase 1 – Foundations Emotion check-ins
- Emotion model (date, intensity, tags)
- Local persistence (no external services)
- Basic app navigation structure
- prompt ~3x daily (soft reminder), option between push or alarm function
- predefined emotion options (3 tiers, unlocking logic)
- unlimited manual entries per day
- monthly calendar view with colour/ emotion indicators
- Unlocking logic:
  - when used tier 1 emotions 7 times unlock tier 2
  - when used tier 2 emotions 7 times unlock tier 3
  - when used tier 3 emotions 7 times unlock Intensity
- Option to have all features from start or to unlock them through the unlocking logic --> explain in onboarding!
- after unlocking all 3 tiers the following entry options are possible:
  - only tier 1 emotion
  - tier 1, tier 2 and tier 3 emotion
  - tier 1 and tier 3 emotion
- for tier 2 and tier 3 a "custom" option should be given
- lock past and future entries, only entries on the current date can be made
- only option is to view or delete an entry from a past date

### Phase 2 – Intensity and Visual Reflection
- Intensity between 1-3
- stored per entry
- visualized as saturation, opacity or bar height in calendar view
- "Where in the body do you feel that emotion"
- Body map selection and interaction SVG with normalizedPosition for storage)
- Emotion-to-body association
- not mandatory but possible for every entry
- Unlocking logic:
  - when Intensity used 7 times unlock Body map --> screens to explain body map feature
- Intensity can always stay 0 if wanted --> doesn't count as used then

### Phase 3 – Trigger prompts
- prompt "Do you want to note what influenced this?"
- short text, keywords or selectable tags
- never mandatory
- Unlocking logic:
  - When Bodymap was used 3 times

### Phase 4 – Free journal
- Full text entries
- Date-based, not forced daily
- can reference emotions automatically
- option to get prompts for journaling maybe?
- Unlocking logic:
  - when Trigger was used 3 times

### Phase 5 – Data Export 
- Export whole entries, parts of entries as PDF

---

## Privacy Philosophy

This app is designed to work **entirely offline**.
All data stays on the user’s device.

No accounts.  
No analytics.  
No external servers.

---

## Status

This project is under active development.
The README will evolve as features are implemented.

---

## License

To be decided.
