//
//  DecimalExtensions.swift
//  Discount
//

import Foundation

extension Decimal {
    /// ปัดเศษค่าเงินเหลือ 2 ตำแหน่งด้วยโหมด `.plain`
    /// (ปัดครึ่งออกจากศูนย์ — วิธีเดียวกับที่ระบบ POS/ใบเสร็จจริงใช้).
    nonisolated static func roundedMoney(_ value: Decimal) -> Decimal {
        value.rounded(toScale: 2)
    }

    /// ปัดลงเป็นจำนวนเต็ม ใช้นับว่ายอดรวมปัจจุบันมีกี่ก้อน
    /// "ทุก X บาท" แบบเต็ม ๆ.
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

    /// ตัวช่วยฝั่ง presentation: จัดรูปแบบเป็นเงินบาทไทย เช่น "฿1,234.56".
    var thb: String { formatted(.currency(code: "THB")) }
}
