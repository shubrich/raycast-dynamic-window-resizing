# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A Raycast extension that triggers an interactive resize of the frontmost macOS window from a keyboard shortcut. While the Raycast hotkey's modifiers are held, mouse movement grows/shrinks the active window from its lower-right corner — replicating the system's bottom-right-edge drag without the user having to first move the cursor there. Releasing any of those modifiers (or pressing Escape) stops the resize.

## Architecture

Two pieces talk through a child-process boundary:

- **`src/resize-window.ts`** — Raycast `no-view` command. Spawns the helper, waits for it to exit, surfaces specific errors as HUD messages by sniffing `stderr` for tagged strings (`accessibility-not-granted`, `no-window`, `no-size`).
- **`swift-helper/Sources/WindowResizeHelper/main.swift`** — Standalone Swift binary. Does all the work that Node can't: reads the focused window via `AXUIElementCopyAttributeValue` / `kAXFocusedWindowAttribute`, snapshots its size and the current cursor position, then polls at 60 Hz, writing back `kAXSizeAttribute = initialSize + cursorDelta` on each tick. The binary is built into `assets/window-resize-helper` and resolved at runtime via `environment.assetsPath`.

### Why the design looks like this

- **Raycast hotkeys fire on press, not on hold.** There's no native "while held" API for a command. The helper polls `CGEventSource.flagsState(.combinedSessionState)`, snapshots which modifiers were held at launch, and exits as soon as any of those modifiers is released. This means **the user's Raycast hotkey must include at least one modifier** (⌃/⌥/⌘/⇧); a bare key like F19 has nothing to "release," so only the Escape fallback would cancel.
- **Anchor is implicit.** AX's `kAXSizeAttribute` resizes from the window's origin (top-left), so we only need to write a new size — never touch `kAXPositionAttribute`. The lower-right corner moves with the size; the top-left stays put.
- **Coordinate system:** `CGEvent(source: nil)?.location` returns Quartz coordinates (top-left origin, y grows downward), which means `cursor.y - initial.y` is positive when the cursor moves down — matching the natural "drag down = taller" expectation. Don't switch to `NSEvent.mouseLocation` without flipping the sign.
- **Polling, not event taps.** Polling needs only Accessibility permission; an event tap would additionally need Input Monitoring. Keep it polling unless we hit a concrete need.

## Required permissions

Raycast.app itself must be granted **Accessibility** in System Settings → Privacy & Security. The helper exits with `error:accessibility-not-granted` on stderr and the TS side translates that to a HUD. No Input Monitoring is needed.

## Commands

```bash
npm install                # one-time
npm run build:helper       # rebuild the Swift binary into assets/
npm run dev                # builds helper, then `ray develop` (live-reload into Raycast)
npm run build              # production build (helper + ray build)
npm run lint               # ray lint
npm run fix-lint           # ray lint --fix
```

`npm run dev` chains `build:helper` ahead of `ray develop` so the binary in `assets/` is always current. The helper binary is gitignored — anyone cloning the repo must run `npm run build:helper` (or `npm run dev`) before the command will work.

## Before first run

Raycast requires `assets/command-icon.png` to exist for `ray build` / `ray develop` to succeed. Drop a 512×512 PNG there before the first `npm run dev`.
