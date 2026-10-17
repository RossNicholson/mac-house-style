import SwiftUI

/// Small uppercase mono label in a capsule, e.g. "UPDATE" or "LOOK FIRST"
public struct TagPill: View {
    let text: String
    let fill: Color
    let foreground: Color

    public init(text: String, fill: Color = AppColors.butter, foreground: Color = AppColors.ink) {
        self.text = text
        self.fill = fill
        self.foreground = foreground
    }

    public var body: some View {
        Text(text)
            .font(.mono(9, weight: .semibold))
            .textCase(.uppercase)
            .foregroundStyle(foreground)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(fill, in: Capsule())
    }
}

/// A rounded square with a symbol on a pastel
public struct SymbolTile: View {
    let symbol: String
    let fill: Color
    let size: CGFloat

    public init(symbol: String, fill: Color, size: CGFloat = 30) {
        self.symbol = symbol
        self.fill = fill
        self.size = size
    }

    public var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.45, weight: .semibold))
            .foregroundStyle(AppColors.ink)
            .frame(width: size, height: size)
            .background(fill, in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
    }
}

/// Large condensed title with a mono subtitle, at the top of a popover or sheet
public struct PopoverHeader: View {
    let title: String
    let subtitle: String

    public init(title: String, subtitle: String) {
        self.title = title
        self.subtitle = subtitle
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.display(30, relativeTo: .largeTitle))
                .textCase(.uppercase)
                .foregroundStyle(AppColors.text)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.mono(10.5))
                .foregroundStyle(AppColors.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Large condensed title with a mono subtitle, at the top of every page in a window
public struct ScreenHeader<Trailing: View>: View {
    let title: String
    let subtitle: String
    let trailing: Trailing

    public init(title: String, subtitle: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.display(40, relativeTo: .largeTitle))
                    .textCase(.uppercase)
                    .foregroundStyle(AppColors.text)
                    .accessibilityAddTraits(.isHeader)
                Text(subtitle)
                    .font(.mono(11.5))
                    .foregroundStyle(AppColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            trailing
        }
    }
}

public extension ScreenHeader where Trailing == EmptyView {
    init(title: String, subtitle: String) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

/// Mono caption above a group of cards
public struct SectionLabel: View {
    let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .font(.mono(10, weight: .semibold))
            .textCase(.uppercase)
            .tracking(0.6)
            .foregroundStyle(AppColors.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
