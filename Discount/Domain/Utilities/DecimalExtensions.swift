//
//  DecimalExtensions.swift
//  Discount
//

import Foundation

extension Decimal {
    /// Rounds monetary values to 2 decimal places using `.plain`
    /// (half-away-from-zero — how real POS/receipt systems round).
    nonisolated static func roundedMoney(_ value: Decimal) -> Decimal {
        value.rounded(toScale: 2)
    }

    /// Floors to an integer value. Used to count how many full
    /// "every X THB" buckets fit into the current total.
    nonisolated static func floored(_ value: Decimal) -> Decimal {
        value.rounded(toScale: 0, rounding: .down)
    }

    nonisolated func rounded(
        toScale scale: Int,
        rounding: NSDecimalNumber.RoundingMode = .plain
    ) -> Decimal {
        (self as NSDecimalNumber).rounding(
            accordingToBehavior: NSDecimalNumberHandler(
                roundingMode: rounding,
                scale: Int16(scale),
                raiseOnExactness: false,
                raiseOnOverflow: false,
                raiseOnUnderflow: false,
                raiseOnDivideByZero: false
            )
        ) as Decimal
    }

    /// Presentation convenience: formats as Thai Baht, e.g. "฿1,234.56".
    var thb: String { formatted(.currency(code: "THB")) }
}
