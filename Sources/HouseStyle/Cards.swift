import SwiftUI

public extension View {
    /// White (or dark) rounded card, used for list rows and settings
    func card(hovered: Bool = false, radius: CGFloat = Radius.row) -> some View {
        background(hovered ? AppColors.surfaceHover : AppColors.surface,
                   in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    /// A pastel block. Text on it is always ink, and buttons inside it switch
    /// to their on-pastel colours.
    func pastelCard(_ fill: Color, radius: CGFloat = Radius.block) -> some View {
        foregroundStyle(AppColors.ink)
            .environment(\.onPastel, true)
            .background(fill, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
    }

    /// Popover or sheet body: padded, on the app's ground colour
    func popoverChrome(width: CGFloat = 260) -> some View {
        padding(18)
            .frame(width: width)
            .background(AppColors.ground)
    }
}

/// A rounded bar showing how full something is
public struct MeterBar: View {
    let fraction: Double
    let fill: Color
    let track: Color
    let height: CGFloat

    public init(fraction: Double, fill: Color = AppColors.ink, track: Color = AppColors.ink.opacity(0.12),
                height: CGFloat = 10) {
        self.fraction = fraction
        self.fill = fill
        self.track = track
        self.height = height
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(fill)
                    .frame(width: max(height, geo.size.width * min(max(fraction, 0), 1)))
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityValue(Text("\(Int((fraction * 100).rounded())) percent"))
    }
}

/// Page scaffold for a full window: ground colour, padding and a scroll view
public struct Screen<Content: View>: View {
    let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                content
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)
            .padding(.bottom, 32)
            .frame(maxWidth: 860, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .scrollContentBackground(.hidden)
        .background(AppColors.ground)
    }
}
