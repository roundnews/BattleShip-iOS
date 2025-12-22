import SwiftUI

struct BattleScreen: View {
    @ObservedObject var state: AppState

    var body: some View {
        ZStack {
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
                            labelsStyle: .battleTop,
                            onTap: { _ in }
                        )
                        .frame(height: each)
                        .animation(.easeInOut(duration: 0.2), value: state.playerMarks)
                        .animation(.easeInOut(duration: 0.2), value: state.playerSunkCells)

                        FleetGridView(
                            title: "Enemy Waters",
                            marks: state.enemyMarks,
                            sunkCells: state.enemySunkCells,
                            hoverCells: [],
                            hoverValid: true,
                            isInteractive: state.isPlayerTurn,
                            labelsStyle: .battleBottom,
                            onTap: { coord in state.fire(at: coord) }
                        )
                        .frame(height: each)
                        .animation(.easeInOut(duration: 0.2), value: state.enemyMarks)
                        .animation(.easeInOut(duration: 0.2), value: state.enemySunkCells)
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(.top, 8)
            .background(Color(.systemGroupedBackground))

            if state.playerWon || state.enemyWon {
                endBanner
                    .transition(.scale.combined(with: .opacity))
            }
        }
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
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
            }
        }
        .padding(.horizontal)
    }

    private var endBanner: some View {
        VStack(spacing: 12) {
            Text(state.playerWon ? "You Win!" : "You Lose")
                .font(.largeTitle).bold()
            HStack(spacing: 12) {
                Button("New Game") { state.resetAll() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .padding()
    }

    private func fire(at coord: Coord) {
        state.fire(at: coord)
    }
}

