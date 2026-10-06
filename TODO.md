# AdBlock Forever Roadmap

## v0.5.0

- [x] Formalize the player whitelist so listed players always bypass every filter.
- [x] Add custom blocked phrases with plain-text matching and individual removal.
- [x] Add Conservative, Balanced, and Aggressive sensitivity per filter category.
- [x] Add per-category controls for Channel, Say, Yell, and Whisper messages.
- [x] Add blocked-log search, category filtering, and selected-entry navigation.
- [x] Add blocked-log actions to copy a message, whitelist its sender, allow a phrase, and mark a false positive.
- [x] Add settings and rule import/export.
- [x] Add section-specific reset controls.
- [x] Add optional notifications and sounds for blocked whispers.
- [x] Add `/abf last` and show the last blocked message in the minimap tooltip.
- [x] Include addon version and detection diagnostics in log exports.
- [x] Add explicit, versioned SavedVariables migrations.
- [x] Add a permanent regression corpus covering advertisements, legitimate messages, toggles, channels, and sensitivity.
- [x] Add developer labels for guild, profession, gold, custom spam, and legitimate captures.
- [x] Add developer export for regression fixtures.
- [x] Show normalized/de-obfuscated text, signal contributions, and sensitivity comparisons in developer diagnostics.
- [x] Detect and identify near-duplicate captured spam messages.
- [x] Update documentation, metadata, and release packaging for v0.5.0.
- [x] Split the monolithic core and interface files into responsibility-based modules.

## Deliberately excluded

- Automatic player reporting.
- Automatic changes to Blizzard's Ignore list.

Both actions have consequences beyond hiding an individual matched message and
are outside the addon's message-only filtering philosophy.
