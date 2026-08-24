//
//  CartViewModel.swift
//  Discount
//

import Foundation
import Observation

/// Manages cart state, campaign selection (Business Rule 1) and drives the
/// `DiscountCalculator` engine. Rebuilds the result whenever any input changes.
@MainActor
@Observable
final class CartViewModel {

    // MARK: Dependencies (injected → easy to unit test / swap implementations)

    private let calculator: any DiscountCalculating

    // MARK: State

    private(set) var cartItems: [CartItem]

    // One option per category — Rule 1 (max 1 campaign per category) is
    // enforced by design because there is exactly one selection slot each.
    var couponOption: CouponOption = .none { didSet { recalculate() } }
    var onTopOption: OnTopOption = .none { didSet { recalculate() } }
    var seasonalOption: SeasonalOption = .none { didSet { recalculate() } }

    /// Only relevant when an "…% Off Category" on-top option is selected.
    var onTopCategory: ItemCategory = .clothing { didSet { recalculate() } }

    /// Free-form text field backing the points campaign.
    var pointsText: String = "" { didSet { recalculate() } }

    // Output state
    private(set) var result: DiscountCalculationResult
    private(set) var lastError: DiscountError?

    // MARK: Init

    init(
        calculator: any DiscountCalculating = DiscountCalculator(),
        cartItems: [CartItem] = CartItem.mockCart
    ) {
        self.calculator = calculator
        self.cartItems = cartItems
        self.result = DiscountCalculationResult(subtotal: 0, steps: [], finalPrice: 0)
        recalculate()
    }

    // MARK: Derived state

    /// All currently selected campaigns — at most one per category (Rule 1).
    var selectedCampaigns: [DiscountCampaign] {
        [
            couponOption.campaign,
            onTopOption.campaign(category: onTopCategory, pointsText: pointsText),
            seasonalOption.campaign,
        ]
        .compactMap(\.self)
    }

    /// Non-nil when the user picked "Redeem Points" but typed something unusable.
    var pointsInputError: String? {
        guard onTopOption == .points else { return nil }
        let parsed = OnTopOption.parsedPoints(from: pointsText)
        if parsed == nil {
            return "Enter a valid, non-negative number of points."
        }
        if parsed == 0 {
            return "Points must be greater than zero to apply."
        }
        return nil
    }

    /// True when at least one campaign is active.
    var hasSelection: Bool { !selectedCampaigns.isEmpty }

    // MARK: Actions

    /// Clears every selection back to a pristine state.
    func reset() {
        couponOption = .none
        onTopOption = .none
        seasonalOption = .none
        onTopCategory = .clothing
        pointsText = ""
    }

    // MARK: Private

    private func recalculate() {
        do {
            lastError = nil
            result = try calculator.calculate(
                cartItems: cartItems,
                campaigns: selectedCampaigns
            )
        } catch {
            // Defensive fallback: show undiscounted totals and surface the problem.
            let subtotal = Decimal.roundedMoney(
                cartItems.reduce(Decimal.zero) { $0 + $1.lineTotal }
            )
            result = DiscountCalculationResult(subtotal: subtotal, steps: [], finalPrice: subtotal)
            lastError = error as? DiscountError ?? nil
        }
    }
}
