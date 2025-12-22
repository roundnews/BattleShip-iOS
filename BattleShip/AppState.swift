import SwiftUI

@MainActor
final class AppState: ObservableObject {

    enum Screen {
        case placement
        case battle
    }

    // Navigation
    @Published var screen: Screen = .placement

    // Placement UI state
    @Published var selectedShip: ShipType = .battleship
    @Published var orientation: Orientation = .horizontal
    @Published var placedShips: Set<ShipType> = []

    // Placement: tap once preview, tap again place
    @Published var pendingOrigin: Coord? = nil
    @Published var hoverCells: Set<Coord> = []
    @Published var hoverIsValid: Bool = true

    // Board marks (UI-only for now)
    @Published var playerMarks: [Coord: CellMark] = [:]
    @Published var enemyMarks:  [Coord: CellMark] = [:]

    // Optional sunk highlight sets (UI-only)
    @Published var playerSunkCells: Set<Coord> = []
    @Published var enemySunkCells:  Set<Coord> = []

    // Battle state (UI-only placeholder)
    @Published var isPlayerTurn: Bool = true
    @Published var shotsCount: Int = 0

    func resetAll() {
        screen = .placement

        selectedShip = .battleship
        orientation = .horizontal
        placedShips = []

        pendingOrigin = nil
        hoverCells = []
        hoverIsValid = true

        playerMarks = [:]
        enemyMarks = [:]
        playerSunkCells = []
        enemySunkCells = []

        isPlayerTurn = true
        shotsCount = 0
    }
}
