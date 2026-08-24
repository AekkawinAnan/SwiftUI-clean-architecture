//
//  CartItem.swift
//  Discount
//

import Foundation

/// รายการสินค้าหนึ่งบรรทัดในตะกร้า
/// ค่าเงินใช้ประเภท `Decimal` เพื่อหลีกเลี่ยงข้อผิดพลาดการปัดเศษของจุดลอย (floating-point).
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

    /// คำนวณ: ยอดรวมของรายการ = ราคาต่อชิ้น × จำนวนชิ้น.
    var lineTotal: Decimal { price * Decimal(quantity) }
}

// MARK: - ข้อมูล Mock (โจทย์กำหนดให้ไม่ต้องสร้างระบบ inventory จริง)

extension CartItem {
    nonisolated static let mockCart: [CartItem] = [
        CartItem(name: "Graphic T-Shirt", category: .clothing, price: 350, quantity: 2),
        CartItem(name: "Denim Jacket", category: .clothing, price: 999, quantity: 1),
        CartItem(name: "Leather Belt", category: .accessories, price: 250, quantity: 1),
        CartItem(name: "Wireless Earbuds", category: .electronics, price: 1299, quantity: 1),
    ]
}
