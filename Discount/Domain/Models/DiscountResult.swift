//
//  DiscountResult.swift
//  Discount
//

import Foundation

/// หนึ่งแถวของการแจกแจงแบบทีละขั้น: ใช้แคมเปญใด กับยอดเท่าไร
/// ลดไปเท่าไร และเหลือยอดรวมเท่าไร
nonisolated struct DiscountStep: Identifiable, Hashable {
    let id: UUID
    let campaign: DiscountCampaign
    /// ยอดรวมก่อนใช้แคมเปญนี้ (ข้อมูลนำเข้า).
    let amountBefore: Decimal
    /// ยอดที่ถูกลดจริง (หลังผ่านการ cap/clamp).
    let discountApplied: Decimal
    /// ยอดรวมหลังใช้แคมเปญนี้ (ผลลัพธ์ → เป็นข้อมูลนำเข้าของขั้นถัดไป).
    let amountAfter: Decimal
    /// คำอธิบายสำหรับผู้ใช้ (ไม่บังคับ) เช่น เหตุผลที่เจอเพดาน cap.
    let note: String?

    init(
        id: UUID = UUID(),
        campaign: DiscountCampaign,
        amountBefore: Decimal,
        discountApplied: Decimal,
        amountAfter: Decimal,
        note: String? = nil
    ) {
        self.id = id
        self.campaign = campaign
        self.amountBefore = amountBefore
        self.discountApplied = discountApplied
        self.amountAfter = amountAfter
        self.note = note
    }
}

/// ผลลัพธ์ที่สมบูรณ์ของการคำนวณ: subtotal, ทุกขั้นตอนที่ใช้ และราคาสุดท้าย.
nonisolated struct DiscountCalculationResult: Hashable {
    let subtotal: Decimal
    let steps: [DiscountStep]
    let finalPrice: Decimal

    /// คำนวณ: ส่วนลดรวม = subtotal − ราคาสุดท้าย.
    var totalDiscount: Decimal { subtotal - finalPrice }

    var hasAnyDiscount: Bool { !steps.isEmpty }
}

// MARK: - ข้อผิดพลาด

/// throw เมื่อ *configuration ของแคมเปญไม่ถูกต้อง* (ส่วนลดที่ "ลดเกิน" ไม่ถือเป็น error —
/// ระบบจะ clamp อย่างนุ่มนวลเพื่อไม่ให้ราคาสุดท้ายติดลบแทน)
nonisolated enum DiscountError: LocalizedError, Equatable {
    case negativeFixedAmount
    case percentageOutOfRange(Decimal)
    case negativePoints
    case invalidSeasonalConfiguration(perAmount: Decimal, discount: Decimal)

    var errorDescription: String? {
        switch self {
        case .negativeFixedAmount:
            "A fixed amount discount cannot be negative."
        case .percentageOutOfRange(let percent):
            "Percentage must be between 0 and 100 (got \(percent))."
        case .negativePoints:
            "Points cannot be negative."
        case .invalidSeasonalConfiguration(let perAmount, let discount):
            "Seasonal campaign requires 'per amount' > 0 and a non-negative discount "
                + "(got X=\(perAmount), Y=\(discount))."
        }
    }
}
