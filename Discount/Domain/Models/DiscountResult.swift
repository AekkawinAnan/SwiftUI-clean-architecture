//
//  DiscountResult.swift
//  Discount
//

import Foundation

/// One row of the step-by-step breakdown: what was applied, on what amount,
/// how much was discounted, and what remained afterwards.
nonisolated struct DiscountStep: Identifiable, Hashable {
    let id: UUID
    let campaign: DiscountCampaign
    /// Total BEFORE this campaign was applied (input).
    let amountBefore: Decimal
    /// How much this campaign actually discounted (after caps/clamps).
    let discountApplied: Decimal
    /// Total AFTER this campaign was applied (output → next step's input).
    let amountAfter: Decimal
    /// Optional human-readable explanation, e.g. why a cap kicked in.
    let note: String?

    init(
        id: UUID = UUID(),
        campaign: DiscountCampaign,
        amountBefore: Decimal,
        discountApplied: Decimal,
        amountAfter: Decimal,
        note: String? = nil
    ) {
        self.id = id
        self.campaign = campaign
        self.amountBefore = amountBefore
        self.discountApplied = discountApplied
        self.amountAfter = amountAfter
        self.note = note
    }
}

/// The complete outcome of a calculation: subtotal, every applied step, final price.
nonisolated struct DiscountCalculationResult: Hashable {
    let subtotal: Decimal
    let steps: [DiscountStep]
    let finalPrice: Decimal

    /// Math: total savings = subtotal − final price.
    var totalDiscount: Decimal { subtotal - finalPrice }

    var hasAnyDiscount: Bool { !steps.isEmpty }
}

// MARK: - Errors

/// Thrown for *invalid campaign configurations*. (Over-discounting is NOT an error —
/// it is gracefully clamped so the final price never drops below zero.)
nonisolated enum DiscountError: LocalizedError, Equatable {
    case negativeFixedAmount
    case percentageOutOfRange(Decimal)
    case negativePoints
    case invalidSeasonalConfiguration(perAmount: Decimal, discount: Decimal)

    var errorDescription: String? {
        switch self {
        case .negativeFixedAmount:
            "A fixed amount discount cannot be negative."
        case .percentageOutOfRange(let percent):
            "Percentage must be between 0 and 100 (got \(percent))."
        case .negativePoints:
            "Points cannot be negative."
        case .invalidSeasonalConfiguration(let perAmount, let discount):
            "Seasonal campaign requires 'per amount' > 0 and a non-negative discount "
                + "(got X=\(perAmount), Y=\(discount))."
        }
    }
}
