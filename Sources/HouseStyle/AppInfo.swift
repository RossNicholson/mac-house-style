import AppKit
import SwiftUI

/// What the shared pieces need to know about the app using them
public struct AppInfo: Sendable {
    /// The app's name as people see it, e.g. "Mop Up"
    public let name: String
    /// Its GitHub repo under RossNicholson, e.g. "mop-up"
    public let repo: String
    /// Its cask in the rossnicholson/tap Homebrew tap, e.g. "mopup"
    public let cask: String
    /// Finishes "Buy me a coffee", e.g. "If Mop Up keeps your Mac tidy"
    public let coffeeLine: String

    public init(name: String, repo: String, cask: String, coffeeLine: String) {
        self.name = name
        self.repo = repo
        self.cask = cask
        self.coffeeLine = coffeeLine
    }

    public var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
    }

    /// The cask by its full name. Homebrew 7 refuses short names for casks
    /// from taps you haven't trusted, but accepts (and trusts) a full one.
    public var caskFullName: String { "rossnicholson/tap/\(cask)" }

    public var repoURL: URL { URL(string: "https://github.com/RossNicholson/\(repo)")! }
}

/// The info popover: who made the app, how to get help, and the small print
public struct AboutPopover<Mascot: View>: View {
    let app: AppInfo
    let mascot: Mascot

    public init(app: AppInfo, @ViewBuilder mascot: () -> Mascot) {
        self.app = app
        self.mascot = mascot()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                PopoverHeader(title: app.name, subtitle: "Version \(app.version)\nMade by Ross Nicholson")
                mascot
            }

            ColorBlockButton(title: "Get help", detail: "Bugs, questions and feature requests", fill: AppColors.mint) {
                NSWorkspace.shared.open(URL(string: "https://rossnicholson.dev/support")!)
            }
            ColorBlockButton(title: "Email support", detail: "support@rossnicholson.dev", fill: AppColors.periwinkle,
                             symbol: "envelope.fill") {
                NSWorkspace.shared.open(URL(string: "mailto:support@rossnicholson.dev")!)
            }
            ColorBlockButton(title: "Buy me a coffee", detail: app.coffeeLine, fill: AppColors.peach,
                             symbol: "cup.and.saucer.fill") {
                NSWorkspace.shared.open(URL(string: "https://buymeacoffee.com/rossnicholson")!)
            }

            HStack(spacing: 10) {
                MonoLink(title: "Website", destination: URL(string: "https://rossnicholson.dev")!)
                MonoLink(title: "GitHub", destination: app.repoURL)
                MonoLink(title: "Terms", destination: URL(string: "https://rossnicholson.dev/terms")!)
                MonoLink(title: "Privacy", destination: URL(string: "https://rossnicholson.dev/privacy")!)
            }
            .padding(.top, 2)
        }
        .popoverChrome()
    }
}
