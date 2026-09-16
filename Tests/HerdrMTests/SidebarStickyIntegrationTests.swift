import AppKit
import SwiftUI
import XCTest
@testable import herdrm

final class SidebarStickyIntegrationTests: XCTestCase {
    @MainActor
    func testSpacesHeaderStaysPinnedWhileScrollingItsBody() throws {
        let frames = StickyProbeFrameStore()
        let host = StickyProbeHost(frames: frames, rowCountPerSection: 40, terminalsVisible: true)
        let window = try host.makeWindow()
        defer { window.close() }

        let scrollView = try host.scrollView(in: window)
        XCTAssertEqual(frames.pinnedMinY(for: .spaces, next: .agents), 0, accuracy: 2)

        scrollView.contentView.scroll(to: NSPoint(x: 0, y: 180))
        scrollView.reflectScrolledClipView(scrollView.contentView)
        host.pump()

        XCTAssertEqual(
            frames.pinnedMinY(for: .spaces, next: .agents),
            0,
            accuracy: 2,
            "spaces header must stay pinned while its body scrolls"
        )
    }

    @MainActor
    func testAgentsHeaderReplacesSpacesAfterTakeover() throws {
        let frames = StickyProbeFrameStore()
        let host = StickyProbeHost(frames: frames, rowCountPerSection: 40, terminalsVisible: true)
        let window = try host.makeWindow()
        defer { window.close() }

        let scrollView = try host.scrollView(in: window)
        let spacesBody = CGFloat(host.rowCountPerSection) * 32
        let pastSpaces =
            SidebarStickyLayout.headerHeight
            + spacesBody
            + SidebarStickyLayout.interSectionGap
            + 40
        scrollView.contentView.scroll(to: NSPoint(x: 0, y: pastSpaces))
        scrollView.reflectScrolledClipView(scrollView.contentView)
        host.pump()

        XCTAssertEqual(
            frames.pinnedMinY(for: .agents, next: .terminals),
            0,
            accuracy: 2,
            "agents should own the pin slot after spaces fully left"
        )
        let agentsNatural = try XCTUnwrap(frames.naturalFrames[.agents]?.minY)
        XCTAssertLessThanOrEqual(
            agentsNatural,
            2,
            "agents header should be at/above the pin slot once spaces list has left"
        )
    }

    @MainActor
    func testSpacesStaysPinnedWhileItsListStillInViewport() throws {
        let frames = StickyProbeFrameStore()
        let host = StickyProbeHost(frames: frames, rowCountPerSection: 40, terminalsVisible: true)
        let window = try host.makeWindow()
        defer { window.close() }

        let scrollView = try host.scrollView(in: window)
        let spacesBody = CGFloat(host.rowCountPerSection) * 32
        // Still inside Spaces — next header has not reached the top yet.
        let stillInSpaces =
            SidebarStickyLayout.headerHeight
            + spacesBody
            + SidebarStickyLayout.interSectionGap
            - 60
        scrollView.contentView.scroll(to: NSPoint(x: 0, y: stillInSpaces))
        scrollView.reflectScrolledClipView(scrollView.contentView)
        host.pump()

        XCTAssertEqual(
            frames.pinnedMinY(for: .spaces, next: .agents),
            0,
            accuracy: 2,
            "spaces must stay pinned until its list fully leaves"
        )
        XCTAssertGreaterThan(
            frames.naturalFrames[.agents]?.minY ?? -1,
            0,
            "agents header should still be below the pin slot"
        )
    }
}
@MainActor
private struct StickyProbeHost {
    let frames: StickyProbeFrameStore
    let rowCountPerSection: Int
    let terminalsVisible: Bool

    func makeWindow() throws -> NSWindow {
        let root = NSHostingView(
            rootView: SidebarStickyProbeStack(
                rowCountPerSection: rowCountPerSection,
                terminalsVisible: terminalsVisible,
                frames: frames
            )
            .frame(width: 260, height: 480)
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentView = root
        window.orderFrontRegardless()
        root.layoutSubtreeIfNeeded()
        pump()
        return window
    }

    func scrollView(in window: NSWindow) throws -> NSScrollView {
        guard let scroll = firstDescendant(of: window.contentView, as: NSScrollView.self) else {
            throw StickyProbeError.missingScrollView
        }
        return scroll
    }

    func pump() {
        for _ in 0..<4 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
            NSApp.windows.forEach { $0.contentView?.layoutSubtreeIfNeeded() }
        }
    }
}

private enum StickyProbeError: Error {
    case missingScrollView
}

@MainActor
private func firstDescendant<T: NSView>(of root: NSView?, as type: T.Type) -> T? {
    guard let root else { return nil }
    if let match = root as? T { return match }
    for child in root.subviews {
        if let found = firstDescendant(of: child, as: type) { return found }
    }
    return nil
}
