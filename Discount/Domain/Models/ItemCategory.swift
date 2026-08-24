//
//  ItemCategory.swift
//  Discount
//

import Foundation

/// Product categories targeted by the "Percentage Discount by Item Category" on-top campaign.
/// `nonisolated`: pure domain value — no actor affinity (the project defaults to MainActor).
nonisolated enum ItemCategory: String, Codable, CaseIterable, Hashable {
    case clothing
    case accessories
    case electronics

    var displayName: String {
        switch self {
        case .clothing: "Clothing"
        case .accessories: "Accessories"
        case .electronics: "Electronics"
        }
    }
}
