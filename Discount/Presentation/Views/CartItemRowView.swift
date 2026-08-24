//
//  CartItemRowView.swift
//  Discount
//

import SwiftUI

/// A single line item: icon, name, category badge, quantity × price, line total.
struct CartItemRowView: View {
    let item: CartItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.category.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 36, height: 36)
                .background(item.category.badgeColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)

                HStack(spacing: 6) {
                    Text(item.category.displayName)
                        .font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.category.badgeColor.opacity(0.2), in: Capsule())

                    Text("\(item.quantity) × \(item.price.thb)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(item.lineTotal.thb)
                .font(.subheadline.weight(.bold))
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Presentation-only category styling

private extension ItemCategory {
    var systemImage: String {
        switch self {
        case .clothing: "tshirt"
        case .accessories: "handbag"
        case .electronics: "headphones"
        }
    }

    var badgeColor: Color {
        switch self {
        case .clothing: .indigo
        case .accessories: .orange
        case .electronics: .teal
        }
    }
}

#Preview {
    List {
        CartItemRowView(item: CartItem.mockCart[0])
        CartItemRowView(item: CartItem.mockCart[3])
    }
}
