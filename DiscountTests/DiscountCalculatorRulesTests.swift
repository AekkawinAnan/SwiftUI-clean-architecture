//
//  DiscountCalculatorRulesTests.swift
//  DiscountTests
//

import XCTest
@testable import Discount

/// Business Rules 1 & 2, the full-pipeline scenario, and remaining edge cases.
final class DiscountCalculatorRulesAndEdgeCaseTests: DiscountCalculatorTestCase {

    // MARK: Rule 1 — max one campaign per category

    func testDuplicateCampaignsInSameCategoryKeepOnlyTheFirst() throws {
        // Both are coupons → only the first (10%) survives.
        let result = try calculate([
            .percentage(percent: 10),
            .fixedAmount(amount: 100),
        ])
        XCTAssertEqual(result.steps.count, 1)
        assertDecimalEqual(result.finalPrice, 1215)
    }

    // MARK: Rule 2 — strict Coupon → On Top → Seasonal order

    func testCampaignsAreAlwaysOrderedCouponOnTopSeasonal() throws {
        let result = try calculate([
            .seasonal(perAmount: 300, discount: 40),   // given out of order…
            .points(count: 243),                       // …on top second…
            .percentage(percent: 10),                  // …coupon last.
        ])

        // Order is enforced regardless of input order.
        XCTAssertEqual(result.steps.map(\.campaign.category), [.coupon, .onTop, .seasonal])

        // And equals the result computed in canonical order.
        let canonical = try calculate([
            .percentage(percent: 10),
            .points(count: 243),
            .seasonal(perAmount: 300, discount: 40),
        ])
        XCTAssertEqual(result.steps.map(\.discountApplied), canonical.steps.map(\.discountApplied))
        XCTAssertEqual(result.finalPrice, canonical.finalPrice)
    }

    func testOutputOfEachStepFeedsTheNextStep() throws {
        // Chain check on amountBefore/amountAfter linkage.
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

    // MARK: Full pipeline scenario (the worked example)

    func testFullPipelineScenario() throws {
        // Subtotal 1350 → 10% coupon → 1215 → 300 pts capped at 20% (=243) → 972
        // → seasonal every-300-get-40: floor(972/300)=3 → −120 → FINAL 852.
        let result = try calculate([
            .percentage(percent: 10),
            .points(count: 300),
            .seasonal(perAmount: 300, discount: 40),
        ])
        XCTAssertEqual(result.steps.map(\.discountApplied), [135, 243, 120])
        assertDecimalEqual(result.finalPrice, 852)
        assertDecimalEqual(result.totalDiscount, 498)
    }

    // MARK: Empty cart edge cases

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
