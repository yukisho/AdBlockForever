v0.5.8
- Added a separate, toggleable trade-advertisement filter with scored `WTS`, item-link, price, auction-house comparison, marketing, and contact signals.
- Added localized trade-sale and auction-house comparison phrases without treating non-English chat as spam by itself.
- Added Trade sensitivity, chat-scope controls, statistics, blocked-log filtering, import/export, reset support, and slash commands.
- Added native AddOn Compartment integration and an AddOns Settings page with quick controls and links to the full addon windows.
- Kept the minimap button available and user-toggleable for players who prefer direct access.
- Added scored portal and summoning-service advertisement detection under the Trade filter, with request and group-coordination safeguards.
- Added lockpicking-service detection, `looking for work` profession wording, and flexible-payment summon phrasing.
- Fixed developer-log capture of chat lines exposed as partial rendered fragments by preferring full message metadata and recent raw events.
- Expanded service detection for abbreviated `port/ports`, commercial `WTB` transport requests, flexible location spellings, and `pick lock`/`opening boxes` wording.

v0.5.4
- Improved detection for French recruitment phrasing and interested-player contact language.
- Improved handling of multi-team raid recruitment messages.
- Added detection for launch-focused recruitment, tagged community invitations, and Danish/Norwegian recruiting language.
- Added Cyrillic/Greek homoglyph normalization for spam detection and website-backed power-leveling service filtering.
- Expanded recruitment detection for relaxed raid teams, late-night guild campaigns, established-community pitches, and concise core-spot ads.
- Added detection for tagged future-raid recruitment using interest language and class-count rosters.

v0.5.2
- Added additional slash commands for convenience.
- Improved handling of guild recruitment ads.

v0.5.0
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
- Fixed sensitivity and category labels overflowing their controls in the Rules & Controls window.
- Expanded guild recruitment detection for long-form `LFM to join` and `join a guild` invitations that omit explicit recruiting language.
- Added supporting detection for newly formed guild campaigns and invitations welcoming all player types.
- Added structured detection for organized leveling/progression communities advertising role support, flexible scheduling, and whisper contact without explicitly saying `guild`.
- Expanded guild recruitment detection for persistent raid-roster campaigns, multi-team schedules, leadership recruitment, and guild-tagged `looking for more players` ads.
- Added detection for speed-roster/clone-split campaigns and French recruitment phrasing, roster building, and interested-player contact language.
- Recognize guild recruitment campaigns welcoming all experience or skill levels, including bracketed guild-name advertisements.

v0.4.0
- Added gold seller spam blocking
- Increased detection triggers for messages
