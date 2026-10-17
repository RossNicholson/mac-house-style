import AppKit
import Testing
@testable import HouseStyle

@Test func bundledFontsRegister() {
    _ = AppFonts.registered
    for name in AppFonts.names {
        #expect(NSFont(name: name, size: 12) != nil, "\(name) should be available")
    }
}

@Test func versionComparison() {
    #expect(SelfUpdater.isNewer("1.0.1", than: "1.0.0"))
    #expect(SelfUpdater.isNewer("1.10.0", than: "1.9.2"))
    #expect(SelfUpdater.isNewer("2", than: "1.9.9"))
    #expect(!SelfUpdater.isNewer("1.0.0", than: "1.0.0"))
    #expect(!SelfUpdater.isNewer("1.0", than: "1.0.0"))
    #expect(!SelfUpdater.isNewer("1.4.1", than: "1.4.2"))
}
