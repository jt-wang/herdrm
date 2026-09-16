import AppKit
import XCTest
@testable import herdrm

final class SidebarStickyLayoutUnitTests: XCTestCase {
    func testVisibleSectionsOmitTerminalsWhenHidden() {
        XCTAssertEqual(
            SidebarStickyLayout.visibleSections(terminalsVisible: false),
            [.spaces, .agents]
        )
    }

    func testVisibleSectionsIncludeTerminalsWhenShown() {
        XCTAssertEqual(
            SidebarStickyLayout.visibleSections(terminalsVisible: true),
            [.spaces, .agents, .terminals]
        )
    }

    func testPinnedSectionStaysOnSpacesUntilAgentsHeaderReachesTop() {
        let bodies: [SidebarSectionID: CGFloat] = [
            .spaces: 400,
            .agents: 400,
            .terminals: 200,
        ]
        let takeover = SidebarStickyLayout.headerHeight + 400 + SidebarStickyLayout.interSectionGap

        XCTAssertEqual(
            SidebarStickyLayout.pinnedSection(
                scrollOffsetY: 0,
                sectionBodyHeights: bodies,
                terminalsVisible: true
            ),
            .spaces
        )
        XCTAssertEqual(
            SidebarStickyLayout.pinnedSection(
                scrollOffsetY: takeover - 1,
                sectionBodyHeights: bodies,
                terminalsVisible: true
            ),
            .spaces
        )
        XCTAssertEqual(
            SidebarStickyLayout.pinnedSection(
                scrollOffsetY: takeover,
                sectionBodyHeights: bodies,
                terminalsVisible: true
            ),
            .agents
        )
    }

    func testPinnedSectionHandsOffAgentsToTerminals() {
        let bodies: [SidebarSectionID: CGFloat] = [
            .spaces: 100,
            .agents: 100,
            .terminals: 100,
        ]
        let spacesSpan = SidebarStickyLayout.headerHeight + 100 + SidebarStickyLayout.interSectionGap
        let agentsSpan = SidebarStickyLayout.headerHeight + 100 + SidebarStickyLayout.interSectionGap
        let terminalsTakeover = spacesSpan + agentsSpan

        XCTAssertEqual(
            SidebarStickyLayout.pinnedSection(
                scrollOffsetY: terminalsTakeover - 1,
                sectionBodyHeights: bodies,
                terminalsVisible: true
            ),
            .agents
        )
        XCTAssertEqual(
            SidebarStickyLayout.pinnedSection(
                scrollOffsetY: terminalsTakeover,
                sectionBodyHeights: bodies,
                terminalsVisible: true
            ),
            .terminals
        )
    }
}

final class SidebarStickyContractTests: XCTestCase {
    func testContinuousPushStickyContract() {
        XCTAssertTrue(SidebarStickyLayout.pinsSectionHeaders)
        XCTAssertTrue(SidebarStickyLayout.usesContinuousPushSticky)
        XCTAssertFalse(SidebarStickyLayout.usesSectionBoundarySticky)
    }

    func testPinnedMinYFollowsContentBeforeReachingTop() {
        XCTAssertEqual(
            SidebarStickyScroll.pinnedMinY(naturalMinY: 120, nextNaturalMinY: 400),
            120,
            accuracy: 0.001
        )
    }

    func testPinnedMinYStaysAtTopUntilNextHeaderPushes() {
        XCTAssertEqual(
            SidebarStickyScroll.pinnedMinY(naturalMinY: -80, nextNaturalMinY: 200),
            0,
            accuracy: 0.001
        )
        // Next header 20pt below clip top → current is pushed 8pt up (28 − 20).
        XCTAssertEqual(
            SidebarStickyScroll.pinnedMinY(naturalMinY: -100, nextNaturalMinY: 20),
            -8,
            accuracy: 0.001
        )
    }

    func testPinnedMinYPushIsContinuous() {
        var previous = SidebarStickyScroll.pinnedMinY(naturalMinY: -1_000, nextNaturalMinY: 28)
        for next in stride(from: 27, through: 0, by: -1) {
            let pinned = SidebarStickyScroll.pinnedMinY(
                naturalMinY: -1_000,
                nextNaturalMinY: CGFloat(next)
            )
            XCTAssertEqual(
                abs(pinned - previous),
                1,
                accuracy: 0.001,
                "push should move 1pt when the next header moves 1pt"
            )
            previous = pinned
        }
    }

    func testAccessibilityIdentifiersAreStable() {
        XCTAssertEqual(SidebarSectionID.spaces.accessibilityIdentifier, "sidebar.section.spaces")
        XCTAssertEqual(SidebarSectionID.agents.accessibilityIdentifier, "sidebar.section.agents")
        XCTAssertEqual(SidebarSectionID.terminals.accessibilityIdentifier, "sidebar.section.terminals")
    }

    func testHeaderAndGapConstantsMatchSidebarChrome() {
        XCTAssertEqual(SidebarStickyLayout.headerHeight, 28)
        XCTAssertEqual(SidebarStickyLayout.interSectionGap, 10)
    }
}
