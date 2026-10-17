import SwiftUI
import CoreText

/// The bundled fonts: Barlow Condensed for titles and Geist Mono for labels.
/// They ship inside this package, so an app needs no font files of its own.
public enum AppFonts {
    public static let display = "BarlowCondensed-Bold"

    public enum MonoWeight: Sendable {
        case regular, medium, semibold

        public var fontName: String {
            switch self {
            case .regular: return "GeistMono-Regular"
            case .medium: return "GeistMono-Medium"
            case .semibold: return "GeistMono-SemiBold"
            }
        }
    }

    static let names = ["BarlowCondensed-Bold", "GeistMono-Regular", "GeistMono-Medium", "GeistMono-SemiBold"]

    /// Registered on first use, so previews and tests get the fonts too
    public static let registered: Void = {
        for name in names {
            guard let url = Bundle.module.url(forResource: name, withExtension: "ttf", subdirectory: "Fonts") else { continue }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()
}

public extension Font {
    /// Bold condensed titles. Use with `.textCase(.uppercase)`.
    static func display(_ size: CGFloat, relativeTo style: Font.TextStyle = .title) -> Font {
        _ = AppFonts.registered
        return .custom(AppFonts.display, size: size, relativeTo: style)
    }

    /// Small monospaced labels and supporting text
    static func mono(_ size: CGFloat, weight: AppFonts.MonoWeight = .regular, relativeTo style: Font.TextStyle = .footnote) -> Font {
        _ = AppFonts.registered
        return .custom(weight.fontName, size: size, relativeTo: style)
    }
}
