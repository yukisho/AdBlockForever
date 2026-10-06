# AdBlock Forever development workflow

`AdBlockForeverDev` is the development worktree. Make and test changes here.
`AdBlockForever` is the public worktree and receives only approved release files.

## In-game testing

Enable **AdBlock Forever Dev** and disable **AdBlock Forever** in the character
addon list. The development build uses its own `AdBlockForeverDevDB` saved
variables and `/abfdev` slash command, so experimental settings do not overwrite
the public addon's settings.

The game should never run both builds together. If the development build detects
the public build, its filtering remains inactive and it prints a warning. The
developer logger remains available so it can still capture messages filtered by
the public build.

## Developer message logger

The logger is enabled by default in the development build. Hover a visible line
in any chat window and click the temporary **+** button at the right edge of that
line. The capture is added to the persistent development database.

Open the log with the **Developer Log** settings button, Shift-left-click the
minimap icon, or run:

```text
/abfdev log
```

The settings and Developer Log windows are mutually exclusive so the two large
panels never overlap. Opening either one closes the other.

The log supports two exports:

- Messages only: one clean message per line for easy reporting.
- Live classifier diagnostics: timestamp, chat event, author, mode, current
  allow/block result, score, matched reasons, and message.

Use **Select All**, then press Ctrl+C to copy the output. WoW addons cannot write
directly to the operating-system clipboard.

Additional commands:

```text
/abfdev export
/abfdev capture on
/abfdev capture off
/abfdev hoverdebug
/abfdev clearlog
```

If the hover button is not visible, keep the cursor over a chat message and run
`/abfdev hoverdebug`. It reports how many visible chat frames, regions, text
lines, and currently hovered lines the game exposes to the addon.

The logger retains the newest 250 messages by default. It reads the final
rendered chat lines, which makes it compatible with Prat formatting while also
keeping a recent raw-event cache for cleaner exports and diagnostics.

## Validate a release

From PowerShell in this folder:

```powershell
.\Build-Release.ps1 -ValidateOnly
```

Validation checks the manifest, required TOC metadata, TOC file references, and
Lua syntax when `luac` is installed.

## Promote a public build

```powershell
.\Build-Release.ps1
```

The script copies only entries in `release-manifest.txt` into the sibling
`AdBlockForever` folder. It refuses to proceed if that public worktree has
uncommitted changes, unless `-AllowDirtyDestination` is deliberately supplied.

To also create a CurseForge-ready archive:

```powershell
.\Build-Release.ps1 -Package
```

The archive is written to `Releases/AdBlockForever-<version>.zip`. Developer
tools, tests, build scripts, worktree metadata, and other unlisted files are not
included.

## Branches

- `dev` is checked out in `AdBlockForeverDev`.
- `main` is checked out in `AdBlockForever`.
- Release promotion copies the approved files; review and commit those changes
  from the public worktree when the build is ready.
