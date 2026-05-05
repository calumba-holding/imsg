---
title: Install
description: "Install imsg with Homebrew, build it from source, or pin a specific release."
---

`imsg` ships as a signed, notarized universal macOS binary. It runs on macOS 14 (Sonoma) and newer, including macOS 26 (Tahoe).

## Homebrew

```bash
brew install steipete/tap/imsg
```

This is the recommended path. Homebrew downloads the universal binary for your architecture, installs it onto your `PATH`, and tracks updates with `brew upgrade`.

To uninstall:

```bash
brew uninstall imsg
brew untap steipete/tap   # optional
```

## Build from source

```bash
git clone https://github.com/steipete/imsg.git
cd imsg
make build
./bin/imsg --help
```

`make build` runs the universal release build through Swift Package Manager and patches `SQLite.swift` with the repo's required adjustments. The binary lands at `bin/imsg`.

For day-to-day development:

```bash
make imsg ARGS="chats --limit 5"
```

This is a clean debug rebuild that runs the resulting binary with the supplied arguments.

## Verify the install

```bash
imsg --version
imsg chats --limit 3
```

If `chats` returns `unable to open database file` or `authorization denied`, jump to [Permissions](permissions.md). The CLI is installed correctly; macOS just hasn't granted it Full Disk Access yet.

## Optional dependencies

- **`ffmpeg`** on your `PATH`. Required only for `--convert-attachments`; see [Attachments](attachments.md).
- **`jq`**. Not required, but every example here uses it to pretty-print JSON streams.

## What you don't need

- No Node, Python, or Ruby runtime.
- No background daemon, launch agent, or login item.
- No private API patches. Default reads use a read-only handle on `chat.db`; sends use Messages' published AppleScript surface. Only the [advanced IMCore features](advanced-imcore.md) need a helper dylib, and even those are off by default.
