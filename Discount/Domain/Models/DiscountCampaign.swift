//
//  DiscountCampaign.swift
//  Discount
//

import Foundation

// MARK: - หมวดหมู่ส่วนลด (กติกาข้อ 1: หนึ่งหมวดหมู่เลือกได้สูงสุด 1 แคมเปญ)

/// หมวดหมู่ส่วนลดทั้งสาม ผู้ใช้เลือกได้หมวดหมู่ละไม่เกิน 1 แคมเปญ.
nonisolated enum DiscountCategory: String, Codable, CaseIterable, Hashable, Identifiable {
    case coupon
    case onTop = "on_top"
    case seasonal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .coupon: "Coupon"
        case .onTop: "On Top"
        case .seasonal: "Seasonal"
        }
    }

    /// สะท้อนกติกาข้อ 2: แคมเปญต้องถูกใช้ตามลำดับ คูปอง → On Top → Seasonal เท่านั้น.
    var applicationOrder: Int {
        switch self {
        case .coupon: 0
        case .onTop: 1
        case .seasonal: 2
        }
    }
}

// MARK: - แคมเปญ (enum พร้อม associated values)

/// คำอธิบายของแคมเปญส่วนลดหนึ่งแคมเปญ ซึ่ง immutable และ type-safe
/// การใช้ associated values ทำให้สร้างแคมเปญที่ข้อมูลไม่ครบไม่ได้ เช่น
/// ส่วนลดเปอร์เซ็นต์ที่ไม่ระบุอัตรา หรือแคมเปญตามฤดูกาลที่ไม่ครบทั้ง X และ Y.
nonisolated enum DiscountCampaign: Hashable, Codable {
    /// **คูปอง** — หักจากยอดรวมเป็นจำนวนเงินคงที่ (บาท).
    case fixedAmount(amount: Decimal)

    /// **คูปอง** — หัก `percent`% (0...100) จากยอดรวม.
    case percentage(percent: Decimal)

    /// **On Top** — คำนวณ `percent`% จากยอดรวมของสินค้า "เฉพาะหมวดหมู่ `category`"
    /// เท่านั้น แล้วนำไปหักจากยอดรวมปัจจุบัน.
    case percentageByCategory(percent: Decimal, category: ItemCategory)

    /// **On Top** — 1 คะแนน = 1 บาท โดยจำกัดส่วนลดไม่เกิน 20% ของยอดรวม "ปัจจุบัน" (หลังหักคูปอง).
    case points(count: Decimal)

    /// **Seasonal** — ทุกยอด `perAmount` บาท ของยอดรวม "ปัจจุบัน"
    /// (หลังหักคูปองและ on-top แล้ว) จะหัก `discount` บาท.
    case seasonal(perAmount: Decimal, discount: Decimal)

    /// แคมเปญนี้อยู่ในหมวดหมู่ใด (ใช้บังคับกติกาข้อ 1 และ 2).
    var category: DiscountCategory {
        switch self {
        case .fixedAmount, .percentage: .coupon
        case .percentageByCategory, .points: .onTop
        case .seasonal: .seasonal
        }
    }

    /// ชื่อสำหรับแสดงผล ใช้ใน UI breakdown แบบทีละขั้นและ picker.
    var displayName: String {
        switch self {
        case .fixedAmount(let amount):
            "Fixed Amount (−\(amount) THB)"
        case .percentage(let percent):
            "\(percent)% Off Total"
        case .percentageByCategory(let percent, let itemCategory):
            "\(percent)% Off \(itemCategory.displayName)"
        case .points:
            "Redeem Points (1 pt = 1 THB)"
        case .seasonal(let perAmount, let discount):
            "Special: Every \(perAmount) THB −\(discount) THB"
        }
    }
}
