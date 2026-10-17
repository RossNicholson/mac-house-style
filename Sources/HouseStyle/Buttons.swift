import SwiftUI

private struct OnPastelKey: EnvironmentKey {
    static let defaultValue = false
}

public extension EnvironmentValues {
    /// True inside a pastel block. Pastels look the same in light and dark
    /// mode, so buttons on them keep their light-mode ink colours.
    var onPastel: Bool {
        get { self[OnPastelKey.self] }
        set { self[OnPastelKey.self] = newValue }
    }
}

/// The dark pill with an icon in a coloured circle: the main action on a screen
public struct PillButton: View {
    @Environment(\.onPastel) private var onPastel
    let title: String
    let symbol: String
    let circle: Color
    let destructive: Bool
    let action: () -> Void

    public init(title: String, symbol: String = "arrow.right", circle: Color = AppColors.mint,
                destructive: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.symbol = symbol
        self.circle = circle
        self.destructive = destructive
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.display(17, relativeTo: .headline))
                    .textCase(.uppercase)
                Image(systemName: symbol)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(AppColors.ink)
                    .frame(width: 24, height: 24)
                    .background(destructive ? AppColors.coral : circle, in: Circle())
            }
            .foregroundStyle(onPastel ? Color.white : AppColors.onSolid)
            .padding(.leading, 18)
            .padding(.trailing, 7)
            .padding(.vertical, 7)
            .background(onPastel ? AppColors.ink : AppColors.solid, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(PressableStyle())
    }
}

/// A quieter pill for secondary actions ("Scan again", "Cancel")
public struct GhostButton: View {
    @Environment(\.onPastel) private var onPastel
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
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol).font(.system(size: 10, weight: .bold))
                }
                Text(title)
                    .font(.mono(11, weight: .medium))
            }
            .foregroundStyle(onPastel ? AppColors.ink : AppColors.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(onPastel ? Color.white.opacity(0.7) : AppColors.surface, in: Capsule())
            .overlay(Capsule().strokeBorder(onPastel ? Color.clear : AppColors.hairline))
            .contentShape(Capsule())
        }
        .buttonStyle(PressableStyle())
    }
}

/// A filled circle with a symbol
public struct RoundIconButton: View {
    let symbol: String
    let size: CGFloat
    let fill: Color
    let foreground: Color
    let help: String?
    let action: () -> Void

    public init(symbol: String, size: CGFloat = 26, fill: Color = AppColors.solid,
                foreground: Color = AppColors.onSolid, help: String? = nil, action: @escaping () -> Void) {
        self.symbol = symbol
        self.size = size
        self.fill = fill
        self.foreground = foreground
        self.help = help
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(foreground)
                .frame(width: size, height: size)
                .background(fill, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(PressableStyle())
        .help(help ?? "")
        .accessibilityLabel(help ?? symbol)
    }
}

/// A white (or dark) circle for a panel header's actions: refresh, settings, info
public struct HeaderIconButton: View {
    let symbol: String
    let help: String
    let action: () -> Void

    public init(symbol: String, help: String, action: @escaping () -> Void) {
        self.symbol = symbol
        self.help = help
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppColors.text)
                .frame(width: 26, height: 26)
                .background(AppColors.surface, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(PressableStyle())
        .help(help)
        .accessibilityLabel(help)
    }
}

/// A pastel block with a condensed title, a mono description and a round arrow,
/// for secondary actions such as "Check for updates"
public struct ColorBlockButton: View {
    let title: String
    let detail: String
    let fill: Color
    let symbol: String
    let action: () -> Void

    public init(title: String, detail: String, fill: Color, symbol: String = "arrow.up.right",
                action: @escaping () -> Void) {
        self.title = title
        self.detail = detail
        self.fill = fill
        self.symbol = symbol
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.display(18, relativeTo: .headline))
                        .textCase(.uppercase)
                    Text(detail)
                        .font(.mono(9.5))
                        .opacity(0.75)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .background(AppColors.ink, in: Circle())
            }
            .foregroundStyle(AppColors.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(fill, in: RoundedRectangle(cornerRadius: Radius.row, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: Radius.row, style: .continuous))
        }
        .buttonStyle(PressableStyle())
    }
}

/// Text link styled as a mono label
public struct MonoLink: View {
    let title: String
    let destination: URL

    public init(title: String, destination: URL) {
        self.title = title
        self.destination = destination
    }

    public var body: some View {
        Link(destination: destination) {
            Text(title)
                .font(.mono(10.5, weight: .medium))
                .foregroundStyle(AppColors.text)
                .underline()
        }
        .buttonStyle(.plain)
    }
}

/// Slight shrink while pressed, so plain buttons still feel tappable
public struct PressableStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
