v0.4.0
- Added gold seller spam blocking
<<<<<<< HEAD
- Increased detection triggers for messages

## 0.5.0 - In development

- Formalized the existing allowed-player system as a global player whitelist that bypasses every filter.
- Added custom plain-text blocked phrases.
- Added Conservative, Balanced, and Aggressive sensitivity settings for guild, profession, and gold filters.
- Added per-category controls for public channels, Say, Yell, and Whispers.
- Added optional notice, sound, or combined alerts for blocked whispers.
- Added a dedicated Rules & Controls window.
- Added settings and custom-rule import/export.
- Added separate reset controls for filters, lists, and lifetime statistics.
- Added blocked-log search, category filtering, and selected-entry navigation.
- Added blocked-log actions to copy a message, whitelist its sender, allow a phrase, and mark a false positive.
- Added the addon version and scored signal contributions to detailed log exports.
- Added `/abf last` and last-blocked details to the minimap tooltip.
- Added explicit SavedVariables migrations through schema version 5.
- Added a permanent regression corpus covering advertisements, legitimate messages, priority rules, chat scopes, and settings round trips.
- Added developer labels and regression-fixture exports.
- Added normalized/de-obfuscated diagnostics and sensitivity comparisons to the developer log.
- Added near-duplicate detection for captured developer messages.
- Split the addon into focused Core and UI modules to make filter, database, command, and interface changes easier to locate and maintain.
=======
- Increased detection triggers for messages
>>>>>>> e9be00b6c69cc1d8b055604bae2d3fa738f2f4b2
