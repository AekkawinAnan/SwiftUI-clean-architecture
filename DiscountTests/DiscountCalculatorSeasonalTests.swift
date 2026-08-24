//
//  DiscountCalculatorSeasonalTests.swift
//  DiscountTests
//

import XCTest
@testable import Discount

/// แคมเปญตามฤดูกาล "ทุก X บาท หัก Y บาท".
final class DiscountCalculatorSeasonalTests: DiscountCalculatorTestCase {

    func testSeasonalExactMultiples() throws {
        // ยอดรวม 900 กับ X=300 → ได้พอดี 3 ก้อน → 3 × 40 = ลด 120.
        let cart900 = [CartItem(name: "Item", category: .electronics, price: 300, quantity: 3)]
        let result = try calculate([.seasonal(perAmount: 300, discount: 40)], cart: cart900)
        assertDecimalEqual(result.steps[0].discountApplied, 120)
        assertDecimalEqual(result.finalPrice, 780)
    }

    func testSeasonalRemainderDoesNotEarnABucket() throws {
        // floor(1350 / 300) = 4 (เศษ 150 ไม่ถูกนับ) → 4 × 40 = ลด 160.
        let result = try calculate([.seasonal(perAmount: 300, discount: 40)])
        assertDecimalEqual(result.steps[0].discountApplied, 160)
        assertDecimalEqual(result.finalPrice, 1190)
    }

    func testSeasonalUsesCurrentPostCouponTotalForBuckets() throws {
        // ต้องนับก้อนจากยอดรวม "ปัจจุบัน" ไม่ใช่ subtotal:
        // คูปอง 10% → 1215; floor(1215 / 300) = 4 → −160 → 1055.
        let result = try calculate([
            .percentage(percent: 10),
            .seasonal(perAmount: 300, discount: 40),
        ])
        assertDecimalEqual(result.steps[1].amountBefore, 1215)
        assertDecimalEqual(result.steps[1].discountApplied, 160)
        assertDecimalEqual(result.finalPrice, 1055)
    }

    func testSeasonalDiscountLargerThanTotalClampsToZero() throws {
        // Edge case: 4 ก้อน × 800 = 3200 > 1350 → clamp แล้วราคาสุดท้ายยัง ≥ 0.
        let result = try calculate([.seasonal(perAmount: 300, discount: 800)])
        assertDecimalEqual(result.steps[0].discountApplied, 1350)
        assertDecimalEqual(result.finalPrice, 0)
        XCTAssertEqual(result.steps[0].note, "Discount limited to remaining total")
    }

    func testSeasonalTotalBelowFirstBucketAppliesNothing() throws {
        let tinyCart = [CartItem(name: "Candy", category: .accessories, price: 150)]
        let result = try calculate([.seasonal(perAmount: 300, discount: 40)], cart: tinyCart)
        assertDecimalEqual(result.steps[0].discountApplied, 0)
        assertDecimalEqual(result.finalPrice, 150)
    }

    func testInvalidSeasonalConfigurationsThrow() {
        assertThrows(
            .invalidSeasonalConfiguration(perAmount: 0, discount: 40),
            campaigns: [.seasonal(perAmount: 0, discount: 40)]
        )
        assertThrows(
            .invalidSeasonalConfiguration(perAmount: -300, discount: 40),
            campaigns: [.seasonal(perAmount: -300, discount: 40)]
        )
        assertThrows(
            .invalidSeasonalConfiguration(perAmount: 300, discount: -40),
            campaigns: [.seasonal(perAmount: 300, discount: -40)]
        )
    }
}
