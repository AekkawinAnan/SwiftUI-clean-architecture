//
//  DiscountCalculatorOnTopTests.swift
//  DiscountTests
//

import XCTest
@testable import Discount

/// แคมเปญ On Top: เปอร์เซ็นต์ตามหมวดหมู่สินค้า และคะแนนสะสม (พร้อมเพดาน 20%).
/// ทุก test เขียนตามโครงสร้าง Given–When–Then.
final class DiscountCalculatorOnTopTests: DiscountCalculatorTestCase {

    // MARK: เปอร์เซ็นต์ตามหมวดหมู่สินค้า

    func testCategoryPercentageUsesOnlyCategorySubtotalAsBasis() throws {
        // Given: ตะกร้าที่มีเสื้อผ้ายอดรวม 1,000 บาท และแคมเปญ on-top ลด 20% เฉพาะหมวดเสื้อผ้า
        let campaigns: [DiscountCampaign] = [
            .percentageByCategory(percent: 20, category: .clothing),
        ]

        // When: คำนวณส่วนลด
        let result = try calculate(campaigns)

        // Then: ฐานคำนวณต้องเป็นยอดของหมวดเสื้อผ้าเท่านั้น (1,000 × 20% = 200 ไม่ใช่ 20% ของ 1,350)
        assertDecimalEqual(result.steps[0].discountApplied, 200)
        assertDecimalEqual(result.finalPrice, 1150)
    }

    func testCategoryPercentageWithCategoryNotInCartAppliesNothing() throws {
        // Given: ตะกร้าที่ไม่มีสินค้าหมวด electronics และแคมเปญลด 50% เฉพาะหมวด electronics
        let clothingOnly = [CartItem(name: "Shirt", category: .clothing, price: 500, quantity: 2)]
        let campaigns: [DiscountCampaign] = [
            .percentageByCategory(percent: 50, category: .electronics),
        ]

        // When: คำนวณส่วนลด
        let result = try calculate(campaigns, cart: clothingOnly)

        // Then: ไม่มีสินค้าในหมวดดังกล่าวจึงไม่เกิดการลดราคา
        assertDecimalEqual(result.steps[0].discountApplied, 0)
        assertDecimalEqual(result.finalPrice, 1000)
    }

    func testCategoryPercentageCannotExceedCurrentTotal() throws {
        // Given: คูปองลดคงที่ 1,300 บาท (เหลือยอด 50) ตามด้วย on-top ลด 20% หมวดเสื้อผ้า
        // โดยฐานดิบของ 20% คือ 200 บาท ซึ่งมากกว่ายอดคงเหลือ
        let campaigns: [DiscountCampaign] = [
            .fixedAmount(amount: 1300),
            .percentageByCategory(percent: 20, category: .clothing),
        ]

        // When: คำนวณส่วนลดตามลำดับ pipeline
        let result = try calculate(campaigns)

        // Then: ส่วนลด on-top ถูก clamp เหลือยอดคงเหลือ 50 บาท พร้อม note อธิบาย
        XCTAssertEqual(result.steps[0].campaign.category, .coupon)
        XCTAssertEqual(result.steps[1].campaign.category, .onTop)
        assertDecimalEqual(result.steps[1].discountApplied, 50)
        assertDecimalEqual(result.finalPrice, 0)
        XCTAssertEqual(result.steps[1].note, "Limited to remaining total")
    }

    func testNegativeCategoryPercentageThrows() {
        // Given: แคมเปญ on-top ที่ระบุเปอร์เซ็นต์ติดลบ
        let campaigns: [DiscountCampaign] = [
            .percentageByCategory(percent: -10, category: .clothing),
        ]

        // When & Then: ต้อง throw .percentageOutOfRange(-10)
        assertThrows(.percentageOutOfRange(-10), campaigns: campaigns)
    }
    // MARK: คะแนนสะสม — 1 คะแนน = 1 บาท จำกัดไม่เกิน 20% ของยอดรวม "ปัจจุบัน"

    func testPointsBelowCapApplyOneToOne() throws {
        // Given: ยอดรวม 1,350 บาท และใช้คะแนน 100 (ต่ำกว่า cap 270)
        let campaigns: [DiscountCampaign] = [.points(count: 100)]

        // When: คำนวณส่วนลด
        let result = try calculate(campaigns)

        // Then: 1 คะแนน = 1 บาท ใช้ได้เต็มจำนวนโดยไม่เจอ cap
        assertDecimalEqual(result.steps[0].discountApplied, 100)
        assertDecimalEqual(result.finalPrice, 1250)
        XCTAssertNil(result.steps[0].note)
    }

    func testPointsExactlyAtCapApplyFully() throws {
        // Given: ยอดรวม 1,350 บาท (cap = 20% × 1350 = 270) และใช้คะแนนพอดี 270
        let campaigns: [DiscountCampaign] = [.points(count: 270)]

        // When: คำนวณส่วนลด
        let result = try calculate(campaigns)

        // Then: ใช้คะแนนได้เต็มจำนวนพอดีเพดาน
        assertDecimalEqual(result.steps[0].discountApplied, 270)
        assertDecimalEqual(result.finalPrice, 1080)
    }

    func testPointsAboveCapAreCappedAt20PercentOfCurrentTotal() throws {
        // Given: ยอดรวม 1,350 บาท (cap = 270) แต่ขอใช้คะแนน 300
        let campaigns: [DiscountCampaign] = [.points(count: 300)]

        // When: คำนวณส่วนลด
        let result = try calculate(campaigns)

        // Then: ลดได้จริงแค่ 270 (cap) พร้อม note อธิบายว่าโดนจำกัด
        assertDecimalEqual(result.steps[0].discountApplied, 270)
        assertDecimalEqual(result.finalPrice, 1080)
        XCTAssertNotNil(result.steps[0].note, "A note should explain why capping kicked in")
    }

    func testPointsCapIsBasedOnPostCouponTotalNotSubtotal() throws {
        // Given: คูปองลดคงที่ 500 บาท (1350 → 850) แล้วใช้คะแนน 300
        // cap ต้องคิดจากยอดหลังคูปอง: 20% × 850 = 170
        let campaigns: [DiscountCampaign] = [
            .fixedAmount(amount: 500),
            .points(count: 300),
        ]

        // When: คำนวณส่วนลดตามลำดับ pipeline
        let result = try calculate(campaigns)

        // Then: cap คิดจาก 850 ไม่ใช่ subtotal 1,350 จึงลดได้แค่ 170
        assertDecimalEqual(result.steps[0].amountAfter, 850)
        assertDecimalEqual(result.steps[1].discountApplied, 170)
        assertDecimalEqual(result.finalPrice, 680)
    }

    func testZeroPointsApplyNothing() throws {
        // Given: ยอดรวม 1,350 บาท และใช้คะแนน 0
        let campaigns: [DiscountCampaign] = [.points(count: 0)]

        // When: คำนวณส่วนลด
        let result = try calculate(campaigns)

        // Then: ไม่มีส่วนลดเกิดขึ้น
        assertDecimalEqual(result.steps[0].discountApplied, 0)
        assertDecimalEqual(result.finalPrice, 1350)
    }

    func testNegativePointsThrow() {
        // Given: แคมเปญคะแนนที่ระบุจำนวนคะแนนติดลบ (input ไม่ถูกต้อง)
        let campaigns: [DiscountCampaign] = [.points(count: -50)]

        // When & Then: ต้อง throw .negativePoints
        assertThrows(.negativePoints, campaigns: campaigns)
    }
}
