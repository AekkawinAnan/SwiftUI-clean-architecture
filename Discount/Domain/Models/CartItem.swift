//
//  CartItem.swift
//  Discount
//

import Foundation

/// A single line item in the shopping cart.
/// Money is modelled with `Decimal` to avoid floating-point rounding artifacts.
nonisolated struct CartItem: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let category: ItemCategory
    let price: Decimal
    var quantity: Int

    init(
        id: UUID = UUID(),
        name: String,
        category: ItemCategory,
        price: Decimal,
        quantity: Int = 1
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.price = price
        self.quantity = quantity
    }

    /// Math: line total = unit price × quantity.
    var lineTotal: Decimal { price * Decimal(quantity) }
}

// MARK: - Mock Data (the assignment asks NOT to build an inventory system)

extension CartItem {
    nonisolated static let mockCart: [CartItem] = [
        CartItem(name: "Graphic T-Shirt", category: .clothing, price: 350, quantity: 2),
        CartItem(name: "Denim Jacket", category: .clothing, price: 999, quantity: 1),
        CartItem(name: "Leather Belt", category: .accessories, price: 250, quantity: 1),
        CartItem(name: "Wireless Earbuds", category: .electronics, price: 1299, quantity: 1),
    ]
}
