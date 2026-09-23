# Open paths
⚠️ Vibecoded ⚠️

Pick a directory open in any tab of another running Yazi instance, then
navigate there in the current tab. Inspired by the workflow of
[Explorer Dialog Path Selector](https://github.com/ThioJoe/ThioJoe-AHK-Scripts).
This is an independent implementation, with no AutoHotkey dependency.

This plugin pairs well with these projects:
- [xdg-desktop-portal-termfilechooser](https://github.com/hunkyburrito/xdg-desktop-portal-termfilechooser)
- [org.freedesktop.FileManager1.common](https://github.com/boydaihungst/org.freedesktop.FileManager1.common)

## Requirements
- [yazi](https://github.com/sxyazi/yaji)

## Installation
```sh
ya pkg add JohWQ/open-paths
```
or
```sh
git clone https://github.com/JohWQ/open-paths.yazi ~/.config/yazi/plugins/open-paths.yazi
```

## Usage

Add this to your `~/.config/yazi/init.lua`
```lua
require("open-paths"):setup()
```

Add this to your `~/.config/yazi/keymap.toml`
```toml
[[mgr.prepend_keymap]]
on = [ "g", "o" ]
run = "plugin open-paths"
desc = "Jump to a path open in another Yazi"

[[mgr.prepend_keymap]]
on = [ "g", "c" ]
run = "plugin open-paths -- copy"
desc = "Copy a path open in another Yazi"
```

Press `g o`. Choose a path with `1`–`9`; `n` and `p` change pages,
and Escape cancels. `g c` opens the same picker and copies the selected path to
the system clipboard instead, using Yazi's clipboard support.

### Feasibility and limits
Yazi's [DDS](https://yazi-rs.github.io/docs/dds/) provides communication between
instances. The plugin broadcasts an on-demand request, and each participating
instance reads all its tabs in a synchronous callback and returns their current
directory URLs. A unique request token separates simultaneous requests.
The requester collects replies for a short interval, removes duplicate paths,
sorts them, and displays Yazi's native key picker.

Every invocation queries afresh: there are no persistent path files, polling
daemons, or cached paths left behind by crashed instances. The originating
instance's own tabs are excluded. Paths are passed directly to Yazi, without
shell interpolation. Control characters are escaped only in menu labels.

All participating instances must load the plugin and share the same DDS service.
Older running instances need a restart. Unresponsive instances may be omitted.
Results are a snapshot: a directory can move or a process can exit after replying.
Paths are shared with other subscribers on the same DDS service.

Reading `/proc/PID/cwd` on Linux could approximate the active directory without
cooperation, but cannot enumerate inactive tabs and may lag behind navigation.
The plugin protocol supports those tabs and avoids that platform-specific fallback.

The original project's Open/Save dialog integration is a separate concern.
This plugin operates inside Yazi, including when Yazi is used as a file chooser.
For a normal desktop dialog, `g p` lets you copy and manually paste a path.
Automatic global-hotkey control of GTK/Qt/browser dialogs would need a separate
desktop helper, with behavior depending on the desktop and X11/Wayland setup.

### Validation
Checked Lua and TOML syntax and ran two Yazi 26.9.1 processes with isolated test
configuration. Verified discovery of active and inactive remote tabs, navigation
to a selected directory, and removal of results after the remote process exits.
Clipboard delivery depends on the terminal/desktop and was not tested end to end.
