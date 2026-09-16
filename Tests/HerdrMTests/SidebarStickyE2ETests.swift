import AppKit
import SwiftUI
import XCTest
@testable import herdrm

final class SidebarStickyE2ETests: XCTestCase {
    @MainActor
    func testProbeExposesSectionHeadersAndScrollSurface() throws {
        let frames = StickyProbeFrameStore()
        let root = NSHostingView(
            rootView: SidebarStickyProbeStack(
                rowCountPerSection: 30,
                terminalsVisible: true,
                frames: frames
            )
            .frame(width: 260, height: 360)
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 360),
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

        XCTAssertEqual(frames.pinnedMinY(for: .spaces, next: .agents), 0, accuracy: 2)

        guard let scroll = findScroll(in: root) else {
            return XCTFail("missing scroll view")
        }

        let spacesBody = CGFloat(30) * 32
        let pastSpaces =
            SidebarStickyLayout.headerHeight
            + spacesBody
            + SidebarStickyLayout.interSectionGap
            + 40
        scroll.contentView.scroll(to: NSPoint(x: 0, y: pastSpaces))
        scroll.reflectScrolledClipView(scroll.contentView)
        pump()

        XCTAssertEqual(
            frames.pinnedMinY(for: .agents, next: .terminals),
            0,
            accuracy: 2,
            "after takeover, Agents should own the pin slot"
        )
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
