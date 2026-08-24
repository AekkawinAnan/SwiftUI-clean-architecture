//
//  DiscountCalculatorCouponTests.swift
//  DiscountTests
//

import XCTest
@testable import Discount

/// Coupon campaigns: Fixed Amount and Percentage.
final class DiscountCalculatorCouponTests: DiscountCalculatorTestCase {

    // MARK: Subtotal

    func testSubtotalSumsLineTotals() throws {
        let result = try calculate([])
        assertDecimalEqual(result.subtotal, 1350, "1000 + 200 + 150")
        XCTAssertEqual(result.finalPrice, result.subtotal)
        XCTAssertTrue(result.steps.isEmpty)
    }

    // MARK: Fixed Amount

    func testFixedAmountCouponSubtractsFromTotal() throws {
        let result = try calculate([.fixedAmount(amount: 100)])
        XCTAssertEqual(result.steps.count, 1)
        assertDecimalEqual(result.steps[0].discountApplied, 100)
        assertDecimalEqual(result.finalPrice, 1250)
    }

    func testFixedAmountLargerThanTotalClampsToZero() throws {
        // Edge case: total must never drop below zero.
        let result = try calculate([.fixedAmount(amount: 2000)])
        assertDecimalEqual(result.steps[0].discountApplied, 1350)
        assertDecimalEqual(result.finalPrice, 0)
    }

    func testNegativeFixedAmountThrows() {
        assertThrows(.negativeFixedAmount, campaigns: [.fixedAmount(amount: -5)])
    }

    // MARK: Percentage

    func testPercentageCoupon() throws {
        let result = try calculate([.percentage(percent: 10)])
        assertDecimalEqual(result.steps[0].discountApplied, 135)
        assertDecimalEqual(result.finalPrice, 1215)
    }

    func testPercentageCoupon100PercentLeavesZero() throws {
        let result = try calculate([.percentage(percent: 100)])
        assertDecimalEqual(result.finalPrice, 0)
    }

    func testPercentageCouponRoundsHalfAwayFromZero() throws {
        // 133.35 × 10% = 13.335 → rounds half-away-from-zero to 13.34 → final = 120.01.
        // NOTE: money fixtures are built via String on purpose — Decimal(Double)
        // inherits binary floating-point error (e.g. 120.01 → 120.01000000000002…).
        let oddPrice = try XCTUnwrap(Decimal(string: "133.35"))
        let expectedDiscount = try XCTUnwrap(Decimal(string: "13.34"))
        let expectedFinal = try XCTUnwrap(Decimal(string: "120.01"))
        let oddCart = [CartItem(name: "Odd item", category: .accessories, price: oddPrice)]

        let result = try calculate([.percentage(percent: 10)], cart: oddCart)

        assertDecimalEqual(result.steps[0].discountApplied, expectedDiscount)
        assertDecimalEqual(result.finalPrice, expectedFinal)
    }

    func testPercentageAbove100Throws() {
        assertThrows(.percentageOutOfRange(150), campaigns: [.percentage(percent: 150)])
    }

    func testNegativePercentageThrows() {
        assertThrows(.percentageOutOfRange(-1), campaigns: [.percentage(percent: -1)])
    }
}
