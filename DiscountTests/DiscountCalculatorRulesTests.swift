//
//  DiscountCalculatorRulesTests.swift
//  DiscountTests
//

import XCTest
@testable import Discount

/// กติกาข้อ 1 และ 2, ฉาก pipeline เต็ม และ edge cases ที่เหลือ.
final class DiscountCalculatorRulesAndEdgeCaseTests: DiscountCalculatorTestCase {

    // MARK: กติกาข้อ 1 — หนึ่งหมวดหมู่เลือกได้สูงสุด 1 แคมเปญ

    func testDuplicateCampaignsInSameCategoryKeepOnlyTheFirst() throws {
        // ทั้งคู่เป็นคูปอง → รอดมาเฉพาะตัวแรก (10%).
        let result = try calculate([
            .percentage(percent: 10),
            .fixedAmount(amount: 100),
        ])
        XCTAssertEqual(result.steps.count, 1)
        assertDecimalEqual(result.finalPrice, 1215)
    }

    // MARK: กติกาข้อ 2 — ลำดับคูปอง → On Top → Seasonal อย่างเคร่งครัด

    func testCampaignsAreAlwaysOrderedCouponOnTopSeasonal() throws {
        let result = try calculate([
            .seasonal(perAmount: 300, discount: 40),   // ส่งมาผิดลำดับ…
            .points(count: 243),                       // …on top เป็นตัวที่สอง…
            .percentage(percent: 10),                  // …และคูปองมาท้ายสุด.
        ])

        // ลำดับถูกบังคับเสมอ ไม่ว่า input จะส่งมาตามลำดับใด.
        XCTAssertEqual(result.steps.map(\.campaign.category), [.coupon, .onTop, .seasonal])

        // และต้องเท่ากับผลลัพธ์ที่คำนวณจากลำดับมาตรฐาน.
        let canonical = try calculate([
            .percentage(percent: 10),
            .points(count: 243),
            .seasonal(perAmount: 300, discount: 40),
        ])
        XCTAssertEqual(result.steps.map(\.discountApplied), canonical.steps.map(\.discountApplied))
        XCTAssertEqual(result.finalPrice, canonical.finalPrice)
    }

    func testOutputOfEachStepFeedsTheNextStep() throws {
        // ตรวจความต่อเนื่องของ amountBefore/amountAfter ระหว่างขั้น.
        let result = try calculate([
            .percentage(percent: 10),                  // 1350 → 1215
            .points(count: 300),                       // cap 243 → 972
            .seasonal(perAmount: 300, discount: 40),   // floor(972/300)=3 → −120 → 852
        ])
        XCTAssertEqual(result.steps.count, 3)

        assertDecimalEqual(result.steps[0].amountBefore, 1350)
        assertDecimalEqual(result.steps[0].amountAfter, 1215)
        assertDecimalEqual(result.steps[1].amountBefore, 1215)
        assertDecimalEqual(result.steps[1].amountAfter, 972)
        assertDecimalEqual(result.steps[2].amountBefore, 972)
        assertDecimalEqual(result.steps[2].amountAfter, 852)
    }

    // MARK: ฉาก pipeline เต็ม (ตัวอย่างที่คำนวณครบทุกขั้น)

    func testFullPipelineScenario() throws {
        // Subtotal 1350 → คูปอง 10% → 1215 → คะแนน 300 โดน cap ที่ 20% (=243) → 972
        // → seasonal ทุก 300 ลด 40: floor(972/300)=3 → −120 → ราคาสุดท้าย 852.
        let result = try calculate([
            .percentage(percent: 10),
            .points(count: 300),
            .seasonal(perAmount: 300, discount: 40),
        ])
        XCTAssertEqual(result.steps.map(\.discountApplied), [135, 243, 120])
        assertDecimalEqual(result.finalPrice, 852)
        assertDecimalEqual(result.totalDiscount, 498)
    }

    // MARK: Edge cases ของตะกร้าว่าง

    func testEmptyCartWithNoCampaigns() throws {
        let result = try calculate([], cart: [])
        assertDecimalEqual(result.subtotal, 0)
        assertDecimalEqual(result.finalPrice, 0)
        XCTAssertTrue(result.steps.isEmpty)
    }

    func testEmptyCartWithCampaignsNeverProducesNegativePrices() throws {
        let result = try calculate([.fixedAmount(amount: 100)], cart: [])
        XCTAssertEqual(result.steps.count, 1)
        assertDecimalEqual(result.steps[0].discountApplied, 0)
        assertDecimalEqual(result.finalPrice, 0)
    }
}
