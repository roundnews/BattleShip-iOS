import SwiftUI

struct BattleScreen: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(spacing: 12) {
            header

            GeometryReader { geo in
                let total = geo.size.height
                let spacing: CGFloat = 12
                let each = (total - spacing) / 2.0

                VStack(spacing: spacing) {

                    FleetGridView(
                        title: "Your Fleet",
                        marks: state.playerMarks,
                        sunkCells: state.playerSunkCells,
                        hoverCells: [],
                        hoverValid: true,
                        isInteractive: false,
                        labelsStyle: .battleTop, // rows-left + cols-bottom
                        onTap: { _ in }
                    )
                    .frame(height: each)

                    FleetGridView(
                        title: "Enemy Waters",
                        marks: state.enemyMarks,
                        sunkCells: state.enemySunkCells,
                        hoverCells: [],
                        hoverValid: true,
                        isInteractive: state.isPlayerTurn,
                        labelsStyle: .battleBottom, // rows-left only
                        onTap: { coord in fire(at: coord) }
                    )
                    .frame(height: each)
                }
            }
            .padding(.horizontal, 8)
        }
        .padding(.top, 8)
        .background(Color(.systemGroupedBackground))
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(state.isPlayerTurn ? "Your turn" : "Enemy turn")
                    .font(.headline)
                Text("Shots: \(state.shotsCount)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Menu {
                Button("New Game") { state.resetAll() }
                Button("Back to Placement") { state.screen = .placement }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
        }
        .padding(.horizontal)
    }

    private func fire(at coord: Coord) {
        // UI-only placeholder:
        // - blocks repeats
        // - records miss/hit pattern for demo
        guard state.enemyMarks[coord] == nil else { return }

        state.shotsCount += 1

        // Fake outcome for UI testing
        if state.shotsCount % 3 == 0 {
            state.enemyMarks[coord] = .hit
        } else {
            state.enemyMarks[coord] = .miss
        }

        // Fake turn switch
        state.isPlayerTurn = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            state.isPlayerTurn = true
        }
    }
}
