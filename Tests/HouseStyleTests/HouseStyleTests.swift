import AppKit
import SwiftUI
import Testing
@testable import HouseStyle

@Test func bundledFontsRegister() {
    _ = AppFonts.registered
    for name in AppFonts.names {
        #expect(NSFont(name: name, size: 12) != nil, "\(name) should be available")
    }
}

@Test func versionComparison() {
    #expect(SelfUpdater.isNewer("1.0.1", than: "1.0.0"))
    #expect(SelfUpdater.isNewer("1.10.0", than: "1.9.2"))
    #expect(SelfUpdater.isNewer("2", than: "1.9.9"))
    #expect(!SelfUpdater.isNewer("1.0.0", than: "1.0.0"))
    #expect(!SelfUpdater.isNewer("1.0", than: "1.0.0"))
    #expect(!SelfUpdater.isNewer("1.4.1", than: "1.4.2"))
}

@Test func moreAppsLeaveOutTheCurrentApp() {
    let others = HouseMacApp.others(than: "clawdbar", hidingInstalled: false)
    #expect(others == [.brewDock, .mopUp])
    #expect(HouseMacApp.allCases.allSatisfy { HouseMacApp.others(than: $0.repo, hidingInstalled: false).count == 2 })
}

@Test func appIconsAreBundled() {
    for app in HouseMacApp.allCases {
        #expect(HouseIcons.image(app.iconName) != nil, "\(app.name) icon")
    }
    for app in HouseiPhoneApp.allCases {
        #expect(HouseIcons.image(app.rawValue) != nil, "\(app.name) icon")
    }
}

/// Set SNAPSHOT_DIR to render the About popover, light and dark
@MainActor @Test func aboutPopoverSnapshot() throws {
    guard let dir = ProcessInfo.processInfo.environment["SNAPSHOT_DIR"] else { return }
    let app = AppInfo(name: "ClawdBar", repo: "clawdbar", cask: "clawdbar",
                      coffeeLine: "If ClawdBar helps you pace your day")
    for dark in [false, true] {
        try Snapshot.panel(dark: dark, to: URL(fileURLWithPath: dir).appendingPathComponent("about-\(dark ? "dark" : "light").png")) {
            AboutPopover(app: app, hidingInstalledApps: false) {
                Circle().fill(AppColors.peach).frame(width: 56, height: 56)
            }
        }
    }
}
