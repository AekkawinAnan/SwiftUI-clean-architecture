//
//  DiscountCalculatorOnTopTests.swift
//  DiscountTests
//

import XCTest
@testable import Discount

/// แคมเปญ On Top: เปอร์เซ็นต์ตามหมวดหมู่สินค้า และคะแนนสะสม (พร้อมเพดาน 20%).
final class DiscountCalculatorOnTopTests: DiscountCalculatorTestCase {

    // MARK: เปอร์เซ็นต์ตามหมวดหมู่สินค้า

    func testCategoryPercentageUsesOnlyCategorySubtotalAsBasis() throws {
        // Subtotal ของเสื้อผ้า = 1000 → 20% = 200 (ไม่ใช่ 20% ของยอดรวม 1350).
        let result = try calculate([.percentageByCategory(percent: 20, category: .clothing)])
        assertDecimalEqual(result.steps[0].discountApplied, 200)
        assertDecimalEqual(result.finalPrice, 1150)
    }

    func testCategoryPercentageWithCategoryNotInCartAppliesNothing() throws {
        let clothingOnly = [CartItem(name: "Shirt", category: .clothing, price: 500, quantity: 2)]
        let result = try calculate(
            [.percentageByCategory(percent: 50, category: .electronics)],
            cart: clothingOnly
        )
        assertDecimalEqual(result.steps[0].discountApplied, 0)
        assertDecimalEqual(result.finalPrice, 1000)
    }

    func testCategoryPercentageCannotExceedCurrentTotal() throws {
        // คูปองใช้ก่อนเหลือยอดเพียง 50 บาท; 20% ของเสื้อผ้าดิบ ๆ (200) จึงถูก clamp เหลือ 50.
        let result = try calculate([
            .fixedAmount(amount: 1300),
            .percentageByCategory(percent: 20, category: .clothing),
        ])
        XCTAssertEqual(result.steps[0].campaign.category, .coupon)
        XCTAssertEqual(result.steps[1].campaign.category, .onTop)
        assertDecimalEqual(result.steps[1].discountApplied, 50)
        assertDecimalEqual(result.finalPrice, 0)
        XCTAssertEqual(result.steps[1].note, "Limited to remaining total")
    }

    func testNegativeCategoryPercentageThrows() {
        assertThrows(
            .percentageOutOfRange(-10),
            campaigns: [.percentageByCategory(percent: -10, category: .clothing)]
        )
    }

    // MARK: คะแนนสะสม — 1 คะแนน = 1 บาท จำกัดไม่เกิน 20% ของยอดรวม "ปัจจุบัน"

    func testPointsBelowCapApplyOneToOne() throws {
        let result = try calculate([.points(count: 100)])
        assertDecimalEqual(result.steps[0].discountApplied, 100)
        assertDecimalEqual(result.finalPrice, 1250)
        XCTAssertNil(result.steps[0].note)
    }

    func testPointsExactlyAtCapApplyFully() throws {
        // Cap = 20% ของ 1350 = 270. ขอใช้พอดี 270 จึงใช้ได้เต็มจำนวน.
        let result = try calculate([.points(count: 270)])
        assertDecimalEqual(result.steps[0].discountApplied, 270)
        assertDecimalEqual(result.finalPrice, 1080)
    }

    func testPointsAboveCapAreCappedAt20PercentOfCurrentTotal() throws {
        // Cap = 270; ขอใช้ 300 ก็ยังลดได้แค่ 270.
        let result = try calculate([.points(count: 300)])
        assertDecimalEqual(result.steps[0].discountApplied, 270)
        assertDecimalEqual(result.finalPrice, 1080)
        XCTAssertNotNil(result.steps[0].note, "A note should explain why capping kicked in")
    }

    func testPointsCapIsBasedOnPostCouponTotalNotSubtotal() throws {
        // รายละเอียดสำคัญของ spec: คูปองถูกใช้ "ก่อน" จึงคำนวณ cap จาก 850 ไม่ใช่ 1350.
        // Cap = 20% × 850 = 170.
        let result = try calculate([
            .fixedAmount(amount: 500),
            .points(count: 300),
        ])
        assertDecimalEqual(result.steps[0].amountAfter, 850)
        assertDecimalEqual(result.steps[1].discountApplied, 170)
        assertDecimalEqual(result.finalPrice, 680)
    }

    func testZeroPointsApplyNothing() throws {
        let result = try calculate([.points(count: 0)])
        assertDecimalEqual(result.steps[0].discountApplied, 0)
        assertDecimalEqual(result.finalPrice, 1350)
    }

    func testNegativePointsThrow() {
        // Edge case "input คะแนนไม่ถูกต้อง": คะแนนติดลบถูกปฏิเสธอย่างชัดเจน.
        assertThrows(.negativePoints, campaigns: [.points(count: -50)])
    }
}
