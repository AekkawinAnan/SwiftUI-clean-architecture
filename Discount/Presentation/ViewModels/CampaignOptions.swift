//
//  CampaignOptions.swift
//  Discount
//

import Foundation

// MARK: - Picker-facing option models
//
// These wrap `DiscountCampaign` for SwiftUI `Picker`s. They keep Rule 1
// (max one campaign per category) trivially enforceable in the UI: the
// ViewModel stores exactly ONE option per category.

/// Options for the **Coupon** category.
enum CouponOption: Hashable, Identifiable {
    case none
    case fixedAmount(Decimal)
    case percentage(Decimal)

    var id: Self { self }

    var label: String {
        switch self {
        case .none: "None"
        case .fixedAmount(let amount): "−\(amount) THB Flat"
        case .percentage(let percent): "\(percent)% Off Total"
        }
    }

    var campaign: DiscountCampaign? {
        switch self {
        case .none: nil
        case .fixedAmount(let amount): .fixedAmount(amount: amount)
        case .percentage(let percent): .percentage(percent: percent)
        }
    }

    static let options: [CouponOption] = [
        .none,
        .fixedAmount(100),
        .fixedAmount(250),
        .percentage(10),
        .percentage(15),
    ]
}

/// Options for the **On Top** category.
enum OnTopOption: Hashable, Identifiable {
    case none
    case categoryPercentage(percent: Decimal)
    case points

    var id: Self { self }

    var label: String {
        switch self {
        case .none: "None"
        case .categoryPercentage(let percent): "\(percent)% Off Category"
        case .points: "Redeem Points"
        }
    }

    /// Builds the concrete campaign.
    /// Returns `nil` when the option is `.none` or when the free-form points
    /// input is missing/invalid/zero — defensive against bad text input.
    func campaign(category: ItemCategory, pointsText: String) -> DiscountCampaign? {
        switch self {
        case .none:
            return nil
        case .categoryPercentage(let percent):
            return .percentageByCategory(percent: percent, category: category)
        case .points:
            guard let points = Self.parsedPoints(from: pointsText), points > 0 else {
                return nil
            }
            return .points(count: points)
        }
    }

    /// Parses free-form user input into a non-negative point amount.
    /// Returns `nil` for empty or unparseable text (e.g. "abc", "-5").
    static func parsedPoints(from text: String) -> Decimal? {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, let value = Decimal(string: cleaned), value >= 0 else {
            return nil
        }
        return value
    }

    static let options: [OnTopOption] = [
        .none,
        .categoryPercentage(percent: 10),
        .categoryPercentage(percent: 20),
        .points,
    ]
}

/// Options for the **Seasonal** category ("for every X THB subtract Y THB").
enum SeasonalOption: Hashable, Identifiable {
    case none
    case seasonal(perAmount: Decimal, discount: Decimal)

    var id: Self { self }

    var label: String {
        switch self {
        case .none: "None"
        case .seasonal(let perAmount, let discount): "Every \(perAmount) THB −\(discount)"
        }
    }

    var campaign: DiscountCampaign? {
        switch self {
        case .none: nil
        case .seasonal(let perAmount, let discount):
            .seasonal(perAmount: perAmount, discount: discount)
        }
    }

    static let options: [SeasonalOption] = [
        .none,
        .seasonal(perAmount: 300, discount: 40),
        .seasonal(perAmount: 500, discount: 60),
        .seasonal(perAmount: 1000, discount: 150),
    ]
}
