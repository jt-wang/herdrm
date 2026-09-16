import AppKit
import SwiftUI
import XCTest
@testable import herdrm

final class SidebarStickyVisualTests: XCTestCase {
    @MainActor
    func testPinnedHeaderBandStableAcrossScroll() throws {
        let frames = StickyProbeFrameStore()
        let root = NSHostingView(
            rootView: SidebarStickyProbeStack(
                rowCountPerSection: 50,
                terminalsVisible: false,
                frames: frames
            )
            .frame(width: 260, height: 420)
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 420),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = root
        window.orderFrontRegardless()
        root.layoutSubtreeIfNeeded()
        pump()
        defer { window.close() }

        let before = frames.pinnedMinY(for: .spaces, next: .agents)
        guard let scroll = findScroll(in: root) else {
            return XCTFail("expected NSScrollView")
        }
        scroll.contentView.scroll(to: NSPoint(x: 0, y: 220))
        scroll.reflectScrolledClipView(scroll.contentView)
        pump()
        let after = frames.pinnedMinY(for: .spaces, next: .agents)

        XCTAssertEqual(before, 0, accuracy: 2)
        XCTAssertEqual(after, before, accuracy: 2, "pinned header Y must not drift mid-section")
    }
}

@MainActor
private func pump() {
    for _ in 0..<4 {
        RunLoop.current.run(until: Date().addingTimeInterval(0.05))
    }
}

@MainActor
private func findScroll(in root: NSView) -> NSScrollView? {
    if let scroll = root as? NSScrollView { return scroll }
    for child in root.subviews {
        if let found = findScroll(in: child) { return found }
    }
    return nil
}
