# AdBlock Forever module map

## Runtime core

- `Core.lua` — addon identity, shared constants, profession vocabulary, and text utilities.
- `Core/Database.lua` — defaults, SavedVariables migrations, and database validation.
- `Core/Rules.lua` — player whitelist, phrase rules, sensitivity, scopes, resets, and diagnostics.
- `Core/Transfer.lua` — settings and rule import/export serialization.
- `Core/Classifier.lua` — guild, profession, gold, and custom-phrase classification.
- `Core/History.lua` — blocked-message history, statistics, deduplication, and whisper alerts.
- `Core/Commands.lua` — public and development slash-command routing.
- `Core/Chat.lua` — chat filters, change notifications, addon startup, and conflict detection.

## User interface

- `UI/MainWindow.lua` — primary settings window.
- `UI/Minimap.lua` — minimap button, tooltip, and rim positioning.
- `UI/RulesWindow.lua` — custom rules, sensitivity, scopes, alerts, resets, and transfer UI.
- `UI/BlockedLog.lua` — searchable blocked-message review and correction actions.

## Development-only code

- `DevTools/Bootstrap.lua` — marks the development build before shared code loads.
- `DevTools/MessageLogger.lua` — hover capture, diagnostics, labels, duplicate detection, and fixture export.
- `Tests/fixtures.lua` — permanent classifier regression corpus.
- `Tests/run.lua` — standalone Lua regression runner.

The load order in both TOC files is authoritative. Shared code should communicate
through the addon table (`ABF`) rather than file-local globals.
