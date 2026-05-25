# Browser Switcher

macOS menu bar app for switching the system default browser between work and personal browsers.

## MVP Scope

- Menu bar browser switching.
- Global shortcuts.
- Settings window.
- Launch at login.
- Safari and Microsoft Edge defaults, with bundle identifier based browser discovery.

## Default Shortcuts

- Work browser: `Control + Option + E`
- Personal browser: `Control + Option + S`

Shortcuts can be changed from the settings window.

## Development

Requires macOS 14 or newer and Swift 6, such as the toolchain included with Xcode 16.

Browser discovery uses the modern `NSWorkspace` APIs available on the supported macOS target.

```sh
swift build
swift run BrowserSwitcher
```

## Build and Install

```sh
chmod +x Scripts/package-app.sh
Scripts/package-app.sh
```

The unsigned app bundle is created at `dist/BrowserSwitcher.app`.

Run it from the build output:

```sh
open "dist/BrowserSwitcher.app"
```

Optionally copy it to `/Applications`:

```sh
cp -R "dist/BrowserSwitcher.app" "/Applications/BrowserSwitcher.app"
open "/Applications/BrowserSwitcher.app"
```

Because the app is unsigned, macOS may block the first launch. If that happens, open System Settings, go to Privacy & Security, and allow Browser Switcher to run.

For workplace use, prefer Developer ID signing and Apple notarization once the MVP behavior is confirmed locally.
