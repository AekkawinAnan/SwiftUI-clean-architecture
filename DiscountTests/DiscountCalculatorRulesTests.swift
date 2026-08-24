//
//  DiscountCalculatorRulesTests.swift
//  DiscountTests
//

import XCTest
@testable import Discount

/// กติกาข้อ 1 และ 2, ฉาก pipeline เต็ม และ edge cases ที่เหลือ.
/// ทุก test เขียนตามโครงสร้าง Given–When–Then.
final class DiscountCalculatorRulesAndEdgeCaseTests: DiscountCalculatorTestCase {

    // MARK: กติกาข้อ 1 — หนึ่งหมวดหมู่เลือกได้สูงสุด 1 แคมเปญ

    func testDuplicateCampaignsInSameCategoryKeepOnlyTheFirst() throws {
        // Given: ส่งคูปองสองตัว (ลด 10% และลดคงที่ 100) ในหมวดหมู่เดียวกัน
        let campaigns: [DiscountCampaign] = [
            .percentage(percent: 10),
            .fixedAmount(amount: 100),
        ]

        // When: คำนวณส่วนลด
        let result = try calculate(campaigns)

        // Then: เอนจินเก็บเฉพาะตัวแรก (10%) ส่วนตัวที่สองถูกตัดทิ้ง
        XCTAssertEqual(result.steps.count, 1)
        assertDecimalEqual(result.finalPrice, 1215)
    }

    // MARK: กติกาข้อ 2 — ลำดับคูปอง → On Top → Seasonal อย่างเคร่งครัด

    func testCampaignsAreAlwaysOrderedCouponOnTopSeasonal() throws {
        // Given: ส่งแคมเปญครบ 3 หมวดหมู่แต่เรียงผิดลำดับ (seasonal → points → coupon)
        // พร้อมชุดเดียวกันที่เรียงตามลำดับมาตรฐาน เพื่อใช้เทียบผลลัพธ์
        let outOfOrder: [DiscountCampaign] = [
            .seasonal(perAmount: 300, discount: 40),
            .points(count: 243),
            .percentage(percent: 10),
        ]
        let canonical: [DiscountCampaign] = [
            .percentage(percent: 10),
            .points(count: 243),
            .seasonal(perAmount: 300, discount: 40),
        ]

        // When: คำนวณทั้งสองชุด
        let result = try calculate(outOfOrder)
        let canonicalResult = try calculate(canonical)

        // Then: ผลลัพธ์เรียงตาม coupon/on-top/seasonal และเท่ากับชุดมาตรฐานทุกประการ
        XCTAssertEqual(result.steps.map(\.campaign.category), [.coupon, .onTop, .seasonal])
        XCTAssertEqual(
            result.steps.map(\.discountApplied),
            canonicalResult.steps.map(\.discountApplied)
        )
        XCTAssertEqual(result.finalPrice, canonicalResult.finalPrice)
    }

    func testOutputOfEachStepFeedsTheNextStep() throws {
        // Given: pipeline ครบ 3 ขั้น — คูปอง 10%, คะแนน 300, seasonal ทุก 300 ลด 40
        let campaigns: [DiscountCampaign] = [
            .percentage(percent: 10),
            .points(count: 300),
            .seasonal(perAmount: 300, discount: 40),
        ]

        // When: คำนวณส่วนลด
        let result = try calculate(campaigns)

        // Then: amountAfter ของแต่ละขั้นต้องเท่ากับ amountBefore ของขั้นถัดไป
        // (1350 → 1215 → 972 → 852)
        XCTAssertEqual(result.steps.count, 3)
        assertDecimalEqual(result.steps[0].amountBefore, 1350)
        assertDecimalEqual(result.steps[0].amountAfter, 1215)
        assertDecimalEqual(result.steps[1].amountBefore, 1215)
        assertDecimalEqual(result.steps[1].amountAfter, 972)
        assertDecimalEqual(result.steps[2].amountBefore, 972)
        assertDecimalEqual(result.steps[2].amountAfter, 852)
    }

    // MARK: ฉาก pipeline เต็ม (ตัวอย่างที่คำนวณครบทุกขั้น)

    func testFullPipelineScenario() throws {
        // Given: คูปอง 10% + คะแนน 300 + seasonal ทุก 300 ลด 40
        let campaigns: [DiscountCampaign] = [
            .percentage(percent: 10),
            .points(count: 300),
            .seasonal(perAmount: 300, discount: 40),
        ]

        // When: คำนวณส่วนลดครบทุกขั้น
        // (1350 → −135 → 1215 → cap 243 → 972 → floor(972/300)=3 → −120 → 852)
        let result = try calculate(campaigns)

        // Then: ส่วนลดรายขั้น [135, 243, 120] ราคาสุดท้าย 852 ส่วนลดรวม 498
        XCTAssertEqual(result.steps.map(\.discountApplied), [135, 243, 120])
        assertDecimalEqual(result.finalPrice, 852)
        assertDecimalEqual(result.totalDiscount, 498)
    }

    // MARK: Edge cases ของตะกร้าว่าง

    func testEmptyCartWithNoCampaigns() throws {
        // Given: ตะกร้าว่าง และไม่เลือกแคมเปญใด
        let emptyCart: [CartItem] = []
        let campaigns: [DiscountCampaign] = []

        // When: คำนวณส่วนลด
        let result = try calculate(campaigns, cart: emptyCart)

        // Then: ทุกยอดเป็นศูนย์ และไม่มี step เกิดขึ้น
        assertDecimalEqual(result.subtotal, 0)
        assertDecimalEqual(result.finalPrice, 0)
        XCTAssertTrue(result.steps.isEmpty)
    }

    func testEmptyCartWithCampaignsNeverProducesNegativePrices() throws {
        // Given: ตะกร้าว่าง แต่เลือกคูปองลดคงที่ 100 บาท
        let emptyCart: [CartItem] = []
        let campaigns: [DiscountCampaign] = [.fixedAmount(amount: 100)]

        // When: คำนวณส่วนลด
        let result = try calculate(campaigns, cart: emptyCart)

        // Then: ไม่มีอะไรให้ลด ราคาสุดท้ายเป็นศูนย์ (ห้ามติดลบ)
        XCTAssertEqual(result.steps.count, 1)
        assertDecimalEqual(result.steps[0].discountApplied, 0)
        assertDecimalEqual(result.finalPrice, 0)
    }
}
