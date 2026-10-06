# AdBlock Forever

**AdBlock Forever** keeps chat cleaner by automatically hiding guild recruitment messages, profession advertisements, and gold seller spam in **WoW Forever**. It can also block unsolicited guild-recruitment whispers.

Unlike a traditional ignore addon, AdBlock Forever filters only the detected advertisement. Other messages from the same player remain visible, and the addon never modifies your Blizzard ignore list.

## Features

- Automatically detects guild recruitment advertisements.
- Automatically detects profession and crafting advertisements.
- Automatically detects gold seller spam in public chat and incoming whispers.
- Optionally blocks unsolicited guild-recruitment whispers.
- Filters public channels, Say, and Yell.
- Does not filter Guild, Officer, Party, Raid, or Instance chat.
- Ordinary whispers and profession advertisements sent by whisper remain visible unless they match the gold-spam filter.
- Separate toggles for public guild recruitment, recruitment whispers, profession advertisements, and gold seller spam.
- Conservative, Balanced, and Aggressive sensitivity for each automatic filter.
- Independent Channel, Say, Yell, and Whisper scope for every filter category.
- Individual controls for each profession.
- Player whitelist for people whose messages should never be filtered, regardless of content.
- Phrase allowlist for messages containing specific text.
- Custom blocked phrases for server-specific spam.
- Movable minimap button that follows the minimap rim.
- Movable settings window constrained to the game screen.
- Persistent account-wide settings.
- Statistics showing how many messages have been blocked.
- Persistent blocked-message history with the sender, category, score, and matched detection signals.
- Searchable blocked log with category filters and false-positive correction actions.
- Settings and rule import/export, targeted reset controls, and optional blocked-whisper alerts.
- Best-effort multilingual detection.

## Profession Controls

Each profession can be enabled or disabled individually.

For example, you can allow **Enchanting** advertisements while continuing to block advertisements for every other profession.

Supported categories include:

- Alchemy
- Blacksmithing
- Cooking
- Enchanting
- Engineering
- Inscription
- Jewelcrafting
- Leatherworking
- Tailoring
- Other professions

## Smart Message Detection

AdBlock Forever uses score-based detection instead of hiding messages based on a single word.

The addon combines signals such as:

- Guild recruitment language
- Guild tags and requests for new members
- Raid schedules and progression details
- Discord and contact information
- Profession and enchantment links
- Crafting orders
- Materials, recipes, fees, and tips
- Contact phrases such as “PST,” “whisper,” or “message me”
- Gold-sale language, real-money pricing, delivery claims, and obfuscated website/contact details

A casual mention of a guild, profession, or gold is not normally enough to hide a message. Gold detection requires a combination of commercial signals, while question-style guild invitations are treated more aggressively in whispers because mass recruiters often phrase advertisements as personal questions.

Detection recognizes common advertising phrases in English, German, French, Spanish, Portuguese, Italian, Polish, Russian, Simplified and Traditional Chinese, and Korean. Detection outside English is best effort and will continue to improve.

## Whisper Filtering

Guild-recruitment whisper filtering is independent from public-chat filtering. Gold seller spam has its own toggle and is detected in both public chat and incoming whispers.

You can:

- Block recruitment in both public chat and whispers.
- Block only recruitment whispers.
- Block only public recruitment messages.
- Disable both while continuing to filter profession advertisements.

The player whitelist and phrase allowlist always take priority.

## Rules & Controls

Open **Rules & Controls** from the main settings window or use `/abf advanced`.

This window provides:

- Custom plain-text blocked phrases
- Per-filter sensitivity
- Per-category controls for public channels, Say, Yell, and Whispers
- Optional notice, sound, or combined alerts when a whisper is hidden
- Settings import/export
- Separate reset buttons for filters, lists, and lifetime statistics

Settings exports include filter settings, profession choices, chat scopes, the
player whitelist, and custom allow/block phrases. Blocked-message history and
statistics are deliberately excluded.

## Minimap Button

- **Left-click:** Open the settings window.
- **Right-click:** Enable or disable all filtering.
- **Drag:** Move the button around the minimap.

The settings window can also be opened with:

    /abf

## Slash Commands

    /abf
    /abf on|off
    /abf guild on|off
    /abf whispers on|off
    /abf professions on|off
    /abf gold on|off
    /abf profession NAME on|off
    /abf whitelist NAME
    /abf unwhitelist NAME
    /abf allowphrase TEXT
    /abf unallowphrase TEXT
    /abf blockphrase TEXT
    /abf unblockphrase TEXT
    /abf sensitivity CATEGORY conservative|balanced|aggressive
    /abf scope CATEGORY channel|say|yell|whisper on|off
    /abf advanced
    /abf minimap show|hide
    /abf stats
    /abf last
    /abf blockedlog
    /abf clearblockedlog
    /abf test MESSAGE

The **/abf test** command checks how a message would be classified without hiding it or increasing your statistics. It also reports when a message would be blocked only in a whisper.

## Blocked Message Log

Open **Blocked Log** from the settings window or use `/abf blockedlog` to review
messages hidden by the addon. Search the history, cycle through categories, and
navigate individual entries. Each detailed entry includes the addon version,
sender, chat event, category, score, and scored detection signals.

The selected entry can be copied, marked as a false positive, given an allowed
phrase, or have its sender added to the player whitelist. `/abf last` prints the
most recently blocked message, which also appears in the minimap tooltip.

The newest 500 blocked messages are retained across sessions. The window can
also show messages without diagnostic details for convenient copying. Use
`/abf clearblockedlog` or the window's **Clear Log** button to remove the history.

## Privacy

AdBlock Forever works entirely on your client.

Blocked-message history is stored locally in the addon's SavedVariables file and
is never transmitted. Clearing the log removes that stored message history while
leaving the aggregate blocked-message statistics unchanged.

It does **not**:

- Add players to Blizzard’s ignore list
- Report players
- Send chat messages
- Send addon communications
- Permanently silence detected advertisers

Only messages matching the enabled filters are hidden.

## Installation

1. Download and extract the addon.
2. Place the **AdBlockForever** folder in your WoW Forever **Interface/AddOns** directory.
3. Restart the client or reload the UI.
4. Type **/abf** or left-click the minimap button to configure the addon.

## Feedback

Automatic advertisement detection will never be perfect for every server, language, or writing style. If you encounter a false positive, add the player to the whitelist or add a distinctive part of the message to the phrase allowlist.

Examples of missed advertisements are especially helpful because they can be used to improve future detection without relying on overly broad keyword blocking.
