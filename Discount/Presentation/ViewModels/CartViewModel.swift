//
//  CartViewModel.swift
//  Discount
//

import Foundation
import Observation

/// จัดการ state ของตะกร้า การเลือกแคมเปญ (กติกาข้อ 1) และสั่งงาน
/// เอนจิน `DiscountCalculator` คำนวณ result ใหม่ทุกครั้งที่ input เปลี่ยน.
@MainActor
@Observable
final class CartViewModel {

    // MARK: Dependencies (inject เข้ามา → test ง่าย / เปลี่ยน implementation ได้)

    private let calculator: any DiscountCalculating

    // MARK: State (สถานะ)

    private(set) var cartItems: [CartItem]

    // หนึ่ง option ต่อหนึ่งหมวดหมู่ — กติกาข้อ 1 (เลือกได้หมวดละ 1 แคมเปญ)
    // ถูกบังคับด้วยการออกแบบ เพราะมี slot เลือกเพียง slot เดียวต่อหมวดหมู่.
    var couponOption: CouponOption = .none { didSet { recalculate() } }
    var onTopOption: OnTopOption = .none { didSet { recalculate() } }
    var seasonalOption: SeasonalOption = .none { didSet { recalculate() } }

    /// มีผลเฉพาะเมื่อเลือก option on-top แบบ "…% Off Category".
    var onTopCategory: ItemCategory = .clothing { didSet { recalculate() } }

    /// ช่องข้อความอิสระที่รองรับแคมเปญคะแนนสะสม.
    var pointsText: String = "" { didSet { recalculate() } }

    // State ผลลัพธ์
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

    // MARK: State ที่ derive เพิ่ม

    /// แคมเปญที่เลือกอยู่ทั้งหมด — ไม่เกินหมวดหมู่ละ 1 (กติกาข้อ 1).
    var selectedCampaigns: [DiscountCampaign] {
        [
            couponOption.campaign,
            onTopOption.campaign(category: onTopCategory, pointsText: pointsText),
            seasonalOption.campaign,
        ]
        .compactMap(\.self)
    }

    /// ไม่เป็น nil เมื่อผู้ใช้เลือก "Redeem Points" แต่พิมพ์ค่าที่ใช้งานไม่ได้.
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

    /// true เมื่อมีแคมเปญที่ใช้งานอยู่อย่างน้อยหนึ่งแคมเปญ.
    var hasSelection: Bool { !selectedCampaigns.isEmpty }

    // MARK: Actions

    /// เคลียร์ทุกการเลือกกลับสู่สถานะเริ่มต้น.
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
            // Fallback ป้องกันตัว: แสดงยอดแบบไม่หักส่วนลด และแจ้งปัญหาออกมา.
            let subtotal = Decimal.roundedMoney(
                cartItems.reduce(Decimal.zero) { $0 + $1.lineTotal }
            )
            result = DiscountCalculationResult(subtotal: subtotal, steps: [], finalPrice: subtotal)
            lastError = error as? DiscountError ?? nil
        }
    }
}
