import SwiftUI
import AppKit

// The house look shared by every Mac app: pastel colour blocks, bold
// condensed uppercase titles and small monospaced labels. The same palette
// as the iOS apps (Don't Worry, Word Slip).

public enum AppColors {
    // Pastels. Text on them is always `ink`, in light and dark mode.
    public static let peach = Color(hex: 0xF6C3B4)
    public static let butter = Color(hex: 0xF6E2A4)
    public static let periwinkle = Color(hex: 0xC3C7F6)
    public static let mint = Color(hex: 0xC2E6D6)
    public static let lilac = Color(hex: 0xDCD2F0)
    public static let coral = Color(hex: 0xEE9C86)
    public static let ink = Color(hex: 0x232428)

    public static let pastels = [peach, butter, periwinkle, mint, lilac]

    public static let ground = Color(light: 0xE9EFEA, dark: 0x16171A)
    public static let surface = Color(light: 0xFFFFFF, dark: 0x2A2B30)
    public static let surfaceHover = Color(light: 0xF6F8F6, dark: 0x33353B)
    public static let text = Color(light: 0x232428, dark: 0xF2F1EE)
    public static let secondaryText = Color(light: 0x5E636C, dark: 0xA9ADB5)
    public static let hairline = Color(light: 0xD5DCD7, dark: 0x2E3035)

    /// Round buttons and the selected tab: ink on light, cream on dark
    public static let solid = Color(light: 0x232428, dark: 0xF2F1EE)
    public static let onSolid = Color(light: 0xFFFFFF, dark: 0x232428)

    public static let toggle = Color(hex: 0x4FAE87)
    public static let destructive = Color(light: 0xB93A26, dark: 0xF19A85)

    /// A stable pastel for a name, so each one keeps its colour
    public static func pastel(for name: String) -> Color {
        let sum = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return pastels[sum % pastels.count]
    }
}

/// Corner radii, so every app rounds the same things the same amount
public enum Radius {
    /// Search fields, small notices
    public static let small: CGFloat = 12
    /// List rows and setting cards
    public static let row: CGFloat = 14
    /// Pastel blocks in a menu bar panel
    public static let block: CGFloat = 16
    /// Cards in a full window
    public static let window: CGFloat = 18
    /// Big pastel heroes in a full window
    public static let hero: CGFloat = 24
}

public extension Color {
    init(hex: UInt32) {
        self.init(nsColor: NSColor(hex: hex))
    }

    /// A colour that switches with light and dark mode
    init(light: UInt32, dark: UInt32) {
        self.init(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light)
        })
    }
}

public extension NSColor {
    convenience init(hex: UInt32) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
