import SwiftUI

/// The "Check for updates" block at the bottom of Settings. It turns into
/// "Update" when a new version is out.
public struct UpdateBlock: View {
    @ObservedObject var updater: SelfUpdater
    let app: AppInfo
    @State private var checkedUpToDate = false

    public init(updater: SelfUpdater, app: AppInfo) {
        self.updater = updater
        self.app = app
    }

    public var body: some View {
        switch updater.available {
        case .homebrew:
            ColorBlockButton(
                title: updater.isUpdating ? "Updating…" : "Update \(app.name)",
                detail: "A new version is ready. \(app.name) will restart.",
                fill: AppColors.peach, symbol: "arrow.up"
            ) {
                Task { await updater.update() }
            }
            .disabled(updater.isUpdating)
        case .download(let version, _):
            ColorBlockButton(
                title: "Get \(app.name) \(version)",
                detail: "A new version is out. This opens its download page.",
                fill: AppColors.peach, symbol: "arrow.down"
            ) {
                Task { await updater.update() }
            }
        case nil:
            ColorBlockButton(
                title: updater.isChecking ? "Checking…" : "Check for updates",
                detail: updater.lastError
                    ?? (checkedUpToDate ? "\(app.name) is up to date." : "See if a new version of \(app.name) is out"),
                fill: checkedUpToDate ? AppColors.mint : AppColors.butter,
                symbol: checkedUpToDate ? "checkmark" : "arrow.clockwise"
            ) {
                checkedUpToDate = false
                Task {
                    await updater.check()
                    checkedUpToDate = !updater.updateAvailable && updater.lastError == nil
                }
            }
            .disabled(updater.isChecking)
        }
    }
}
