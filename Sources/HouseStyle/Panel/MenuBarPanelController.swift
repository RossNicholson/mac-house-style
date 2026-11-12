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
    /// Lays the content out at a width: nil lets it fill the panel freely
    private var render: ((CGFloat?) -> Void)?
    /// The content's natural size when laid out at a width. Nil for a panel
    /// with a fixed default size.
    private var measure: ((CGFloat) -> NSSize)?
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

    /// Show a view that the panel fits to. The panel measures the view
    /// itself, as shown, so its state (a search, an open section) counts.
    /// With `resizable`, the grip can make the panel bigger than its content;
    /// `.menuBarPanel()` in the view picks this up.
    public func setContent<V: View>(resizable: Bool = true, @ViewBuilder _ make: () -> V) {
        self.resizable = resizable
        install(make(), measured: true)
        fitToContent()
    }

    /// Show a view that fills a panel of a set size, for content such as a
    /// scrolling list that has no natural height
    public func setContent<V: View>(defaultSize: NSSize, minimumSize: NSSize, @ViewBuilder _ make: () -> V) {
        self.defaultSize = defaultSize
        self.minimumSize = minimumSize
        resizable = true
        install(make(), measured: false)
        fitToContent()
    }

    private func install<V: View>(_ view: V, measured: Bool) {
        let resizable = self.resizable
        func root(_ width: CGFloat?) -> PanelRoot<V> {
            PanelRoot(content: view, width: width, resizable: resizable)
        }
        let hosting = NSHostingView(rootView: root(nil))
        // The window decides the size; the content just fills it
        hosting.sizingOptions = []
        // The panel's title bar is hidden; don't leave a gap for it
        if #available(macOS 13.3, *) { hosting.safeAreaRegions = [] }
        hosting.frame = container.bounds
        hosting.autoresizingMask = [.width, .height]
        container.subviews.forEach { $0.removeFromSuperview() }
        container.addSubview(hosting)

        // Setting the root view again keeps the content's state: it's the same view
        render = { [weak hosting] width in hosting?.rootView = root(width) }
        measure = measured ? { [weak hosting] width in
            guard let hosting else { return .zero }
            hosting.rootView = root(width)
            // A hosting view only reports a fitting size while it sizes
            // itself, so turn that on just long enough to ask
            hosting.sizingOptions = [.intrinsicContentSize]
            defer { hosting.sizingOptions = [] }
            return hosting.fittingSize
        } : nil
    }

    /// Size the panel to its content, or to the size you dragged it to if
    /// that's bigger, keeping it hanging from the menu bar and on the screen.
    /// Call this when the content changes height (a card appears or goes away).
    public func fitToContent() {
        let largest = largestSize
        let saved = resizable ? savedSize : nil
        var minimum: NSSize
        var size: NSSize
        if let measure {
            // Its narrowest, then its height at the width it'll be shown at
            let narrowest = measure(0)
            guard narrowest.width > 0, narrowest.height > 0 else { return }
            let width = min(max(narrowest.width, saved?.width ?? 0), largest.width)
            let natural = width == narrowest.width ? narrowest : measure(width)
            render?(width)
            minimum = NSSize(width: narrowest.width, height: natural.height)
            size = NSSize(width: width, height: max(natural.height, saved?.height ?? 0))
        } else {
            minimum = minimumSize
            let width = (saved?.width).flatMap { $0 > 0 ? $0 : nil } ?? defaultSize.width
            let height = (saved?.height).flatMap { $0 > 0 ? $0 : nil } ?? defaultSize.height
            size = NSSize(width: max(width, minimum.width), height: max(height, minimum.height))
        }
        // Never bigger than the screen, so the footer and grip stay in reach
        minimum = NSSize(width: min(minimum.width, largest.width), height: min(minimum.height, largest.height))
        size = NSSize(width: min(size.width, largest.width), height: min(size.height, largest.height))
        panel.minSize = minimum
        panel.maxSize = largest
        guard size != panel.frame.size else { return }
        if panel.isVisible {
            let frame = panel.frame
            panel.setFrame(NSRect(x: frame.minX, y: frame.maxY - size.height, width: size.width, height: size.height),
                           display: true)
            position()
        } else {
            panel.setContentSize(size)
        }
    }

    /// The room under the menu bar item on its screen
    private var largestSize: NSSize {
        let button = statusItem.button
        guard let buttonWindow = button?.window,
              let screen = buttonWindow.screen ?? NSScreen.main ?? NSScreen.screens.first else {
            return NSSize(width: 10_000, height: 10_000)
        }
        let visible = screen.visibleFrame
        let top = min(buttonWindow.frame.minY, visible.maxY)
        return NSSize(width: max(visible.width - 8, 200), height: max(top - visible.minY - 8, 200))
    }

    /// The size you dragged the panel to. For a panel that fits its content,
    /// a 0 width or height means that side fits the content.
    private var savedSize: NSSize? {
        UserDefaults.standard.string(forKey: sizeKey).map(NSSizeFromString)
    }

    /// Remember a size the panel was dragged to. The grip calls this. For a
    /// panel that fits its content, only a side that was dragged is kept, and
    /// dragging a side back to the content's size lets it fit again.
    func rememberSize(_ size: NSSize, from start: NSSize) {
        guard resizable else { return }
        var remembered = size
        if measure != nil {
            remembered = savedSize ?? .zero
            let fit = panel.minSize
            if size.width != start.width { remembered.width = size.width <= fit.width + 1 ? 0 : size.width }
            if size.height != start.height { remembered.height = size.height <= fit.height + 1 ? 0 : size.height }
        }
        if remembered == .zero {
            UserDefaults.standard.removeObject(forKey: sizeKey)
        } else {
            UserDefaults.standard.set(NSStringFromSize(remembered), forKey: sizeKey)
        }
    }

    public func windowDidResize(_ notification: Notification) {
        // Content that's measured is laid out at the panel's width, so follow the grip
        if measure != nil { render?(panel.frame.width) }
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
        x = max(min(x, screen.visibleFrame.maxX - panel.frame.width - 4), screen.visibleFrame.minX + 4)
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

/// The panel's content, told the width to lay out at and whether the panel
/// can be resized
struct PanelRoot<Content: View>: View {
    let content: Content
    let width: CGFloat?
    let resizable: Bool

    var body: some View {
        content
            .environment(\.panelContentWidth, width)
            .environment(\.panelResizable, resizable)
    }
}

private struct IsMeasuringPanelKey: EnvironmentKey {
    static let defaultValue = false
}

private struct PanelContentWidthKey: EnvironmentKey {
    static let defaultValue: CGFloat? = nil
}

private struct PanelResizableKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}

public extension EnvironmentValues {
    /// No longer set: the panel now measures its real content, not a copy
    @available(*, deprecated, message: "The panel measures its real content now; this is always false")
    var isMeasuringPanel: Bool {
        get { self[IsMeasuringPanelKey.self] }
        set { self[IsMeasuringPanelKey.self] = newValue }
    }
}

extension EnvironmentValues {
    /// The width a measured panel lays its content out at; nil to fill freely
    var panelContentWidth: CGFloat? {
        get { self[PanelContentWidthKey.self] }
        set { self[PanelContentWidthKey.self] = newValue }
    }

    /// Whether the controller made the panel resizable; nil outside one
    var panelResizable: Bool? {
        get { self[PanelResizableKey.self] }
        set { self[PanelResizableKey.self] = newValue }
    }
}
