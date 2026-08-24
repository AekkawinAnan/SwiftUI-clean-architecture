//
//  ItemCategory.swift
//  Discount
//

import Foundation

/// หมวดหมู่สินค้า ใช้กับแคมเปญ on-top "ส่วนลดเปอร์เซ็นต์ตามหมวดหมู่สินค้า"
/// `nonisolated`: เป็นค่าในโดเมนล้วน ๆ ไม่ผูกกับ actor ใด (โปรเจกต์ตั้ง default isolation เป็น MainActor).
nonisolated enum ItemCategory: String, Codable, CaseIterable, Hashable {
    case clothing
    case accessories
    case electronics

    var displayName: String {
        switch self {
        case .clothing: "Clothing"
        case .accessories: "Accessories"
        case .electronics: "Electronics"
        }
    }
}
