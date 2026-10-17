import AppKit
import Testing
@testable import HouseStyle

@Test func bundledFontsRegister() {
    _ = AppFonts.registered
    for name in AppFonts.names {
        #expect(NSFont(name: name, size: 12) != nil, "\(name) should be available")
    }
}
