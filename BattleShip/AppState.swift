import SwiftUI
import Combine
import os
import UniformTypeIdentifiers

private extension Array where Element == Int {
    func chunked(_ size: Int) -> [[Int]] {
        guard size > 0 else { return [] }
        var res: [[Int]] = []
        var idx = 0
        while idx < count {
            let end = Swift.min(idx + size, count)
            res.append(Array(self[idx..<end]))
            idx = end
        }
        return res
    }
}

@MainActor
final class AppState: ObservableObject {

    enum Screen {
        case placement
        case battle
    }

    // MARK: - Game Model
    struct PlacedShip: Identifiable, Hashable {
        let id = UUID()
        let type: ShipType
        let cells: [Coord] // contiguous cells occupied by ship
        var hits: Set<Coord> = []

        var isSunk: Bool { Set(cells).isSubset(of: hits) }
    }

    struct Board {
        var ships: [PlacedShip] = []
        var shots: Set<Coord> = [] // cells that have been fired upon

        func ship(at coord: Coord) -> PlacedShip? {
            ships.first { $0.cells.contains(coord) }
        }

        var allShipCells: Set<Coord> { Set(ships.flatMap { $0.cells }) }
    }

    // MARK: - Persistence
    struct SaveState: Codable {
        let screen: String
        let playerShips: [[Int]] // flattened coords row,col pairs per ship
        let playerShipTypes: [String]
        let playerShipHits: [[Int]]
        let enemyShips: [[Int]]
        let enemyShipTypes: [String]
        let enemyShipHits: [[Int]]
        let enemyShots: [[Int]]
        let playerShots: [[Int]]
        let isPlayerTurn: Bool
        let shotsCount: Int
        let playerWon: Bool
        let enemyWon: Bool
    }

