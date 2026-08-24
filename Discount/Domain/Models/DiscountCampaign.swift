//
//  DiscountCampaign.swift
//  Discount
//

import Foundation

// MARK: - Discount Categories (Business Rule 1: MAX 1 campaign per category)

/// The three discount categories. The user may select at most one campaign from each.
nonisolated enum DiscountCategory: String, Codable, CaseIterable, Hashable, Identifiable {
    case coupon
    case onTop = "on_top"
    case seasonal

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .coupon: "Coupon"
        case .onTop: "On Top"
        case .seasonal: "Seasonal"
        }
    }

    /// Encodes Business Rule 2: campaigns MUST be applied Coupon → On Top → Seasonal.
    var applicationOrder: Int {
        switch self {
        case .coupon: 0
        case .onTop: 1
        case .seasonal: 2
        }
    }
}

// MARK: - Campaigns (enum with associated values)

/// A single, immutable, type-safe description of one discount campaign.
/// Associated values make it impossible to construct, e.g., a percentage discount
/// without a rate, or a seasonal campaign without both X and Y.
nonisolated enum DiscountCampaign: Hashable, Codable {
    /// **Coupon** — subtracts a fixed THB amount from the total.
    case fixedAmount(amount: Decimal)

    /// **Coupon** — subtracts `percent`% (0...100) from the total.
    case percentage(percent: Decimal)

    /// **On Top** — `percent`% calculated ONLY from the subtotal of items
    /// in `category`, then subtracted from the current total.
    case percentageByCategory(percent: Decimal, category: ItemCategory)

    /// **On Top** — 1 point = 1 THB; capped at 20% of the CURRENT total (post-coupon).
    case points(count: Decimal)

    /// **Seasonal** — for every `perAmount` THB of the CURRENT total
    /// (post-coupon, post-on-top), subtract `discount` THB.
    case seasonal(perAmount: Decimal, discount: Decimal)

    /// Which of the three categories this campaign belongs to (drives Rules 1 & 2).
    var category: DiscountCategory {
        switch self {
        case .fixedAmount, .percentage: .coupon
        case .percentageByCategory, .points: .onTop
        case .seasonal: .seasonal
        }
    }

    /// Human-readable name used by the breakdown UI and pickers.
    var displayName: String {
        switch self {
        case .fixedAmount(let amount):
            "Fixed Amount (−\(amount) THB)"
        case .percentage(let percent):
            "\(percent)% Off Total"
        case .percentageByCategory(let percent, let itemCategory):
            "\(percent)% Off \(itemCategory.displayName)"
        case .points:
            "Redeem Points (1 pt = 1 THB)"
        case .seasonal(let perAmount, let discount):
            "Special: Every \(perAmount) THB −\(discount) THB"
        }
    }
}
