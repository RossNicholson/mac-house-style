# HouseStyle

The shared look and menu bar plumbing for Ross Nicholson's Mac apps:
[BrewDock](https://github.com/RossNicholson/brewdock), [ClawdBar](https://github.com/RossNicholson/clawdbar)
and [Mop Up](https://github.com/RossNicholson/mop-up).

It's compiled into each app, so every app is complete on its own. Someone with
just one of the apps needs nothing else.

## What's in it

- **Colours and radii:** `AppColors` (pastels, ground, surface, ink, light and dark) and `Radius`
- **Fonts:** Barlow Condensed and Geist Mono, bundled. Use `.font(.display(28))` and `.font(.mono(10))`.
- **Buttons:** `PillButton` (the main action), `GhostButton`, `ColorBlockButton`, `RoundIconButton`,
  `HeaderIconButton`, `MonoLink`
- **Labels and cards:** `TagPill`, `SymbolTile`, `PopoverHeader`, `ScreenHeader`, `SectionLabel`,
  `.card()`, `.pastelCard(_:)`, `MeterBar`, `Screen`
- **The menu bar panel:** `MenuBarPanelController` owns the panel. It hangs under its icon, closes on Esc
  or a click elsewhere, stays put, and remembers the size the corner grip drags it to. The views on it
  are `PanelHeader`, `HeaderRefreshButton`, `PanelFooter`, `FooterButton` and `.menuBarPanel()`.
- **Settings:** `SettingToggle`, `SettingCard`, `SettingNote`, `PillPicker`, `UpdateBlock`
- **About:** `AboutPopover`
- **Updates:** `SelfUpdater`. An app installed with Homebrew updates itself through its cask and restarts.
  Installed from the DMG, "Check for updates" asks GitHub for the latest release and opens its page.
- **Screenshots:** `Snapshot.png` and `Snapshot.panel` render views to PNG off-screen, from a test

## Adding it to a new app

1. In `project.yml` (XcodeGen):

   ```yaml
   packages:
     HouseStyle:
       url: https://github.com/RossNicholson/mac-house-style
       from: 1.0.0

   targets:
     MyApp:
       dependencies:
         - package: HouseStyle
   ```

2. Add `Theme/HouseStyle.swift`, so every file can use it without an import:

   ```swift
   @_exported import HouseStyle

   extension AppInfo {
       static let myApp = AppInfo(name: "My App", repo: "my-app", cask: "myapp",
                                  coffeeLine: "If My App helps you out")
   }
   ```

3. Give the app a `Mascot` view of its own, in the same cartoon style.

4. For a menu bar app, own the status item and hand the panel to the controller:

   ```swift
   let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
   let panel = MenuBarPanelController(statusItem: statusItem)
   panel.setContent { MenuBarView() }   // fits its content; the grip makes it bigger
   ```

   and build the view from the shared pieces:

   ```swift
   VStack(spacing: 0) {
       PanelHeader(title: "My App", subtitle: "What it does") {
           Mascot(size: PanelMetrics.mascot)
       } actions: {
           HeaderRefreshButton(isRefreshing: model.isLoading) { model.refresh() }
           HeaderIconButton(symbol: "gearshape", help: "Settings") { … }
           HeaderIconButton(symbol: "info", help: "About & help") { … }
       }
       content.padding(.horizontal, PanelMetrics.inset)
       Spacer(minLength: 0)
       PanelFooter { Text("Updated just now") }
   }
   .menuBarPanel()
   ```

5. In Settings, put the app's own settings first, then **Launch at login**, then
   `UpdateBlock(updater: updater, app: .myApp)`. Call `updater.checkSilent()` at launch.

## Changing the look

Change it here, tag a new version, then bump `from:` in each app. Run each app's
`make screenshots` to see the result without clicking through the app.

## Licence

MIT. The fonts are under the SIL Open Font License; see the `-OFL.txt` files in `Sources/HouseStyle/Fonts`.
