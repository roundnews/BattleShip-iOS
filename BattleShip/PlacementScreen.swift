import SwiftUI

struct PlacementScreen: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(spacing: 12) {
            header

            FleetGridView(
                title: "Your Fleet",
                marks: state.playerMarks,
                sunkCells: state.playerSunkCells,
                hoverCells: state.hoverCells,
                hoverValid: state.hoverIsValid,
                isInteractive: true,
                labelsStyle: .placement, // rows-left + cols-top
                onTap: { coord in handlePlacementTap(coord) }
            )
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 8)

            PlacementControlsView(state: state)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
        .padding(.top, 8)
        .background(Color(.systemGroupedBackground))
    }

    private var header: some View {
        HStack {
            Text("Place your ships")
                .font(.headline)
            Spacer()
            Button("Reset") { state.resetAll() }
        }
        .padding(.horizontal)
    }

    private func handlePlacementTap(_ coord: Coord) {
        // Second tap on same origin places (if valid)
        if state.pendingOrigin == coord,
           state.hoverIsValid,
           !state.hoverCells.isEmpty {
            commitPendingPlacement()
            return
        }

        // First tap (or different origin): update preview
        let cells = cellsFor(ship: state.selectedShip, origin: coord, orientation: state.orientation)
        let valid = validatePlacement(cells: cells)

        state.pendingOrigin = coord
        state.hoverCells = Set(cells)
        state.hoverIsValid = valid
    }

    private func commitPendingPlacement() {
        for c in state.hoverCells {
            state.playerMarks[c] = .ship
        }
        state.placedShips.insert(state.selectedShip)

        // Clear preview
        state.pendingOrigin = nil
        state.hoverCells = []
        state.hoverIsValid = true

        // Auto-advance
        if let next = ShipType.allCases.first(where: { !state.placedShips.contains($0) }) {
            state.selectedShip = next
        }
    }

    private func validatePlacement(cells: [Coord]) -> Bool {
        for c in cells {
            guard (0..<8).contains(c.row), (0..<8).contains(c.col) else { return false }
            if state.playerMarks[c] == .ship { return false }
        }
        return true
    }

    private func cellsFor(ship: ShipType, origin: Coord, orientation: Orientation) -> [Coord] {
        (0..<ship.length).map { i in
            switch orientation {
            case .horizontal: return Coord(row: origin.row, col: origin.col + i)
            case .vertical:   return Coord(row: origin.row + i, col: origin.col)
            }
        }
    }
}

private struct PlacementControlsView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(spacing: 12) {

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(ShipType.allCases) { ship in
                        ShipChip(
                            ship: ship,
                            isSelected: ship == state.selectedShip,
                            isPlaced: state.placedShips.contains(ship)
                        )
                        .onTapGesture {
                            guard !state.placedShips.contains(ship) else { return }
                            state.selectedShip = ship
                            // Clear preview when switching ships
                            state.pendingOrigin = nil
                            state.hoverCells = []
                            state.hoverIsValid = true
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            HStack(spacing: 12) {
                Button {
                    state.orientation.toggle()
                    // If we had a pending origin, recompute preview with new orientation
                    if let origin = state.pendingOrigin {
                        let cells = (0..<state.selectedShip.length).map { i -> Coord in
                            switch state.orientation {
                            case .horizontal: return Coord(row: origin.row, col: origin.col + i)
                            case .vertical:   return Coord(row: origin.row + i, col: origin.col)
                            }
                        }
                        state.hoverCells = Set(cells)
                        state.hoverIsValid = cells.allSatisfy {
                            (0..<8).contains($0.row) && (0..<8).contains($0.col) && state.playerMarks[$0] != .ship
                        }
                    }
                } label: {
                    Label("Rotate (\(state.orientation.rawValue))", systemImage: "rotate.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    // UI-only placeholder for now
                } label: {
                    Label("Auto-place", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 12) {
                Button(role: .destructive) {
                    state.playerMarks = [:]
                    state.placedShips = []
                    state.pendingOrigin = nil
                    state.hoverCells = []
                    state.hoverIsValid = true
                    state.selectedShip = .battleship
                    state.orientation = .horizontal
                } label: {
                    Label("Clear", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                Button {
                    state.screen = .battle
                } label: {
                    Text("Start Battle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(state.placedShips.count < ShipType.allCases.count)
            }
        }
    }
}
