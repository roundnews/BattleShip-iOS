import SwiftUI

struct FleetGridView: View {
    let title: String
    let marks: [Coord: CellMark]
    let sunkCells: Set<Coord>

    let hoverCells: Set<Coord>
    let hoverValid: Bool

    let isInteractive: Bool
    let labelsStyle: LabelsStyle
    let onTap: (Coord) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .padding(.leading, 6)

            GeometryReader { geo in
                let available = min(geo.size.width, geo.size.height)

                // Determine label gutters
                let labelProbe = AxisLabelsView(cell: 1, style: labelsStyle)
                let left = labelProbe.leftGutter
                let top = labelProbe.topGutter
                let bottom = labelProbe.bottomGutter

                // Ensure square grid area
                let gridSize = available - left - top - bottom
                let cell = gridSize / 8.0

                ZStack(alignment: .topLeading) {
                    if labelsStyle != .none {
                        AxisLabelsView(cell: cell, style: labelsStyle)
                            .frame(width: left + gridSize,
                                   height: top + gridSize + bottom,
                                   alignment: .topLeading)
                    }

                    GridCoreView(
                        gridSize: gridSize,
                        cell: cell,
                        marks: marks,
                        sunkCells: sunkCells,
                        hoverCells: hoverCells,
                        hoverValid: hoverValid,
                        isInteractive: isInteractive,
                        onTap: onTap
                    )
                    .frame(width: gridSize, height: gridSize)
                    .offset(x: left, y: top)
                }
                .frame(width: left + gridSize,
                       height: top + gridSize + bottom,
                       alignment: .topLeading)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

private struct GridCoreView: View {
    let gridSize: CGFloat
    let cell: CGFloat
    let marks: [Coord: CellMark]
    let sunkCells: Set<Coord>
    let hoverCells: Set<Coord>
    let hoverValid: Bool
    let isInteractive: Bool
    let onTap: (Coord) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))

            VStack(spacing: 0) {
                // IMPORTANT: top row is row 0 (top-down)
                ForEach(0..<8, id: \.self) { r in
                    HStack(spacing: 0) {
                        ForEach(0..<8, id: \.self) { c in
                            let coord = Coord(row: r, col: c)
                            CellView(
                                size: cell,
                                mark: markFor(coord),
                                isHover: hoverCells.contains(coord),
                                hoverValid: hoverValid
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if isInteractive { onTap(coord) }
                            }
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))

            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        }
    }

    private func markFor(_ coord: Coord) -> CellMark {
        if sunkCells.contains(coord) { return .sunk }
        return marks[coord] ?? .empty
    }
}
