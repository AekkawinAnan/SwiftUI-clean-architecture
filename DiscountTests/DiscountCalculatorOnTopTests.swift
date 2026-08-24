//
//  DiscountCalculatorOnTopTests.swift
//  DiscountTests
//

import XCTest
@testable import Discount

/// On Top campaigns: Percentage by Item Category and Points (with the 20% cap).
final class DiscountCalculatorOnTopTests: DiscountCalculatorTestCase {

    // MARK: Percentage by Item Category

    func testCategoryPercentageUsesOnlyCategorySubtotalAsBasis() throws {
        // Clothing subtotal = 1000 → 20% = 200 (NOT 20% of the 1350 total).
        let result = try calculate([.percentageByCategory(percent: 20, category: .clothing)])
        assertDecimalEqual(result.steps[0].discountApplied, 200)
        assertDecimalEqual(result.finalPrice, 1150)
    }

    func testCategoryPercentageWithCategoryNotInCartAppliesNothing() throws {
        let clothingOnly = [CartItem(name: "Shirt", category: .clothing, price: 500, quantity: 2)]
        let result = try calculate(
            [.percentageByCategory(percent: 50, category: .electronics)],
            cart: clothingOnly
        )
        assertDecimalEqual(result.steps[0].discountApplied, 0)
        assertDecimalEqual(result.finalPrice, 1000)
    }

    func testCategoryPercentageCannotExceedCurrentTotal() throws {
        // Coupon first leaves only 50 THB; a raw 20% of clothing (200) is clamped to 50.
        let result = try calculate([
            .fixedAmount(amount: 1300),
            .percentageByCategory(percent: 20, category: .clothing),
        ])
        XCTAssertEqual(result.steps[0].campaign.category, .coupon)
        XCTAssertEqual(result.steps[1].campaign.category, .onTop)
        assertDecimalEqual(result.steps[1].discountApplied, 50)
        assertDecimalEqual(result.finalPrice, 0)
        XCTAssertEqual(result.steps[1].note, "Limited to remaining total")
    }

    func testNegativeCategoryPercentageThrows() {
        assertThrows(
            .percentageOutOfRange(-10),
            campaigns: [.percentageByCategory(percent: -10, category: .clothing)]
        )
    }

    // MARK: Points — 1 pt = 1 THB, capped at 20% of CURRENT total

    func testPointsBelowCapApplyOneToOne() throws {
        let result = try calculate([.points(count: 100)])
        assertDecimalEqual(result.steps[0].discountApplied, 100)
        assertDecimalEqual(result.finalPrice, 1250)
        XCTAssertNil(result.steps[0].note)
    }

    func testPointsExactlyAtCapApplyFully() throws {
        // Cap = 20% of 1350 = 270. Requesting exactly 270 applies fully.
        let result = try calculate([.points(count: 270)])
        assertDecimalEqual(result.steps[0].discountApplied, 270)
        assertDecimalEqual(result.finalPrice, 1080)
    }

    func testPointsAboveCapAreCappedAt20PercentOfCurrentTotal() throws {
        // Cap = 270; requesting 300 still discounts only 270.
        let result = try calculate([.points(count: 300)])
        assertDecimalEqual(result.steps[0].discountApplied, 270)
        assertDecimalEqual(result.finalPrice, 1080)
        XCTAssertNotNil(result.steps[0].note, "A note should explain why capping kicked in")
    }

    func testPointsCapIsBasedOnPostCouponTotalNotSubtotal() throws {
        // Crucial spec detail: coupon runs FIRST, so the cap uses 850, not 1350.
        // Cap = 20% × 850 = 170.
        let result = try calculate([
            .fixedAmount(amount: 500),
            .points(count: 300),
        ])
        assertDecimalEqual(result.steps[0].amountAfter, 850)
        assertDecimalEqual(result.steps[1].discountApplied, 170)
        assertDecimalEqual(result.finalPrice, 680)
    }

    func testZeroPointsApplyNothing() throws {
        let result = try calculate([.points(count: 0)])
        assertDecimalEqual(result.steps[0].discountApplied, 0)
        assertDecimalEqual(result.finalPrice, 1350)
    }

    func testNegativePointsThrow() {
        // "Incorrect points input" edge case: negative points are rejected loudly.
        assertThrows(.negativePoints, campaigns: [.points(count: -50)])
    }
}
