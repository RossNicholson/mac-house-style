import AppKit
import SwiftUI

/// The floating panel that drops down from a menu bar item, the same in every
/// app: it hangs under its icon, closes when you click elsewhere or press Esc,
/// can be made bigger with the corner grip (and remembers that size), and
/// stays put under the menu bar.
///
/// The app owns the status item and its title; this owns the panel.
@MainActor
public final class MenuBarPanelController: NSObject, NSWindowDelegate {
    public let statusItem: NSStatusItem
    public let panel: NSPanel

    /// Called after the panel opens and before it closes, e.g. to refresh
    public var onOpen: (() -> Void)?
    public var onClose: (() -> Void)?

    private let container: NSView
    /// An off-screen copy of the content at its natural size, used to measure
    /// how big the panel needs to be. Nil for a panel with a fixed default size.
    private var measure: NSView?
    private var defaultSize = NSSize(width: 300, height: 400)
    private var minimumSize = NSSize(width: 300, height: 200)
    private var resizable = true
    private let sizeKey: String
    private var clickMonitor: Any?
    private var keyMonitor: Any?

    public var isVisible: Bool { panel.isVisible }

    /// - Parameter sizeKey: where the size you drag the panel to is remembered
    public init(statusItem: NSStatusItem, sizeKey: String = "panelSize") {
        self.statusItem = statusItem
        self.sizeKey = sizeKey
        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: defaultSize),
            styleMask: [.titled, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        container = NSView(frame: NSRect(origin: .zero, size: defaultSize))
        super.init()

        panel.delegate = self
        panel.isFloatingPanel = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        // It belongs under its icon, so it can't be dragged away
        panel.isMovable = false
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        // The SwiftUI view goes in a plain container rather than being the
        // panel's own content view: as the content view, SwiftUI sizes the
        // window from its content, which fights the resize grip and loops.
        panel.contentView = container

        statusItem.button?.target = self
        statusItem.button?.action = #selector(toggle)
    }

    // MARK: - Content

    /// Show a view that the panel fits to. `make` is called twice: once for
    /// the panel and once for an off-screen copy that measures it. With
    /// `resizable`, the grip can make the panel bigger than its content.
    public func setContent<V: View>(resizable: Bool = true, @ViewBuilder _ make: () -> V) {
        let measureView = NSHostingView(rootView: make().environment(\.isMeasuringPanel, true))
        if #available(macOS 13.3, *) { measureView.safeAreaRegions = [] }
        measure = measureView
        self.resizable = resizable
        install(make())
        fitToContent()
    }

    /// Show a view that fills a panel of a set size, for content such as a
    /// scrolling list that has no natural height
    public func setContent<V: View>(defaultSize: NSSize, minimumSize: NSSize, @ViewBuilder _ make: () -> V) {
        measure = nil
        self.defaultSize = defaultSize
        self.minimumSize = minimumSize
        resizable = true
        install(make())
        fitToContent()
    }

    private func install<V: View>(_ view: V) {
        let hosting = NSHostingView(rootView: view)
        // The window decides the size; the content just fills it
        hosting.sizingOptions = []
        // The panel's title bar is hidden; don't leave a gap for it
        if #available(macOS 13.3, *) { hosting.safeAreaRegions = [] }
        hosting.frame = container.bounds
        hosting.autoresizingMask = [.width, .height]
        container.subviews.forEach { $0.removeFromSuperview() }
        container.addSubview(hosting)
    }

    /// Size the panel to its content, or to the size you dragged it to if
    /// that's bigger, keeping it hanging from the menu bar. Call this when the
    /// content changes height (a card appears or goes away).
    public func fitToContent() {
        let fit: NSSize
        if let measure {
            fit = measure.fittingSize
            guard fit.width > 0, fit.height > 0 else { return }
        } else {
            fit = minimumSize
        }
        panel.minSize = fit
        var size = resizable ? (savedSize ?? .zero) : .zero
        if measure == nil, savedSize == nil { size = defaultSize }
        size = NSSize(width: max(fit.width, size.width), height: max(fit.height, size.height))
        guard size != panel.frame.size else { return }
        if panel.isVisible {
            let frame = panel.frame
            panel.setFrame(NSRect(x: frame.minX, y: frame.maxY - size.height, width: size.width, height: size.height),
                           display: true)
        } else {
            panel.setContentSize(size)
        }
    }

    private var savedSize: NSSize? {
        UserDefaults.standard.string(forKey: sizeKey).map(NSSizeFromString)
    }

    /// Remember a size the panel was dragged to. The grip calls this.
    func rememberSize(_ size: NSSize) {
        guard resizable else { return }
        UserDefaults.standard.set(NSStringFromSize(size), forKey: sizeKey)
    }

    // MARK: - Open and close

    @objc public func toggle() {
        if panel.isVisible { close() } else { open() }
    }

    public func open() {
        guard !panel.isVisible else { return }
        fitToContent()
        position()
        panel.makeKeyAndOrderFront(nil)

        // Clicks on our own menu bar item arrive here too; leave those to toggle()
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self, !self.mouseIsOverStatusItem else { return }
                self.close()
            }
        }
        // Esc closes the panel. A local monitor sees it even while a text
        // field (which would otherwise swallow Esc) has focus.
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            let windowNumber = event.windowNumber
            let closed = MainActor.assumeIsolated { () -> Bool in
                guard let self, windowNumber == self.panel.windowNumber else { return false }
                self.close()
                return true
            }
            return closed ? nil : event
        }
        onOpen?()
    }

    public func close() {
        guard panel.isVisible || clickMonitor != nil else { return }
        onClose?()
        panel.orderOut(nil)
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
            self.keyMonitor = nil
        }
    }

    private func position() {
        guard let button = statusItem.button, let buttonWindow = button.window else { return }
        let screenRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        guard let screen = buttonWindow.screen ?? NSScreen.main ?? NSScreen.screens.first else { return }
        var x = screenRect.midX - panel.frame.width / 2
        x = min(max(x, screen.visibleFrame.minX + 4), screen.visibleFrame.maxX - panel.frame.width - 4)
        panel.setFrameOrigin(NSPoint(x: x, y: screenRect.minY - panel.frame.height))
    }

    public func windowDidResignKey(_ notification: Notification) {
        // Wait a tick for the new key window to settle, then stay open if it
        // belongs to the panel: a popover, sheet or save dialog opened from it.
        // Clicking another app, or one of this app's own windows, closes it.
        DispatchQueue.main.async { [weak self] in
            guard let self, self.panel.isVisible else { return }
            if NSApp.modalWindow != nil { return }
            if let key = NSApp.keyWindow, key !== self.panel,
               key.sheetParent != nil || !key.canBecomeMain {
                return
            }
            // A click on the menu bar item is toggle()'s to handle; closing
            // here would make that click reopen the panel straight away.
            if self.mouseIsOverStatusItem { return }
            self.close()
        }
    }

    private var mouseIsOverStatusItem: Bool {
        guard let button = statusItem.button, let window = button.window else { return false }
        let frame = window.convertToScreen(button.convert(button.bounds, to: nil))
        return frame.contains(NSEvent.mouseLocation)
    }
}

private struct IsMeasuringPanelKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    /// True in the off-screen copy of a panel's content that measures its
    /// natural size. `menuBarPanel()` uses it to stop the copy stretching.
    var isMeasuringPanel: Bool {
        get { self[IsMeasuringPanelKey.self] }
        set { self[IsMeasuringPanelKey.self] = newValue }
    }
}
