import SwiftUI
@testable import herdrm

/// Shared frame sink for sticky-header probes.
@MainActor
final class StickyProbeFrameStore: ObservableObject {
    /// Header frames in the scroll clip coordinate space (move with scroll).
    var naturalFrames: [SidebarSectionID: CGRect] = [:]

    func pinnedMinY(for id: SidebarSectionID, next: SidebarSectionID?) -> CGFloat {
        let natural = naturalFrames[id]?.minY ?? 0
        let nextY = next.flatMap { naturalFrames[$0]?.minY }
        return SidebarStickyScroll.pinnedMinY(naturalMinY: natural, nextNaturalMinY: nextY)
    }
}

/// Probe stack mirroring production continuous-push sticky headers.
struct SidebarStickyProbeStack: View {
    let rowCountPerSection: Int
    let terminalsVisible: Bool
    var rowHeight: CGFloat = 32
    @ObservedObject var frames: StickyProbeFrameStore
    @State private var localNatural: [SidebarSectionID: CGRect] = [:]

    var body: some View {
        let sections = SidebarStickyLayout.visibleSections(terminalsVisible: terminalsVisible)
        ScrollView {
            VStack(spacing: 1) {
                ForEach(Array(sections.enumerated()), id: \.element) { index, section in
                    let next = index + 1 < sections.count ? sections[index + 1] : nil
                    probeHeader(section, next: next)
                    ForEach(0..<rowCountPerSection, id: \.self) { row in
                        Text("\(section.rawValue)-row-\(row)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: rowHeight)
                    }
                    if index + 1 < sections.count {
                        Color.clear.frame(height: SidebarStickyLayout.interSectionGap)
                    }
                }
            }
            .padding(.horizontal, 10)
        }
        .coordinateSpace(name: SidebarStickyScroll.coordinateSpaceName)
        .onPreferenceChange(SidebarStickyHeaderFramesKey.self) { value in
            localNatural = value
            frames.naturalFrames = value
        }
        .accessibilityIdentifier("sidebar.sticky.probe.scroll")
    }

    @ViewBuilder
    private func probeHeader(_ section: SidebarSectionID, next: SidebarSectionID?) -> some View {
        let natural = localNatural[section]?.minY ?? 0
        let nextY = next.flatMap { localNatural[$0]?.minY }
        let pinned = SidebarStickyScroll.pinnedMinY(naturalMinY: natural, nextNaturalMinY: nextY)
        Text(section.title)
            .font(.system(size: 12.5, weight: .medium))
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: SidebarStickyLayout.headerHeight)
            .padding(.horizontal, 8)
            .background(.regularMaterial)
            .reportStickyHeaderFrame(section)
            .offset(y: pinned - natural)
            .zIndex(10)
            .accessibilityIdentifier(section.accessibilityIdentifier)
    }
}
