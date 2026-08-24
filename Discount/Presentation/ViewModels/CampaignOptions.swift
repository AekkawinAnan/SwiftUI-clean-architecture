//
//  CampaignOptions.swift
//  Discount
//

import Foundation

// MARK: - โมเดล options สำหรับ Picker
//
// ตัวห่อ `DiscountCampaign` สำหรับ SwiftUI `Picker` ทำให้บังคับกติกาข้อ 1
// (หนึ่งหมวดหมู่เลือกได้สูงสุด 1 แคมเปญ) ใน UI ได้โดยง่าย:
// ViewModel เก็บ option ได้ "หนึ่งเดียว" ต่อหมวดหมู่

/// Options ของหมวด **Coupon**.
enum CouponOption: Hashable, Identifiable {
    case none
    case fixedAmount(Decimal)
    case percentage(Decimal)

    var id: Self { self }

    var label: String {
        switch self {
        case .none: "None"
        case .fixedAmount(let amount): "−\(amount) THB Flat"
        case .percentage(let percent): "\(percent)% Off Total"
        }
    }

    var campaign: DiscountCampaign? {
        switch self {
        case .none: nil
        case .fixedAmount(let amount): .fixedAmount(amount: amount)
        case .percentage(let percent): .percentage(percent: percent)
        }
    }

    static let options: [CouponOption] = [
        .none,
        .fixedAmount(100),
        .fixedAmount(250),
        .percentage(10),
        .percentage(15),
    ]
}

/// Options ของหมวด **On Top**.
enum OnTopOption: Hashable, Identifiable {
    case none
    case categoryPercentage(percent: Decimal)
    case points

    var id: Self { self }

    var label: String {
        switch self {
        case .none: "None"
        case .categoryPercentage(let percent): "\(percent)% Off Category"
        case .points: "Redeem Points"
        }
    }

    /// สร้างแคมเปญที่ใช้งานจริง
    /// คืน `nil` เมื่อ option เป็น `.none` หรือข้อความคะแนน
    /// ว่าง/ไม่ถูกต้อง/เป็นศูนย์ — ป้องกัน input ข้อความที่ผิดพลาด.
    func campaign(category: ItemCategory, pointsText: String) -> DiscountCampaign? {
        switch self {
        case .none:
            return nil
        case .categoryPercentage(let percent):
            return .percentageByCategory(percent: percent, category: category)
        case .points:
            guard let points = Self.parsedPoints(from: pointsText), points > 0 else {
                return nil
            }
            return .points(count: points)
        }
    }

    /// แปลงข้อความอิสระจากผู้ใช้เป็นจำนวนคะแนนที่ไม่ติดลบ
    /// คืน `nil` เมื่อข้อความว่างหรือแปลงไม่ได้ (เช่น "abc", "-5").
    static func parsedPoints(from text: String) -> Decimal? {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, let value = Decimal(string: cleaned), value >= 0 else {
            return nil
        }
        return value
    }

    static let options: [OnTopOption] = [
        .none,
        .categoryPercentage(percent: 10),
        .categoryPercentage(percent: 20),
        .points,
    ]
}

/// Options ของหมวด **Seasonal** ("ทุก X บาท หัก Y บาท").
enum SeasonalOption: Hashable, Identifiable {
    case none
    case seasonal(perAmount: Decimal, discount: Decimal)

    var id: Self { self }

    var label: String {
        switch self {
        case .none: "None"
        case .seasonal(let perAmount, let discount): "Every \(perAmount) THB −\(discount)"
        }
    }

    var campaign: DiscountCampaign? {
        switch self {
        case .none: nil
        case .seasonal(let perAmount, let discount):
            .seasonal(perAmount: perAmount, discount: discount)
        }
    }

    static let options: [SeasonalOption] = [
        .none,
        .seasonal(perAmount: 300, discount: 40),
        .seasonal(perAmount: 500, discount: 60),
        .seasonal(perAmount: 1000, discount: 150),
    ]
}
