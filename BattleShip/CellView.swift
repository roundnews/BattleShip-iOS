import SwiftUI

struct CellView: View {
    let size: CGFloat
    let mark: CellMark
    let isHover: Bool
    let hoverValid: Bool

    var body: some View {
        ZStack {
            Rectangle().fill(Color.clear)
            Rectangle().stroke(Color(.separator), lineWidth: 0.5)

            switch mark {
            case .empty:
                EmptyView()
            case .ship:
                Rectangle().inset(by: 1).fill(Color.brown.opacity(0.55))
            case .miss:
                Circle().frame(width: size * 0.22, height: size * 0.22)
            case .hit:
                Image(systemName: "xmark")
                    .font(.system(size: size * 0.35, weight: .bold))
            case .sunk:
                Rectangle().inset(by: 1).fill(Color.red.opacity(0.75))
            }

            if isHover {
                Rectangle()
                    .inset(by: 2)
                    .stroke(hoverValid ? Color.accentColor : Color.red, lineWidth: 2)
            }
        }
        .frame(width: size, height: size)
    }
}
