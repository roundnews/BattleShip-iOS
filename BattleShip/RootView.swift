import SwiftUI

struct RootView: View {
    @StateObject private var state = AppState()
    @Environment(\.scenePhase) private var phase

    var body: some View {
        VStack {
            switch state.screen {
            case .placement:
                PlacementScreen(state: state)
            case .battle:
                BattleScreen(state: state)
            }
        }
        .onChange(of: phase) { old, newPhase in
            if newPhase == .background { state.save() }
        }
    }
}

