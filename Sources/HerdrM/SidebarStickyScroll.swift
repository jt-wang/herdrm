import SwiftUI

/// Header frames in the scroll view’s coordinate space (minY moves with scroll).
struct SidebarStickyHeaderFramesKey: PreferenceKey {
    static var defaultValue: [SidebarSectionID: CGRect] = [:]
    static func reduce(
        value: inout [SidebarSectionID: CGRect],
        nextValue: () -> [SidebarSectionID: CGRect]
    ) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    /// Reports this view’s frame in the sidebar sticky scroll coordinate space.
    func reportStickyHeaderFrame(_ id: SidebarSectionID) -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: SidebarStickyHeaderFramesKey.self,
                    value: [id: geo.frame(in: .named(SidebarStickyScroll.coordinateSpaceName))]
                )
            }
        )
    }
}

/// Flow-sticky section headers: the current header pins under the top actions
/// while you scroll its list; the next section’s header pushes it out when that
/// list has left the viewport (classic sticky push — continuous, no snap).
enum SidebarStickyScroll {
    static let coordinateSpaceName = "sidebar.sticky.scroll"

    /// Pin Y for a header given its natural minY and the next header’s minY
    /// (both in scroll coordinates).
    static func pinnedMinY(
        naturalMinY: CGFloat,
        nextNaturalMinY: CGFloat?,
        headerHeight: CGFloat = SidebarStickyLayout.headerHeight
    ) -> CGFloat {
        let floored = max(naturalMinY, 0)
        guard let next = nextNaturalMinY else { return floored }
        return min(floored, next - headerHeight)
    }
}
