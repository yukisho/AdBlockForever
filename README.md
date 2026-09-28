# AdBlock Forever

**AdBlock Forever** keeps public chat cleaner by automatically hiding guild recruitment messages and profession advertisements in **WoW Forever**. It can also block unsolicited guild-recruitment whispers.

Unlike a traditional ignore addon, AdBlock Forever filters only the detected advertisement. Other messages from the same player remain visible, and the addon never modifies your Blizzard ignore list.

## Features

- Automatically detects guild recruitment advertisements.
- Automatically detects profession and crafting advertisements.
- Optionally blocks unsolicited guild-recruitment whispers.
- Filters public channels, Say, and Yell.
- Does not filter Guild, Officer, Party, Raid, or Instance chat.
- Ordinary whispers and profession advertisements sent by whisper remain visible.
- Separate toggles for public guild recruitment, recruitment whispers, and profession advertisements.
- Individual controls for each profession.
- Player allowlist for people whose messages should never be filtered.
- Phrase allowlist for messages containing specific text.
- Movable minimap button that follows the minimap rim.
- Movable settings window constrained to the game screen.
- Persistent account-wide settings.
- Statistics showing how many messages have been blocked.
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

A casual mention of a guild or profession is not normally enough to hide a message. Question-style guild invitations are treated more aggressively in whispers because mass recruiters often phrase advertisements as personal questions.

Detection recognizes common advertising phrases in English, German, French, Spanish, Portuguese, Italian, Polish, Russian, Simplified and Traditional Chinese, and Korean. Detection outside English is best effort and will continue to improve.

## Whisper Filtering

Guild-recruitment whisper filtering is independent from public-chat filtering.

You can:

- Block recruitment in both public chat and whispers.
- Block only recruitment whispers.
- Block only public recruitment messages.
- Disable both while continuing to filter profession advertisements.

Player and phrase allowlists always take priority.

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
    /abf profession NAME on|off
    /abf allowplayer NAME
    /abf unallowplayer NAME
    /abf allowphrase TEXT
    /abf unallowphrase TEXT
    /abf minimap show|hide
    /abf stats
    /abf test MESSAGE

The **/abf test** command checks how a message would be classified without hiding it or increasing your statistics. It also reports when a message would be blocked only in a whisper.

## Privacy

AdBlock Forever works entirely on your client.

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

Automatic advertisement detection will never be perfect for every server, language, or writing style. If you encounter a false positive, add the player or a distinctive part of the message to an allowlist.

Examples of missed advertisements are especially helpful because they can be used to improve future detection without relying on overly broad keyword blocking.
