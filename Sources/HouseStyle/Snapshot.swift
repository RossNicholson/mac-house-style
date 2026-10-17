import AppKit
import SwiftUI

/// Renders views to PNG files off-screen, for website screenshots and for
/// checking a design without clicking through the app. Use from a test.
@MainActor
public enum Snapshot {
    /// Renders `view` at `size` (points; the PNG is at the screen's scale)
    public static func png<V: View>(_ view: V, size: NSSize, dark: Bool = false, to url: URL,
                                    transparent: Bool = false, exactPixels: Bool = false) throws {
        let window = NSWindow(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless],
                              backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        if transparent { window.backgroundColor = .clear; window.isOpaque = false }
        let host = NSHostingView(rootView: view)
        host.frame = NSRect(origin: .zero, size: size)
        window.contentView = host
        window.orderFrontRegardless()
        RunLoop.main.run(until: Date().addingTimeInterval(1.0))
        host.layoutSubtreeIfNeeded()
        guard var rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else {
            throw CocoaError(.fileWriteUnknown)
        }
        host.cacheDisplay(in: host.bounds, to: rep)
        if exactPixels, let small = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) {
            // Exactly size.width × size.height pixels, e.g. 1200×630 social cards
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: small)
            rep.draw(in: NSRect(origin: .zero, size: size))
            NSGraphicsContext.restoreGraphicsState()
            rep = small
        }
        window.orderOut(nil)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        try data.write(to: url)
    }

    /// Renders a menu bar panel's content at the size it fits, or at `size`
    /// for one that fills a set size
    public static func panel<V: View>(dark: Bool = false, size: NSSize? = nil, to url: URL,
                                      @ViewBuilder _ make: () -> V) throws {
        let fit = size ?? NSHostingView(rootView: make().environment(\.isMeasuringPanel, true)).fittingSize
        try png(make(), size: fit, dark: dark, to: url)
    }
}
