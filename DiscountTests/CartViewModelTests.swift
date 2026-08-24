//
//  CartViewModelTests.swift
//  DiscountTests
//

import XCTest
@testable import Discount

/// ViewModel behavior: Rule-1 selection slots, points input validation,
/// live recalculation, and reset.
@MainActor
final class CartViewModelTests: XCTestCase {

    func testViewModelAllowsAtMostOneCampaignPerCategory() {
        // Given: one selection per category slot (Rule 1 by design).
        let viewModel = CartViewModel()
        viewModel.couponOption = .percentage(10)
        viewModel.onTopOption = .categoryPercentage(percent: 20)
        viewModel.seasonalOption = .seasonal(perAmount: 300, discount: 40)

        // Then: three campaigns, exactly one per category, in pipeline order.
        let selected = viewModel.selectedCampaigns
        XCTAssertEqual(selected.count, 3)
        XCTAssertEqual(selected.map(\.category), [.coupon, .onTop, .seasonal])
    }

    func testViewModelInvalidPointsTextYieldsNoOnTopCampaign() {
        let viewModel = CartViewModel()
        viewModel.onTopOption = .points
        viewModel.pointsText = "abc"

        // Invalid input → no campaign is built, no error thrown, price untouched.
        XCTAssertTrue(viewModel.selectedCampaigns.isEmpty)
        XCTAssertNotNil(viewModel.pointsInputError)
        XCTAssertEqual(viewModel.result.finalPrice, viewModel.result.subtotal)
    }

    func testViewModelNegativePointsTextIsRejected() {
        let viewModel = CartViewModel()
        viewModel.onTopOption = .points
        viewModel.pointsText = "-5"

        XCTAssertTrue(viewModel.selectedCampaigns.isEmpty)
        XCTAssertNotNil(viewModel.pointsInputError)
    }

    func testViewModelValidPointsProduceResultAndClearInputError() {
        let viewModel = CartViewModel()
        viewModel.onTopOption = .points
        viewModel.pointsText = "200"

        XCTAssertNil(viewModel.pointsInputError)
        XCTAssertEqual(viewModel.selectedCampaigns.count, 1)
        XCTAssertEqual(viewModel.result.steps.first?.campaign.category, .onTop)
    }

    func testResetClearsEverything() {
        let viewModel = CartViewModel()
        viewModel.couponOption = .fixedAmount(100)
        viewModel.seasonalOption = .seasonal(perAmount: 300, discount: 40)

        viewModel.reset()

        XCTAssertTrue(viewModel.selectedCampaigns.isEmpty)
        XCTAssertTrue(viewModel.result.steps.isEmpty)
        XCTAssertEqual(viewModel.result.finalPrice, viewModel.result.subtotal)
    }

    func testLiveRecalculationReflectsSelectionChanges() {
        let viewModel = CartViewModel()
        // Subtotal of the mock cart: 700 + 999 + 250 + 1299 = 3248
        assertDecimalEqual(viewModel.result.subtotal, 3248)
        XCTAssertEqual(viewModel.result.finalPrice, viewModel.result.subtotal)

        viewModel.couponOption = .fixedAmount(250)
        assertDecimalEqual(viewModel.result.finalPrice, 3248 - 250)

        viewModel.seasonalOption = .seasonal(perAmount: 300, discount: 40)
        // 3248 − 250 = 2998 → floor(2998/300) = 9 buckets → −360 → 2638
        XCTAssertEqual(viewModel.result.steps.map(\.campaign.category), [.coupon, .seasonal])
        XCTAssertEqual(viewModel.result.steps[1].discountApplied, 360)
        XCTAssertEqual(viewModel.result.finalPrice, 2638)
    }
}
