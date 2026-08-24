//
//  DiscountCalculator.swift
//  Discount
//

import Foundation

// MARK: - Abstraction (Dependency Inversion: the ViewModel depends on this protocol)

/// `nonisolated`: the engine is pure and thread-free — callable from any actor.
nonisolated protocol DiscountCalculating {
    /// Applies the selected campaigns following Business Rule 2
    /// (Coupon → On Top → Seasonal) and returns a step-by-step breakdown
    /// plus the final price.
    ///
    /// - Throws: `DiscountError` for invalid campaign configurations.
    func calculate(
        cartItems: [CartItem],
        campaigns: [DiscountCampaign]
    ) throws -> DiscountCalculationResult
}

// MARK: - Engine

/// Pure, stateless calculation engine. No UI/framework dependencies → trivially unit-testable.
/// `nonisolated`: pure domain logic, callable from any actor (project defaults to MainActor).
nonisolated struct DiscountCalculator: DiscountCalculating {

    /// Business rule: points can never discount more than 20% of the current total.
    static let pointsCapPercent: Decimal = 20

    func calculate(
        cartItems: [CartItem],
        campaigns: [DiscountCampaign]
    ) throws -> DiscountCalculationResult {
        // Fail fast on nonsensical configurations (negative amounts, % > 100, ...).
        for campaign in campaigns {
            try Self.validate(campaign)
        }

        // --- Step 0: Subtotal ----------------------------------------------
        // Math: subtotal = Σ (unit price × quantity) over all line items.
        // This is the input of the discount pipeline.
        let subtotal = Decimal.roundedMoney(
            cartItems.reduce(Decimal.zero) { $0 + $1.lineTotal }
        )

        // --- Rules 1 & 2 are enforced HERE, not only in the UI --------------
        // Even if this engine receives [seasonal, onTop, coupon] or duplicates,
        // output is deterministic and spec-compliant.
        let pipeline = Self.pipeline(from: campaigns)

        var currentTotal = subtotal
        var steps: [DiscountStep] = []

        // The output of each step becomes the input of the next one.
        for campaign in pipeline {
            let step = apply(campaign, to: currentTotal, cartItems: cartItems)
            steps.append(step)
            currentTotal = step.amountAfter
        }

        // Edge case: the final price can never drop below zero.
        let finalPrice = max(Decimal.roundedMoney(currentTotal), Decimal.zero)

        return DiscountCalculationResult(
            subtotal: subtotal,
            steps: steps,
            finalPrice: finalPrice
        )
    }

    // MARK: Pipeline construction (Rules 1 & 2)

    /// Sorts campaigns by category order (Coupon → On Top → Seasonal) and keeps
    /// only the FIRST campaign per category (Business Rule 1).
    static func pipeline(from campaigns: [DiscountCampaign]) -> [DiscountCampaign] {
        var seenCategories = Set<DiscountCategory>()
        return campaigns
            .sorted { $0.category.applicationOrder < $1.category.applicationOrder }
            .filter { seenCategories.insert($0.category).inserted }
    }

    // MARK: Validation (throws on invalid input, never on "too big" discounts)

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

    // MARK: Single-step application

    /// Applies one campaign to `total` and returns the resulting `DiscountStep`.
    /// Every branch documents its math and clamps over-discounting gracefully.
    private func apply(
        _ campaign: DiscountCampaign,
        to total: Decimal,
        cartItems: [CartItem]
    ) -> DiscountStep {
        let discount: Decimal
        var note: String?

        switch campaign {

        case .fixedAmount(let amount):
            // Math: after = total − amount, but never below zero.
            discount = min(total, amount)

        case .percentage(let percent):
            // Math: discount = total × percent / 100.
            // Since 0 ≤ percent ≤ 100 was validated, the result stays ≥ 0 automatically.
            discount = Decimal.roundedMoney(total * percent / 100)

        case .percentageByCategory(let percent, let category):
            // Math: the percentage basis is ONLY the subtotal of the matching
            // category — NOT the whole running total. The result is then
            // subtracted from the current total.
            let categorySubtotal = cartItems
                .filter { $0.category == category }
                .reduce(Decimal.zero) { $0 + $1.lineTotal }
            let rawDiscount = Decimal.roundedMoney(categorySubtotal * percent / 100)
            // Edge case: even a category-based discount cannot exceed the current total.
            if rawDiscount > total {
                discount = total
                note = "Limited to remaining total"
            } else {
                discount = rawDiscount
            }

        case .points(let requestedPoints):
            // Math: Cap = 20% × CURRENT total (i.e., AFTER the coupon step).
            // Real discount = min(requestedPoints, cap). 1 pt = 1 THB.
            let cap = Decimal.roundedMoney(total * Self.pointsCapPercent / 100)
            if requestedPoints > cap {
                discount = cap
                note = "Capped at \(Self.pointsCapPercent)% of current total"
            } else {
                discount = requestedPoints
            }

        case .seasonal(let perAmount, let discountPerBucket):
            // Math: bucketCount = floor(total / X) — the remainder does not earn a bucket.
            // discount = bucketCount × Y, clamped so the total never goes below zero.
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
