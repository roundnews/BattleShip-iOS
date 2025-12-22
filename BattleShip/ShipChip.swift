import SwiftUI

struct ShipChip: View {
    let ship: ShipType
    let isSelected: Bool
    let isPlaced: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text("\(ship.name) \(ship.length)")
                .font(.subheadline)
                .lineLimit(1)

            if isPlaced {
                Image(systemName: "checkmark.circle.fill")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.15) : Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .cornerRadius(12)
        .opacity(isPlaced ? 0.6 : 1.0)
    }
}
