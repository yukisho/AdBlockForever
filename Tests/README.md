# Regression tests

Run `lua Tests/run.lua` from the development worktree when a Lua 5.1-compatible
runtime is available. `fixtures.lua` is the permanent corpus of advertisements
that must be blocked and legitimate messages that must remain visible.

The development logger's **Export Fixtures** action produces entries in the same
format after captured messages have been labeled.
