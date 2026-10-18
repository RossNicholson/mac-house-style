import AppKit
import SwiftUI

/// Ross's Mac apps, for the "More apps by Ross" card in each one's About popover.
/// The list is built in, so showing it never touches the network.
public enum HouseMacApp: String, CaseIterable, Identifiable, Sendable {
    case brewDock
    case clawdBar
    case mopUp

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .brewDock: return "BrewDock"
        case .clawdBar: return "ClawdBar"
        case .mopUp: return "Mop Up"
        }
    }

    public var tagline: String {
        switch self {
        case .brewDock: return "Homebrew in your menu bar"
        case .clawdBar: return "Claude Code usage at a glance"
        case .mopUp: return "Clean up and tune up your Mac"
        }
    }

    /// Matches `AppInfo.repo`, so the popover knows which app it's in
    public var repo: String {
        switch self {
        case .brewDock: return "brewdock"
        case .clawdBar: return "clawdbar"
        case .mopUp: return "mop-up"
        }
    }

    public var bundleID: String {
        switch self {
        case .brewDock: return "com.rossnicholson.BrewDock"
        case .clawdBar: return "com.rossnicholson.ClawdBar"
        case .mopUp: return "com.rossnicholson.MopUp"
        }
    }

    /// Its page on the website, which explains it and how to install it
    public var pageURL: URL {
        switch self {
        case .brewDock: return URL(string: "https://rossnicholson.dev/brewdock")!
        case .clawdBar: return URL(string: "https://rossnicholson.dev/clawdbar")!
        case .mopUp: return URL(string: "https://rossnicholson.dev/mopup")!
        }
    }

    var iconName: String {
        switch self {
        case .brewDock: return "brewdock"
        case .clawdBar: return "clawdbar"
        case .mopUp: return "mopup"
        }
    }

    public var isInstalled: Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) != nil
    }

    /// The apps worth suggesting from inside the app with this repo: not itself,
    /// and not ones already on this Mac (unless `hidingInstalled` is false, for screenshots)
    public static func others(than repo: String, hidingInstalled: Bool = true) -> [HouseMacApp] {
        allCases.filter { $0.repo != repo && !(hidingInstalled && $0.isInstalled) }
    }
}

/// The iPhone apps, shown together as one row that opens the website
enum HouseiPhoneApp: String, CaseIterable {
    case dontWorry = "dontworry"
    case feedie
    case wordSlip = "wordslip"

    var name: String {
        switch self {
        case .dontWorry: return "Don't Worry"
        case .feedie: return "Feedie"
        case .wordSlip: return "Word Slip"
        }
    }
}

enum HouseIcons {
    static func image(_ name: String) -> NSImage? {
        guard let url = Bundle.module.url(forResource: name, withExtension: "png", subdirectory: "Icons") else { return nil }
        return NSImage(contentsOf: url)
    }
}

/// "More apps by Ross": a white card with a row for each other Mac app, then
/// one row for the iPhone apps that opens the website
public struct MoreAppsCard: View {
    let currentRepo: String
    let hidingInstalled: Bool

    public init(current app: AppInfo, hidingInstalled: Bool = true) {
        self.currentRepo = app.repo
        self.hidingInstalled = hidingInstalled
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "More apps by Ross")
                .accessibilityAddTraits(.isHeader)

            VStack(spacing: 0) {
                ForEach(HouseMacApp.others(than: currentRepo, hidingInstalled: hidingInstalled)) { app in
                    MoreAppRow(title: app.name, detail: app.tagline,
                               hint: "Opens its page on rossnicholson.dev", url: app.pageURL) {
                        MacIcon(name: app.iconName)
                    }
                    RowDivider()
                }
                MoreAppRow(title: "On iPhone",
                           detail: HouseiPhoneApp.allCases.map(\.name).joined(separator: ", "),
                           hint: "Opens rossnicholson.dev", url: URL(string: "https://rossnicholson.dev")!) {
                    iPhoneIconStack()
                }
            }
            .padding(.vertical, 3)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: Radius.row, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: Radius.row, style: .continuous))
        }
        .padding(.top, 4)
    }
}

private struct MoreAppRow<Icon: View>: View {
    let title: String
    let detail: String
    let hint: String
    let url: URL
    @ViewBuilder let icon: Icon
    @State private var hovered = false

    var body: some View {
        Button {
            NSWorkspace.shared.open(url)
        } label: {
            HStack(spacing: 10) {
                icon
                    .frame(width: 30, height: 30)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.display(16, relativeTo: .headline))
                        .textCase(.uppercase)
                        .foregroundStyle(AppColors.text)
                    Text(detail)
                        .font(.mono(9.5))
                        .foregroundStyle(AppColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundStyle(AppColors.onSolid)
                    .frame(width: 20, height: 20)
                    .background(AppColors.solid, in: Circle())
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(hovered ? AppColors.surfaceHover : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .onHover { hovered = $0 }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isLink)
        .accessibilityHint(hint)
    }
}

/// A Mac app icon, rounded like the iPhone ones beside it
private struct MacIcon: View {
    let name: String

    var body: some View {
        if let image = HouseIcons.image(name) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .frame(width: 30, height: 30)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
    }
}

/// Three small overlapping iPhone app icons
private struct iPhoneIconStack: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            tile(.dontWorry).offset(x: 0, y: 0)
            tile(.feedie).offset(x: 12, y: 4)
            tile(.wordSlip).offset(x: 6, y: 12)
        }
        .frame(width: 30, height: 30, alignment: .topLeading)
    }

    @ViewBuilder
    private func tile(_ app: HouseiPhoneApp) -> some View {
        if let image = HouseIcons.image(app.rawValue) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .frame(width: 18, height: 18)
                .clipShape(RoundedRectangle(cornerRadius: 4.5, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                    .strokeBorder(AppColors.surface, lineWidth: 1.5))
        }
    }
}

private struct RowDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppColors.hairline)
            .frame(height: 1)
            .padding(.leading, 50)
            .padding(.trailing, 10)
    }
}
