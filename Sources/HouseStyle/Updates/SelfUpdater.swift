import AppKit
import Foundation

/// Keeps an app up to date. Installed with Homebrew, it updates itself through
/// its cask and restarts. Installed some other way (the DMG), it asks GitHub
/// for the latest release and offers the download page.
@MainActor
public final class SelfUpdater: ObservableObject {
    public enum Update: Equatable, Sendable {
        /// `brew upgrade` will install it
        case homebrew
        /// A newer release is on GitHub; this opens its page
        case download(version: String, page: URL)
    }

    @Published public private(set) var available: Update?
    @Published public private(set) var isChecking = false
    @Published public private(set) var isUpdating = false
    /// Set when a check couldn't finish, e.g. no internet connection
    @Published public private(set) var lastError: String?

    public var updateAvailable: Bool { available != nil }

    private let app: AppInfo

    public init(app: AppInfo) {
        self.app = app
    }

    /// Whether the app was installed with Homebrew, so Homebrew can update it
    public var isManagedByHomebrew: Bool {
        guard let brew = Brew.path else { return false }
        let prefix = ((brew as NSString).deletingLastPathComponent as NSString).deletingLastPathComponent
        return FileManager.default.fileExists(atPath: "\(prefix)/Caskroom/\(app.cask)")
    }

    /// A quick check on launch. It only reads Homebrew's local index, so it
    /// makes no network request; installs not from Homebrew skip it.
    public func checkSilent() async {
        guard isManagedByHomebrew else { return }
        let result = await Brew.run(["outdated", "--cask", app.caskFullName])
        available = listsSelf(result.output) ? .homebrew : nil
    }

    /// "Check for updates": fetches Homebrew's latest index, or asks GitHub
    /// for the latest release when the app wasn't installed with Homebrew
    public func check() async {
        isChecking = true
        lastError = nil
        defer { isChecking = false }
        if isManagedByHomebrew {
            _ = await Brew.run(["update"], timeout: 60)
            let result = await Brew.run(["outdated", "--cask", app.caskFullName])
            available = listsSelf(result.output) ? .homebrew : nil
        } else {
            do {
                available = try await latestRelease()
            } catch {
                lastError = "Couldn't reach GitHub to check. Try again later."
            }
        }
    }

    public func update() async {
        switch available {
        case .homebrew:
            isUpdating = true
            guard launchDetachedUpgrade() else {
                isUpdating = false
                lastError = "Couldn't start the update."
                return
            }
            NSApp.terminate(nil)
        case .download(_, let page):
            NSWorkspace.shared.open(page)
        case nil:
            break
        }
    }

    private func listsSelf(_ output: String) -> Bool {
        output.split(separator: "\n").contains {
            let line = $0.trimmingCharacters(in: .whitespaces)
            return line == app.cask || line == app.caskFullName
        }
    }

    // MARK: - GitHub

    private struct Release: Decodable {
        let tag_name: String
        let html_url: URL
        let draft: Bool
        let prerelease: Bool
    }

    private func latestRelease() async throws -> Update? {
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/RossNicholson/\(app.repo)/releases/latest")!)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 20
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        let release = try JSONDecoder().decode(Release.self, from: data)
        guard !release.draft, !release.prerelease else { return nil }
        let latest = release.tag_name.hasPrefix("v") ? String(release.tag_name.dropFirst()) : release.tag_name
        return Self.isNewer(latest, than: app.version) ? .download(version: latest, page: release.html_url) : nil
    }

    /// Compares dotted version numbers: 1.10.0 is newer than 1.9.2
    nonisolated static func isNewer(_ candidate: String, than current: String) -> Bool {
        let a = candidate.split(separator: ".").map { Int($0) ?? 0 }
        let b = current.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0
            let y = i < b.count ? b[i] : 0
            if x != y { return x > y }
        }
        return false
    }

    // MARK: - Homebrew upgrade

    /// An app can't upgrade itself from a `brew` child process: the cask's
    /// `uninstall quit:` closes the app mid-upgrade, which kills the child
    /// brew and leaves the app closed and not updated. Hand the work to a
    /// detached script that waits for the app to quit, upgrades, then reopens it.
    private func launchDetachedUpgrade() -> Bool {
        guard let brew = Brew.path else { return false }
        let fm = FileManager.default
        guard let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return false
        }
        let dir = support.appendingPathComponent(app.name, isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        let scriptURL = dir.appendingPathComponent("self-update.sh")
        let logURL = dir.appendingPathComponent("self-update.log")

        let pid = ProcessInfo.processInfo.processIdentifier
        let appPath = Bundle.main.bundlePath
        let bundleID = Bundle.main.bundleIdentifier ?? ""

        // `$(...)`, `$LOG` and `$status` are shell; only `\(...)` is Swift.
        let script = """
        #!/bin/sh
        export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        export HOMEBREW_NO_AUTO_UPDATE=1
        LOG="\(logURL.path)"
        : > "$LOG"
        echo "[$(date)] waiting for \(app.name) (pid \(pid)) to quit" >> "$LOG"
        for i in $(seq 1 60); do
            kill -0 \(pid) 2>/dev/null || break
            sleep 0.5
        done
        echo "[$(date)] running brew upgrade --cask \(app.caskFullName)" >> "$LOG"
        "\(brew)" upgrade --cask \(app.caskFullName) >> "$LOG" 2>&1
        status=$?
        echo "[$(date)] brew exited with status $status" >> "$LOG"
        if [ "$status" -ne 0 ]; then
            osascript -e 'display notification "Update failed. See \(logURL.path)" with title "\(app.name)"' >/dev/null 2>&1 || true
        fi
        open -b "\(bundleID)" || open "\(appPath)"
        """
        do {
            try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        } catch {
            return false
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [scriptURL.path]
        // Detached stdio: a broken pipe to this (quitting) process must not stop it
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            return true
        } catch {
            return false
        }
    }
}

/// Runs `brew` with a usable environment, for the updater
enum Brew {
    static let path: String? = ["/opt/homebrew/bin/brew", "/usr/local/bin/brew"]
        .first { FileManager.default.isExecutableFile(atPath: $0) }

    struct Result: Sendable {
        let output: String
        let exitCode: Int32
    }

    /// A Finder-launched app gets a minimal environment; give brew a usable
    /// PATH and turn off its implicit auto-update so checks stay quick.
    private static let environment: [String: String] = {
        var env = ProcessInfo.processInfo.environment
        let prefix = path.map { ($0 as NSString).deletingLastPathComponent } ?? "/opt/homebrew/bin"
        env["PATH"] = "\(prefix):/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin" + (env["PATH"].map { ":\($0)" } ?? "")
        if env["HOME"] == nil { env["HOME"] = NSHomeDirectory() }
        env["HOMEBREW_NO_AUTO_UPDATE"] = "1"
        env["HOMEBREW_NO_ENV_HINTS"] = "1"
        return env
    }()

    static func run(_ args: [String], timeout: TimeInterval = 30) async -> Result {
        guard let path else { return Result(output: "", exitCode: 127) }
        return await withCheckedContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = args
            process.environment = environment
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice
            do {
                try process.run()
            } catch {
                continuation.resume(returning: Result(output: "", exitCode: 1))
                return
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                if process.isRunning { process.terminate() }
            }
            // Read while brew runs, so large output can't fill the pipe and stall it
            DispatchQueue.global().async {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                continuation.resume(returning: Result(
                    output: String(data: data, encoding: .utf8) ?? "",
                    exitCode: process.terminationStatus
                ))
            }
        }
    }
}
