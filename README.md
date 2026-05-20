<p align="center">
  <img src="assets/command-icon.png" width="128" alt="Icon" />
</p>

# Dynamic Window Resizing for Raycast

Resize the frontmost macOS window with a keyboard shortcut: press your hotkey, move the mouse, release the modifiers to stop. The window grows or shrinks from its lower-right corner — same as dragging the system resize edge there, but without having to move the cursor first.

## Installation

Requirements: macOS 12+, [Raycast](https://www.raycast.com/), Node 22.x (the repo pins `22.22.2` via `.tool-versions`), and the Swift toolchain (`xcode-select --install` if you don't have it).

```bash
git clone https://github.com/shubrich/raycast-dynamic-window-resizing.git
cd raycast-dynamic-window-resizing
npm install
npm run dev
```

`npm run dev` builds the Swift helper into `assets/` and runs `ray develop`, which registers the extension into your local Raycast. Quit `ray develop` once it's registered — the extension stays installed.

Then grant **Accessibility** access to Raycast.app in System Settings → Privacy & Security → Accessibility. (No Input Monitoring is required.)

## Usage

1. In Raycast, find **Resize Active Window** and assign a hotkey **that includes at least one modifier** (⌃ / ⌥ / ⌘ / ⇧). Modifier-less hotkeys can't be detected on release.
2. Focus the window you want to resize.
3. Press and hold the hotkey, then move the mouse to grow or shrink the window from its bottom-right corner.
4. Release any of the hotkey's modifiers — or press Escape — to stop.
