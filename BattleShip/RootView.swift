import SwiftUI

struct RootView: View {
    @StateObject private var state = AppState()

    var body: some View {
        switch state.screen {
        case .placement:
            PlacementScreen(state: state)
        case .battle:
            BattleScreen(state: state)
        }
    }
}
