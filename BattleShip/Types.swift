import SwiftUI

// MARK: - Coordinate

struct Coord: Hashable, Equatable {
    let row: Int   // 0..7 (0 is top)
    let col: Int   // 0..7
}

// MARK: - Ships

enum ShipType: CaseIterable, Identifiable {
    case battleship, cruiser, destroyer, submarine

    var id: String { name }

    var name: String {
        switch self {
        case .battleship: return "Battleship"
        case .cruiser:    return "Cruiser"
        case .destroyer:  return "Destroyer"
        case .submarine:  return "Submarine"
        }
    }

    var length: Int {
        switch self {
        case .battleship: return 4
        case .cruiser:    return 3
        case .destroyer:  return 2
        case .submarine:  return 1
        }
    }
}

enum Orientation: String {
    case horizontal = "H"
    case vertical   = "V"

    mutating func toggle() {
        self = (self == .horizontal) ? .vertical : .horizontal
    }
}

// MARK: - Cell state for rendering

enum CellMark {
    case empty
    case ship
    case miss
    case hit
    case sunk
}
