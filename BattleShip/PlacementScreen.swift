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
                onTap: { coord in
                    if let pending = state.pendingOrigin, pending == coord {
                        state.commitPlacementPreview()
                    } else {
                        state.previewPlacement(at: coord)
                    }
                }
            )
            .frame(maxHeight: .infinity)
            .padding(.horizontal, 8)

            PlacementControlsView(state: state)
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
        .padding(.top, 8)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            state.loadIfAvailable()
        }
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
        // Deprecated: logic moved into AppState. Kept for compatibility.
        state.previewPlacement(at: coord)
    }

    private func commitPendingPlacement() {
        state.commitPlacementPreview()
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
                    if let origin = state.pendingOrigin { state.previewPlacement(at: origin) }
                } label: {
                    Label("Rotate (\(state.orientation.rawValue))", systemImage: "rotate.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                if state.pendingOrigin != nil && state.hoverIsValid {
                    Button {
                        state.commitPlacementPreview()
                    } label: {
                        Label("Place Ship", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        state.autoPlacePlayer()
                    } label: {
                        Label("Auto-place", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
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
                    state.startBattle()
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
