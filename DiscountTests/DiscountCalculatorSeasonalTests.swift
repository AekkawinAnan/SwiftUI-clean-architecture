//
//  DiscountCalculatorSeasonalTests.swift
//  DiscountTests
//

import XCTest
@testable import Discount

/// แคมเปญตามฤดูกาล "ทุก X บาท หัก Y บาท".
/// ทุก test เขียนตามโครงสร้าง Given–When–Then.
final class DiscountCalculatorSeasonalTests: DiscountCalculatorTestCase {

    func testSeasonalExactMultiples() throws {
        // Given: ยอดรวม 900 บาท (300×3) และแคมเปญทุก 300 บาท ลด 40
        let cart900 = [CartItem(name: "Item", category: .electronics, price: 300, quantity: 3)]
        let campaigns: [DiscountCampaign] = [.seasonal(perAmount: 300, discount: 40)]

        // When: คำนวณส่วนลด
        let result = try calculate(campaigns, cart: cart900)

        // Then: ได้พอดี 3 ก้อน → 3 × 40 = 120
        assertDecimalEqual(result.steps[0].discountApplied, 120)
        assertDecimalEqual(result.finalPrice, 780)
    }

    func testSeasonalRemainderDoesNotEarnABucket() throws {
        // Given: ยอดรวม 1,350 บาท และแคมเปญทุก 300 บาท ลด 40
        let campaigns: [DiscountCampaign] = [.seasonal(perAmount: 300, discount: 40)]

        // When: คำนวณส่วนลด
        let result = try calculate(campaigns)

        // Then: floor(1350 / 300) = 4 (เศษ 150 ไม่ถูกนับ) → 4 × 40 = 160
        assertDecimalEqual(result.steps[0].discountApplied, 160)
        assertDecimalEqual(result.finalPrice, 1190)
    }

    func testSeasonalUsesCurrentPostCouponTotalForBuckets() throws {
        // Given: คูปองลด 10% ตามด้วย seasonal ทุก 300 บาท ลด 40
        let campaigns: [DiscountCampaign] = [
            .percentage(percent: 10),
            .seasonal(perAmount: 300, discount: 40),
        ]

        // When: คำนวณส่วนลดตามลำดับ pipeline (1350 → 1215)
        let result = try calculate(campaigns)

        // Then: นับก้อนจากยอดรวม "ปัจจุบัน": floor(1215 / 300) = 4 → −160 → 1055
        assertDecimalEqual(result.steps[1].amountBefore, 1215)
        assertDecimalEqual(result.steps[1].discountApplied, 160)
        assertDecimalEqual(result.finalPrice, 1055)
    }

    func testSeasonalDiscountLargerThanTotalClampsToZero() throws {
        // Given: ยอดรวม 1,350 บาท และแคมเปญทุก 300 บาท ลด 800
        let campaigns: [DiscountCampaign] = [.seasonal(perAmount: 300, discount: 800)]

        // When: คำนวณส่วนลด (4 ก้อน × 800 = 3,200 > 1,350)
        let result = try calculate(campaigns)

        // Then: clamp ที่ยอดรวม ราคาสุดท้ายเป็นศูนย์ พร้อม note อธิบาย
        assertDecimalEqual(result.steps[0].discountApplied, 1350)
        assertDecimalEqual(result.finalPrice, 0)
        XCTAssertEqual(result.steps[0].note, "Discount limited to remaining total")
    }

    func testSeasonalTotalBelowFirstBucketAppliesNothing() throws {
        // Given: ยอดรวมเพียง 150 บาท และแคมเปญทุก 300 บาท ลด 40
        let tinyCart = [CartItem(name: "Candy", category: .accessories, price: 150)]
        let campaigns: [DiscountCampaign] = [.seasonal(perAmount: 300, discount: 40)]

        // When: คำนวณส่วนลด
        let result = try calculate(campaigns, cart: tinyCart)

        // Then: ยอดไม่ถึงก้อนแรก จึงไม่มีส่วนลด
        assertDecimalEqual(result.steps[0].discountApplied, 0)
        assertDecimalEqual(result.finalPrice, 150)
    }

    func testInvalidSeasonalConfigurationsThrow() {
        // Given: configuration ของ seasonal ที่ไม่ถูกต้อง (X=0, X ติดลบ, Y ติดลบ)
        let invalidCases: [(perAmount: Decimal, discount: Decimal)] = [
            (0, 40), (-300, 40), (300, -40),
        ]

        // When & Then: ทุกกรณีต้อง throw .invalidSeasonalConfiguration
        for invalid in invalidCases {
            assertThrows(
                .invalidSeasonalConfiguration(perAmount: invalid.perAmount, discount: invalid.discount),
                campaigns: [.seasonal(perAmount: invalid.perAmount, discount: invalid.discount)]
            )
        }
    }
}