    private let saveURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("battleship.save", conformingTo: .data)
    }()

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

    // Board marks for UI
    @Published var playerMarks: [Coord: CellMark] = [:]
    @Published var enemyMarks:  [Coord: CellMark] = [:]

    // Sunk highlight sets for UI
    @Published var playerSunkCells: Set<Coord> = []
    @Published var enemySunkCells:  Set<Coord> = []

    // Battle state
    @Published var isPlayerTurn: Bool = true
    @Published var shotsCount: Int = 0
    @Published var playerWon: Bool = false
    @Published var enemyWon: Bool = false

    // Internal boards
    private var playerBoard = Board()
    private var enemyBoard = Board()

    // MARK: - Lifecycle
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
        playerWon = false
        enemyWon = false

        playerBoard = Board()
        enemyBoard = Board()
        // We'll auto-place enemy when battle starts
        save()
    }

    // MARK: - Placement
    func canPlace(ship: ShipType, at origin: Coord, orientation: Orientation) -> [Coord]? {
        let cells = cellsFor(ship: ship, origin: origin, orientation: orientation)
        // bounds
        guard cells.allSatisfy({ (0..<8).contains($0.row) && (0..<8).contains($0.col) }) else { return nil }
        // overlap with existing player ships
        let occupied = Set(playerBoard.allShipCells)
        guard cells.allSatisfy({ !occupied.contains($0) }) else { return nil }
        return cells
    }

    func previewPlacement(at coord: Coord) {
        guard let cells = canPlace(ship: selectedShip, at: coord, orientation: orientation) else {
            pendingOrigin = coord
            hoverCells = Set(cellsFor(ship: selectedShip, origin: coord, orientation: orientation))
            hoverIsValid = false
            return
        }
        pendingOrigin = coord
        hoverCells = Set(cells)
        hoverIsValid = true
    }

    func commitPlacementPreview() {
        guard let origin = pendingOrigin,
              let cells = canPlace(ship: selectedShip, at: origin, orientation: orientation) else { return }

        // Update model
        let new = PlacedShip(type: selectedShip, cells: cells, hits: [])
        playerBoard.ships.append(new)
        placedShips.insert(selectedShip)

        // Update UI marks
        for c in cells { playerMarks[c] = .ship }

        // Clear preview
        pendingOrigin = nil
        hoverCells = []
        hoverIsValid = true

        // Auto-advance selection
        if let next = ShipType.allCases.first(where: { !placedShips.contains($0) }) {
            selectedShip = next
        }
        save()
    }

    func autoPlaceEnemy() {
        enemyBoard = Board()
        var rng = SystemRandomNumberGenerator()
        for type in ShipType.allCases {
            var placed = false
            var attempts = 0
            while !placed && attempts < 500 {
                attempts += 1
                let orientation: Orientation = Bool.random(using: &rng) ? .horizontal : .vertical
                let maxRow = orientation == .horizontal ? 7 : 8 - type.length
                let maxCol = orientation == .vertical ? 7 : 8 - type.length
                let row = Int.random(in: 0...maxRow, using: &rng)
                let col = Int.random(in: 0...maxCol, using: &rng)
                let origin = Coord(row: row, col: col)
                let cells = cellsFor(ship: type, origin: origin, orientation: orientation)
                // Check overlap
                let occupied = Set(enemyBoard.allShipCells)
                if cells.allSatisfy({ !occupied.contains($0) }) {
                    let ship = PlacedShip(type: type, cells: cells, hits: [])
                    enemyBoard.ships.append(ship)
                    placed = true
                }
            }
        }
        save()
    }

    func autoPlacePlayer(clearExisting: Bool = true) {
        if clearExisting {
            playerBoard = Board()
            playerMarks = [:]
            placedShips = []
        }
        var rng = SystemRandomNumberGenerator()
        for type in ShipType.allCases {
            var placed = false
            var attempts = 0
            while !placed && attempts < 500 {
                attempts += 1
                let orientation: Orientation = Bool.random(using: &rng) ? .horizontal : .vertical
                let maxRow = orientation == .horizontal ? 7 : 8 - type.length
                let maxCol = orientation == .vertical ? 7 : 8 - type.length
                let row = Int.random(in: 0...maxRow, using: &rng)
                let col = Int.random(in: 0...maxCol, using: &rng)
                let origin = Coord(row: row, col: col)
                let cells = cellsFor(ship: type, origin: origin, orientation: orientation)
                let occupied = Set(playerBoard.allShipCells)
                if cells.allSatisfy({ !occupied.contains($0) }) {
                    let ship = PlacedShip(type: type, cells: cells, hits: [])
                    playerBoard.ships.append(ship)
                    for c in cells { playerMarks[c] = .ship }
                    placedShips.insert(type)
                    placed = true
                }
            }
        }
        // clear preview state
        pendingOrigin = nil
        hoverCells = []
        hoverIsValid = true
        selectedShip = ShipType.allCases.first(where: { !placedShips.contains($0) }) ?? .battleship
        save()
    }

    // MARK: - Battle
    func startBattle() {
        // Ensure enemy is placed
        autoPlaceEnemy()
        // Sync UI for player ships
        playerMarks = [:]
        for ship in playerBoard.ships { for c in ship.cells { playerMarks[c] = .ship } }
        playerSunkCells = []

        // Clear enemy UI
        enemyMarks = [:]
        enemySunkCells = []

        isPlayerTurn = true
        shotsCount = 0
        playerWon = false
        enemyWon = false

        screen = .battle
    }

    func fire(at coord: Coord) {
        guard screen == .battle, isPlayerTurn, !playerWon, !enemyWon else { return }
        guard enemyMarks[coord] == nil else { return } // no repeat

        shotsCount += 1
        enemyBoard.shots.insert(coord)

        if let idx = enemyBoard.ships.firstIndex(where: { $0.cells.contains(coord) }) {
            // hit
            enemyBoard.ships[idx].hits.insert(coord)
            enemyMarks[coord] = .hit
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            // sunk?
            if enemyBoard.ships[idx].isSunk {
                let cells = enemyBoard.ships[idx].cells
                for c in cells { enemyMarks[c] = .sunk }
                enemySunkCells.formUnion(cells)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } else {
            enemyMarks[coord] = .miss
        }

        // victory?
        if enemyBoard.ships.allSatisfy({ $0.isSunk }) {
            playerWon = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            save()
            return
        }

        save()

        // Enemy turn (very simple AI)
        isPlayerTurn = false
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 400_000_000)
            enemyAIFire()
            isPlayerTurn = true
        }
    }

    private func enemyAIFire() {
        // naive random untargeted AI
        var rng = SystemRandomNumberGenerator()
        var target: Coord
        var attempts = 0
        repeat {
            attempts += 1
            target = Coord(row: Int.random(in: 0...7, using: &rng),
                           col: Int.random(in: 0...7, using: &rng))
        } while playerBoard.shots.contains(target) && attempts < 300

        playerBoard.shots.insert(target)

        // record
        if let pIdx = playerBoard.ships.firstIndex(where: { $0.cells.contains(target) }) {
            playerBoard.ships[pIdx].hits.insert(target)
            playerMarks[target] = .hit
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            if playerBoard.ships[pIdx].isSunk {
                let cells = playerBoard.ships[pIdx].cells
                for c in cells { playerMarks[c] = .sunk }
                playerSunkCells.formUnion(cells)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        } else {
            // only mark a miss if not already a ship cell (to preserve ship tint)
            if playerMarks[target] == nil { playerMarks[target] = .miss }
        }

        // defeat?
        if playerBoard.ships.allSatisfy({ $0.isSunk }) {
            enemyWon = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }

        save()
    }

    // MARK: - Persistence API
    func save() {
        do {
            let payload = try makeSaveState()
            let data = try JSONEncoder().encode(payload)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            os_log("Save failed: %{public}@", String(describing: error))
        }
    }

    func loadIfAvailable() {
        do {
            let data = try Data(contentsOf: saveURL)
            let payload = try JSONDecoder().decode(SaveState.self, from: data)
            try restore(from: payload)
            // Ensure UI state is consistent after load
            rebuildUIMarks()
        } catch {
            // no-op on first launch or decode failure
        }
    }

    private func makeSaveState() throws -> SaveState {
        func flatten(_ ship: PlacedShip) -> [Int] { ship.cells.flatMap { [$0.row, $0.col] } }
        func flattenSet(_ set: Set<Coord>) -> [Int] { set.flatMap { [$0.row, $0.col] } }

        let pShips = playerBoard.ships.map { flatten($0) }
        let pTypes = playerBoard.ships.map { $0.type.name }
        let pHits  = playerBoard.ships.map { flattenSet($0.hits) }

        let eShips = enemyBoard.ships.map { flatten($0) }
        let eTypes = enemyBoard.ships.map { $0.type.name }
        let eHits  = enemyBoard.ships.map { flattenSet($0.hits) }

        let eShots = Array(enemyBoard.shots).flatMap { [$0.row, $0.col] }
        let pShots = Array(playerBoard.shots).flatMap { [$0.row, $0.col] }

        return SaveState(
            screen: screen == .battle ? "battle" : "placement",
            playerShips: pShips,
            playerShipTypes: pTypes,
            playerShipHits: pHits,
            enemyShips: eShips,
            enemyShipTypes: eTypes,
            enemyShipHits: eHits,
            enemyShots: eShots.chunked(2),
            playerShots: pShots.chunked(2),
            isPlayerTurn: isPlayerTurn,
            shotsCount: shotsCount,
            playerWon: playerWon,
            enemyWon: enemyWon
        )
    }

    private func restore(from save: SaveState) throws {
        func toCoords(_ flat: [Int]) -> [Coord] {
            stride(from: 0, to: flat.count, by: 2).map { i in Coord(row: flat[i], col: flat[i+1]) }
        }
        func type(from name: String) -> ShipType {
            ShipType.allCases.first { $0.name == name } ?? .battleship
        }

        screen = (save.screen == "battle") ? .battle : .placement

        playerBoard = Board()
        for (idx, flat) in save.playerShips.enumerated() {
            let cells = toCoords(flat)
            let ship = PlacedShip(type: type(from: save.playerShipTypes[idx]), cells: cells, hits: Set(toCoords(save.playerShipHits[idx])))
            playerBoard.ships.append(ship)
        }

        enemyBoard = Board()
        for (idx, flat) in save.enemyShips.enumerated() {
            let cells = toCoords(flat)
            let ship = PlacedShip(type: type(from: save.enemyShipTypes[idx]), cells: cells, hits: Set(toCoords(save.enemyShipHits[idx])))
            enemyBoard.ships.append(ship)
        }
        enemyBoard.shots = Set(save.enemyShots.map { Coord(row: $0[0], col: $0[1]) })
        playerBoard.shots = Set(save.playerShots.map { Coord(row: $0[0], col: $0[1]) })

        isPlayerTurn = save.isPlayerTurn
        shotsCount = save.shotsCount
        playerWon = save.playerWon
        enemyWon = save.enemyWon

        // Rebuild UI marks
        rebuildUIMarks()
    }

    private func rebuildUIMarks() {
        playerMarks = [:]
        enemyMarks = [:]
        playerSunkCells = []
        enemySunkCells = []

        for ship in playerBoard.ships {
            for c in ship.cells { playerMarks[c] = .ship }
            if ship.isSunk { playerSunkCells.formUnion(ship.cells) }
            for h in ship.hits { playerMarks[h] = .hit }
        }
        for s in playerSunkCells { playerMarks[s] = .sunk }

        for ship in enemyBoard.ships {
            if ship.isSunk { enemySunkCells.formUnion(ship.cells) }
            for h in ship.hits { enemyMarks[h] = .hit }
        }
        for s in enemySunkCells { enemyMarks[s] = .sunk }
        for m in enemyBoard.shots where enemyMarks[m] == nil { enemyMarks[m] = .miss }
    }

    // MARK: - Helpers
    func cellsFor(ship: ShipType, origin: Coord, orientation: Orientation) -> [Coord] {
        (0..<ship.length).map { i in
            switch orientation {
            case .horizontal: return Coord(row: origin.row, col: origin.col + i)
            case .vertical:   return Coord(row: origin.row + i, col: origin.col)
            }
        }
    }
}

