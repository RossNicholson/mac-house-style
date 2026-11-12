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
    #expect(others == [.brewDock, .mopUp, .keyBar])
    #expect(HouseMacApp.allCases.allSatisfy { HouseMacApp.others(than: $0.repo, hidingInstalled: false).count == 3 })
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

/// The off-screen copy that sizes a panel must wrap text at the panel's
/// width, or the panel comes out too short and cuts off its footer
@MainActor @Test func panelMeasuresWrappedText() {
    let text = String(repeating: "Claude Code can use your keys without seeing them. ", count: 4)
    let oneLine = NSHostingView(rootView: Text("Claude")).fittingSize.height
    let measured = NSHostingView(rootView: Text(text)
        .fixedSize(horizontal: false, vertical: true)
        .menuBarPanel()
        .environment(\.isMeasuringPanel, true)).fittingSize
    #expect(measured.width == PanelMetrics.width)
    #expect(measured.height > oneLine * 2, "text should wrap over several lines")
}
