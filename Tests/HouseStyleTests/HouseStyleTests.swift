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
    #expect(others == [.brewDock, .mopUp, .keyBar, .repoRadar])
    #expect(HouseMacApp.allCases.allSatisfy { HouseMacApp.others(than: $0.repo, hidingInstalled: false).count == 4 })
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

/// A panel must wrap text at its width when measuring, or it comes out
/// too short and cuts off its footer
@MainActor @Test func panelMeasuresWrappedText() {
    let text = String(repeating: "Claude Code can use your keys without seeing them. ", count: 4)
    let oneLine = NSHostingView(rootView: Text("Claude")).fittingSize.height
    let measured = NSHostingView(rootView: Text(text)
        .fixedSize(horizontal: false, vertical: true)
        .menuBarPanel()
        .environment(\.panelContentWidth, 0)).fittingSize
    #expect(measured.width == PanelMetrics.width)
    #expect(measured.height > oneLine * 2, "text should wrap over several lines")
}

@MainActor final class PanelModel: ObservableObject {
    nonisolated(unsafe) static var made = 0
    @Published var rows = 2
    init() { Self.made += 1 }
}

private struct PanelContent: View {
    @StateObject private var counted = PanelModel()
    @ObservedObject var model: PanelModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(0..<model.rows, id: \.self) { Text("Row \($0)") }
        }
        .menuBarPanel()
    }
}

/// The panel measures the content as shown, with its state, and makes it once
@MainActor @Test func panelMeasuresItsRealContent() {
    let model = PanelModel()
    PanelModel.made = 0
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    defer { NSStatusBar.system.removeStatusItem(item) }
    let suite = "panel-test-\(UUID().uuidString)"
    let controller = MenuBarPanelController(statusItem: item, sizeKey: suite)
    defer { UserDefaults.standard.removeObject(forKey: suite) }
    controller.setContent { PanelContent(model: model) }
    let short = controller.panel.frame.height
    #expect(short > 0)
    // Apps refit a tick after a change, once SwiftUI has caught up
    func refit() {
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))
        controller.fitToContent()
    }
    model.rows = 12
    refit()
    let tall = controller.panel.frame.height
    #expect(tall > short + 100, "more rows, taller panel")
    #expect(PanelModel.made == 1, "the content's own model is made once, not again for a measuring copy")

    // Dragged wider only: the height still follows the content
    controller.rememberSize(NSSize(width: 420, height: tall), from: NSSize(width: PanelMetrics.width, height: tall))
    model.rows = 2
    refit()
    #expect(controller.panel.frame.width == 420)
    #expect(controller.panel.frame.height == short, "a drag that didn't change the height doesn't pin it")

    // Dragged back to the content's width: it fits again
    controller.rememberSize(NSSize(width: PanelMetrics.width, height: short), from: NSSize(width: 420, height: short))
    #expect(UserDefaults.standard.string(forKey: suite) == nil)
}

/// The panel is never taller than the room under the menu bar
@MainActor @Test func panelStaysOnScreen() {
    let model = PanelModel()
    model.rows = 400
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    defer { NSStatusBar.system.removeStatusItem(item) }
    let controller = MenuBarPanelController(statusItem: item, sizeKey: "panel-test-\(UUID().uuidString)")
    controller.setContent { PanelContent(model: model) }
    guard let screen = NSScreen.main else { return }
    #expect(controller.panel.frame.height <= screen.visibleFrame.height)
    #expect(controller.panel.maxSize.height <= screen.visibleFrame.height)
}

@MainActor @Test func meterBarTakesAnyFraction() throws {
    let dir = FileManager.default.temporaryDirectory
    for fraction in [Double.nan, .infinity, -1, 1.3] {
        try Snapshot.png(MeterBar(fraction: fraction), size: NSSize(width: 100, height: 10),
                         to: dir.appendingPathComponent("meter-\(UUID().uuidString).png"))
    }
}
