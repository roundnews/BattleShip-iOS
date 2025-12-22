import SwiftUI

enum LabelsStyle {
    case none
    case placement
    case battleTop
    case battleBottom
}

enum GridAxis {
    static let cols = Array("ABCDEFGH").map(String.init) // A..H
    static let rows = (1...8).map(String.init)           // 1..8 (top-down)
}

struct AxisLabelsView: View {
    let cell: CGFloat
    let style: LabelsStyle

    var body: some View {
        ZStack(alignment: .topLeading) {
            if showsRowLabels {
                VStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { r in
                        Text(GridAxis.rows[r]) // 1 at top, 8 at bottom
                            .font(.caption2)
                            .frame(width: 18, height: cell)
                            .minimumScaleFactor(0.6)
                    }
                }
                .offset(x: 0, y: topGutter)
            }

            if showsTopColLabels {
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { c in
                        Text(GridAxis.cols[c])
                            .font(.caption2)
                            .frame(width: cell, height: 18)
                            .minimumScaleFactor(0.6)
                    }
                }
                .offset(x: leftGutter, y: 0)
            }

            if showsBottomColLabels {
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { c in
                        Text(GridAxis.cols[c])
                            .font(.caption2)
                            .frame(width: cell, height: 18)
                            .minimumScaleFactor(0.6)
                    }
                }
                .offset(x: leftGutter, y: topGutter + cell * 8)
            }
        }
    }

    // Gutters (space reserved for labels)
    var leftGutter: CGFloat { showsRowLabels ? 18 : 0 }
    var topGutter: CGFloat { showsTopColLabels ? 18 : 0 }
    var bottomGutter: CGFloat { showsBottomColLabels ? 18 : 0 }

    private var showsRowLabels: Bool {
        switch style {
        case .none: return false
        case .placement, .battleTop, .battleBottom: return true
        }
    }

    private var showsTopColLabels: Bool {
        style == .placement
    }

    private var showsBottomColLabels: Bool {
        style == .battleTop
    }
}
