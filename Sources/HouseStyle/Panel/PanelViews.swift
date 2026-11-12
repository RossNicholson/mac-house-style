import AppKit
import SwiftUI

/// Sizes every menu bar panel shares
public enum PanelMetrics {
    /// The narrowest a panel gets, and the width of one that fits its content
    public static let width: CGFloat = 300
    /// The mascot beside the app's name in the header
    public static let mascot: CGFloat = 40
    /// Side padding for the header, the content and the footer
    public static let inset: CGFloat = 14
}

public extension View {
    /// The menu bar panel's frame: the ground colour, the corner resize grip,
    /// and a width that grows when the panel is dragged bigger. Put it on the
    /// panel's whole content (header, content, footer). In a
    /// MenuBarPanelController's panel, whether it's resizable comes from the
    /// controller's `setContent`, and `resizable` here is ignored.
    func menuBarPanel(width: CGFloat = PanelMetrics.width, resizable: Bool = true) -> some View {
        modifier(MenuBarPanelFrame(width: width, resizable: resizable))
    }
}

private struct MenuBarPanelFrame: ViewModifier {
    @Environment(\.panelContentWidth) private var contentWidth
    @Environment(\.panelResizable) private var controllerResizable
    let width: CGFloat
    let requestedResizable: Bool

    init(width: CGFloat, resizable: Bool) {
        self.width = width
        requestedResizable = resizable
    }

    private var resizable: Bool { controllerResizable ?? requestedResizable }

    func body(content: Content) -> some View {
        sized(content)
            .background(AppColors.ground)
            .overlay(alignment: .bottomTrailing) {
                if resizable {
                    ResizeGrip().padding(3)
                }
            }
    }

    /// A measured panel lays its content out at a set width, so its text
    /// wraps as it will be shown: a min/max frame asked for its ideal size
    /// measures every line unwrapped, and the panel comes out too short.
    @ViewBuilder private func sized(_ content: Content) -> some View {
        if let contentWidth {
            content
                .frame(width: resizable ? max(contentWidth, width) : width, alignment: .top)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        } else {
            content.frame(minWidth: width, maxWidth: resizable ? .infinity : width,
                          maxHeight: resizable ? .infinity : nil, alignment: .top)
        }
    }
}

/// The top of every menu bar panel: the app's mascot, its name and a line
/// about it, then round buttons (refresh, settings, info, in that order)
public struct PanelHeader<Mascot: View, Actions: View>: View {
    let title: String
    let subtitle: String
    let mascot: Mascot
    let actions: Actions

    public init(title: String, subtitle: String,
                @ViewBuilder mascot: () -> Mascot,
                @ViewBuilder actions: () -> Actions) {
        self.title = title
        self.subtitle = subtitle
        self.mascot = mascot()
        self.actions = actions()
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 0) {
            mascot
                .padding(.trailing, 10)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.display(28, relativeTo: .largeTitle))
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.text)
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(.mono(10))
                    .foregroundStyle(AppColors.secondaryText)
                    .lineLimit(1)
            }
            .layoutPriority(1)
            Spacer(minLength: 8)
            HStack(spacing: 6) {
                actions
            }
        }
        .padding(.horizontal, PanelMetrics.inset)
        .padding(.top, PanelMetrics.inset)
        .padding(.bottom, 12)
    }
}

/// The header's refresh button, which spins while a refresh runs
public struct HeaderRefreshButton: View {
    let isRefreshing: Bool
    let action: () -> Void

    public init(isRefreshing: Bool, action: @escaping () -> Void) {
        self.isRefreshing = isRefreshing
        self.action = action
    }

    public var body: some View {
        if isRefreshing {
            ProgressView()
                .controlSize(.small)
                .frame(width: 26, height: 26)
                .accessibilityLabel("Refreshing")
        } else {
            HeaderIconButton(symbol: "arrow.clockwise", help: "Refresh", action: action)
        }
    }
}

/// The bottom of every menu bar panel: a short status line on the left and
/// Quit on the right, above a hairline
public struct PanelFooter<Status: View>: View {
    let status: Status

    public init(@ViewBuilder status: () -> Status) {
        self.status = status()
    }

    public var body: some View {
        HStack(spacing: 8) {
            status
                .font(.mono(9.5))
                .foregroundStyle(AppColors.secondaryText)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button("Quit") { NSApplication.shared.terminate(nil) }
                .font(.mono(9.5, weight: .semibold))
                .textCase(.uppercase)
                .buttonStyle(.plain)
                .foregroundStyle(AppColors.text)
        }
        .padding(.leading, 16)
        .padding(.trailing, 26)   // clear of the resize grip in the corner
        .padding(.vertical, 9)
        .overlay(alignment: .top) {
            Rectangle().fill(AppColors.hairline).frame(height: 1)
        }
    }
}

/// A text button for the footer's status side, e.g. "Open Mop Up"
public struct FooterButton: View {
    let title: String
    let symbol: String?
    let action: () -> Void

    public init(title: String, symbol: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                if let symbol {
                    Image(systemName: symbol).font(.system(size: 8, weight: .bold))
                }
            }
            .font(.mono(9.5, weight: .semibold))
            .textCase(.uppercase)
            .foregroundStyle(AppColors.text)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
