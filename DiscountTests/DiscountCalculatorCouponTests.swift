//
//  DiscountCalculatorCouponTests.swift
//  DiscountTests
//

import XCTest
@testable import Discount

/// แคมเปญคูปอง: จำนวนเงินคงที่ และแบบเปอร์เซ็นต์.
/// ทุก test เขียนตามโครงสร้าง Given–When–Then.
final class DiscountCalculatorCouponTests: DiscountCalculatorTestCase {

    // MARK: Subtotal

    func testSubtotalSumsLineTotals() throws {
        // Given: ตะกร้า mock (500×2 + 200×1 + 150×1) โดยไม่เลือกแคมเปญใด
        let campaigns: [DiscountCampaign] = []

        // When: คำนวณส่วนลด
        let result = try calculate(campaigns)

        // Then: subtotal = 1,350 และราคาสุดท้ายเท่ากับ subtotal
        assertDecimalEqual(result.subtotal, 1350, "1000 + 200 + 150")
        XCTAssertEqual(result.finalPrice, result.subtotal)
        XCTAssertTrue(result.steps.isEmpty)
    }

    // MARK: จำนวนเงินคงที่

    func testFixedAmountCouponSubtractsFromTotal() throws {
        // Given: คูปองลดคงที่ 100 บาท
        let campaigns: [DiscountCampaign] = [.fixedAmount(amount: 100)]

        // When: คำนวณส่วนลด
        let result = try calculate(campaigns)

        // Then: หัก 100 บาทจากยอดรวม
        XCTAssertEqual(result.steps.count, 1)
        assertDecimalEqual(result.steps[0].discountApplied, 100)
        assertDecimalEqual(result.finalPrice, 1250)
    }

    func testFixedAmountLargerThanTotalClampsToZero() throws {
        // Given: คูปองลดคงที่ 2,000 บาท ซึ่งมากกว่ายอดรวม 1,350
        let campaigns: [DiscountCampaign] = [.fixedAmount(amount: 2000)]

        // When: คำนวณส่วนลด
        let result = try calculate(campaigns)

        // Then: ลดได้มากสุดเท่ายอดรวม และราคาสุดท้ายเป็นศูนย์
        assertDecimalEqual(result.steps[0].discountApplied, 1350)
        assertDecimalEqual(result.finalPrice, 0)
    }

    func testNegativeFixedAmountThrows() {
        // Given: คูปองลดคงที่ที่ระบุจำนวนติดลบ
        let campaigns: [DiscountCampaign] = [.fixedAmount(amount: -5)]

        // When & Then: ต้อง throw .negativeFixedAmount
        assertThrows(.negativeFixedAmount, campaigns: campaigns)
    }

    // MARK: เปอร์เซ็นต์

    func testPercentageCoupon() throws {
        // Given: คูปองลด 10%
        let campaigns: [DiscountCampaign] = [.percentage(percent: 10)]

        // When: คำนวณส่วนลด
        let result = try calculate(campaigns)

        // Then: ลด 10% ของ 1,350 = 135
        assertDecimalEqual(result.steps[0].discountApplied, 135)
        assertDecimalEqual(result.finalPrice, 1215)
    }

    func testPercentageCoupon100PercentLeavesZero() throws {
        // Given: คูปองลด 100%
        let campaigns: [DiscountCampaign] = [.percentage(percent: 100)]

        // When: คำนวณส่วนลด
        let result = try calculate(campaigns)

        // Then: ราคาสุดท้ายเป็นศูนย์
        assertDecimalEqual(result.finalPrice, 0)
    }

    func testPercentageCouponRoundsHalfAwayFromZero() throws {
        // Given: สินค้าราคา 133.35 บาท (สร้างจาก String เพื่อความแม่นยำของ Decimal)
        // และคูปองลด 10%
        let oddPrice = try XCTUnwrap(Decimal(string: "133.35"))
        let expectedDiscount = try XCTUnwrap(Decimal(string: "13.34"))
        let expectedFinal = try XCTUnwrap(Decimal(string: "120.01"))
        let oddCart = [CartItem(name: "Odd item", category: .accessories, price: oddPrice)]
        let campaigns: [DiscountCampaign] = [.percentage(percent: 10)]

        // When: คำนวณส่วนลด (133.35 × 10% = 13.335)
        let result = try calculate(campaigns, cart: oddCart)

        // Then: ปัดครึ่งออกจากศูนย์ได้ 13.34 และราคาสุดท้าย 120.01
        assertDecimalEqual(result.steps[0].discountApplied, expectedDiscount)
        assertDecimalEqual(result.finalPrice, expectedFinal)
    }

    func testPercentageAbove100Throws() {
        // Given: คูปองลด 150% (เกินช่วงที่กำหนด)
        let campaigns: [DiscountCampaign] = [.percentage(percent: 150)]

        // When & Then: ต้อง throw .percentageOutOfRange(150)
        assertThrows(.percentageOutOfRange(150), campaigns: campaigns)
    }

    func testNegativePercentageThrows() {
        // Given: คูปองลด -1%
        let campaigns: [DiscountCampaign] = [.percentage(percent: -1)]

        // When & Then: ต้อง throw .percentageOutOfRange(-1)
        assertThrows(.percentageOutOfRange(-1), campaigns: campaigns)
    }
}
