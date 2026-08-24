//
//  DiscountCalculator.swift
//  Discount
//

import Foundation

// MARK: - Abstraction (Dependency Inversion: ViewModel พึ่งพา protocol นี้ ไม่ใช่ concrete type)

/// `nonisolated`: เอนจินเป็น pure logic ปลอดภัยต่อเธรด — เรียกได้จาก actor ใดก็ได้.
nonisolated protocol DiscountCalculating {
    /// ใช้แคมเปญที่เลือกตามกติกาข้อ 2 (คูปอง → On Top → Seasonal)
    /// แล้วคืนผลลัพธ์แบบแจกแจงทีละขั้นพร้อมราคาสุดท้าย.
    ///
    /// - Throws: `DiscountError` เมื่อ configuration ของแคมเปญไม่ถูกต้อง.
    func calculate(
        cartItems: [CartItem],
        campaigns: [DiscountCampaign]
    ) throws -> DiscountCalculationResult
}

// MARK: - เอนจิน

/// เอนจินคำนวณแบบ pure และ stateless ไม่พึ่ง UI/framework → เขียน unit test ได้ง่าย.
/// `nonisolated`: logic โดเมนล้วน เรียกได้จาก actor ใดก็ได้ (โปรเจกต์ default isolation เป็น MainActor).
nonisolated struct DiscountCalculator: DiscountCalculating {

    /// กติกา: คะแนนสะสมห้ามลดเกิน 20% ของยอดรวมปัจจุบัน.
    static let pointsCapPercent: Decimal = 20

    func calculate(
        cartItems: [CartItem],
        campaigns: [DiscountCampaign]
    ) throws -> DiscountCalculationResult {
        // ตรวจสอบ configuration ที่ไม่สมเหตุสมผลให้จบเร็ว (จำนวนเงินติดลบ, % > 100, ...).
        for campaign in campaigns {
            try Self.validate(campaign)
        }

        // --- ขั้นที่ 0: Subtotal --------------------------------------------
        // คำนวณ: subtotal = Σ (ราคาต่อชิ้น × จำนวนชิ้น) ของทุกรายการ
        // นี่คือข้อมูลนำเข้าตั้งต้นของ pipeline ส่วนลด.
        let subtotal = Decimal.roundedMoney(
            cartItems.reduce(Decimal.zero) { $0 + $1.lineTotal }
        )

        // --- กติกาข้อ 1 และ 2 ถูกบังคับ "ที่นี่" ไม่ใช่แค่ใน UI -----------------
        // แม้เอนจินได้รับ [seasonal, onTop, coupon] หรือข้อมูลซ้ำ
        // ผลลัพธ์ก็ยัง deterministic และตรงตาม spec เสมอ.
        let pipeline = Self.pipeline(from: campaigns)

        var currentTotal = subtotal
        var steps: [DiscountStep] = []

        // ผลลัพธ์ของแต่ละขั้นจะกลายเป็นข้อมูลนำเข้าของขั้นถัดไป.
        for campaign in pipeline {
            let step = apply(campaign, to: currentTotal, cartItems: cartItems)
            steps.append(step)
            currentTotal = step.amountAfter
        }

        // Edge case: ราคาสุดท้ายห้ามต่ำกว่าศูนย์เด็ดขาด.
        let finalPrice = max(Decimal.roundedMoney(currentTotal), Decimal.zero)

        return DiscountCalculationResult(
            subtotal: subtotal,
            steps: steps,
            finalPrice: finalPrice
        )
    }

    // MARK: การสร้าง pipeline (กติกาข้อ 1 และ 2)

    /// เรียงแคมเปญตามลำดับหมวดหมู่ (คูปอง → On Top → Seasonal) และเก็บเฉพาะ
    /// แคมเปญ "แรก" ของแต่ละหมวดหมู่ (กติกาข้อ 1).
    static func pipeline(from campaigns: [DiscountCampaign]) -> [DiscountCampaign] {
        var seenCategories = Set<DiscountCategory>()
        return campaigns
            .sorted { $0.category.applicationOrder < $1.category.applicationOrder }
            .filter { seenCategories.insert($0.category).inserted }
    }

    // MARK: การตรวจสอบความถูกต้อง (throw เมื่อ input ไม่ถูกต้อง แต่ไม่ throw กรณี "ส่วนลดเกิน")

    private static func validate(_ campaign: DiscountCampaign) throws {
        switch campaign {
        case .fixedAmount(let amount):
            guard amount >= 0 else { throw DiscountError.negativeFixedAmount }

        case .percentage(let percent):
            guard percent >= 0, percent <= 100 else {
                throw DiscountError.percentageOutOfRange(percent)
            }

        case .percentageByCategory(let percent, _):
            guard percent >= 0, percent <= 100 else {
                throw DiscountError.percentageOutOfRange(percent)
            }

        case .points(let count):
            guard count >= 0 else { throw DiscountError.negativePoints }

        case .seasonal(let perAmount, let discount):
            guard perAmount > 0, discount >= 0 else {
                throw DiscountError.invalidSeasonalConfiguration(
                    perAmount: perAmount,
                    discount: discount
                )
            }
        }
    }

    // MARK: การใช้แคมเปญทีละขั้น

    /// ใช้แคมเปญหนึ่งตัวกับยอด `total` แล้วคืน `DiscountStep` ผลลัพธ์
    /// ทุก branch มีคอมเมนต์อธิบายสูตรคำนวณ และ clamp กรณีส่วนลดเกินอย่างนุ่มนวล.
    private func apply(
        _ campaign: DiscountCampaign,
        to total: Decimal,
        cartItems: [CartItem]
    ) -> DiscountStep {
        let discount: Decimal
        var note: String?

        switch campaign {

        case .fixedAmount(let amount):
            // คำนวณ: after = total − amount แต่ไม่ต่ำกว่าศูนย์.
            discount = min(total, amount)

        case .percentage(let percent):
            // คำนวณ: discount = total × percent / 100.
            // เนื่องจาก validate แล้วว่า 0 ≤ percent ≤ 100 ผลลัพธ์จึงไม่ติดลบเองโดยอัตโนมัติ.
            discount = Decimal.roundedMoney(total * percent / 100)

        case .percentageByCategory(let percent, let category):
            // คำนวณ: ฐานของเปอร์เซ็นต์คือยอดรวม "เฉพาะหมวดหมู่ที่ระบุ"
            // — ไม่ใช่ยอดรวมทั้งหมด จากนั้นจึงนำผลลัพธ์ไป
            // หักจากยอดรวมปัจจุบัน.
            let categorySubtotal = cartItems
                .filter { $0.category == category }
                .reduce(Decimal.zero) { $0 + $1.lineTotal }
            let rawDiscount = Decimal.roundedMoney(categorySubtotal * percent / 100)
            // Edge case: แม้เป็นส่วนลดแบบหมวดหมู่ ก็หักเกินยอดรวมปัจจุบันไม่ได้.
            if rawDiscount > total {
                discount = total
                note = "Limited to remaining total"
            } else {
                discount = rawDiscount
            }

        case .points(let requestedPoints):
            // คำนวณ: Cap = 20% × ยอดรวม "ปัจจุบัน" (คือหลังขั้นคูปองแล้ว)
            // ส่วนลดจริง = min(คะแนนที่ขอใช้, cap) โดย 1 คะแนน = 1 บาท.
            let cap = Decimal.roundedMoney(total * Self.pointsCapPercent / 100)
            if requestedPoints > cap {
                discount = cap
                note = "Capped at \(Self.pointsCapPercent)% of current total"
            } else {
                discount = requestedPoints
            }

        case .seasonal(let perAmount, let discountPerBucket):
            // คำนวณ: bucketCount = floor(total / X) — เศษที่เหลือไม่นับเป็นก้อนใหม่
            // discount = bucketCount × Y โดย clamp ไม่ให้ยอดรวมติดลบ.
            let bucketCount = Decimal.floored(total / perAmount)
            let rawDiscount = bucketCount * discountPerBucket
            if rawDiscount > total {
                discount = total
                note = "Discount limited to remaining total"
            } else {
                discount = rawDiscount
            }
        }

        return DiscountStep(
            campaign: campaign,
            amountBefore: total,
            discountApplied: discount,
            amountAfter: total - discount,
            note: note
        )
    }
}
