//
//  CartViewModelTests.swift
//  DiscountTests
//

import XCTest
@testable import Discount

/// พฤติกรรมของ ViewModel: slot เลือกแคมเปญตามกติกาข้อ 1 การ validate input คะแนน
/// การคำนวณใหม่แบบเรียลไทม์ และการ reset.
/// ทุก test เขียนตามโครงสร้าง Given–When–Then.
@MainActor
final class CartViewModelTests: XCTestCase {

    func testViewModelAllowsAtMostOneCampaignPerCategory() {
        // Given: ViewModel ที่เลือกแคมเปญครบทั้ง 3 หมวดหมู่ (slot ละ 1 ตามกติกาข้อ 1)
        let viewModel = CartViewModel()
        viewModel.couponOption = .percentage(10)
        viewModel.onTopOption = .categoryPercentage(percent: 20)
        viewModel.seasonalOption = .seasonal(perAmount: 300, discount: 40)

        // When: ดึงรายการแคมเปญที่เลือกอยู่
        let selected = viewModel.selectedCampaigns

        // Then: ได้สามแคมเปญ หมวดหมู่ละพอดีหนึ่ง ตามลำดับ pipeline
        XCTAssertEqual(selected.count, 3)
        XCTAssertEqual(selected.map(\.category), [.coupon, .onTop, .seasonal])
    }

    func testViewModelInvalidPointsTextYieldsNoOnTopCampaign() {
        // Given: ViewModel ที่จะเลือก option "Redeem Points"
        let viewModel = CartViewModel()

        // When: พิมพ์ข้อความคะแนนที่แปลงเป็นตัวเลขไม่ได้
        viewModel.onTopOption = .points
        viewModel.pointsText = "abc"

        // Then: ไม่สร้างแคมเปญ on-top มี error แจ้งเตือน และราคาไม่เปลี่ยน
        XCTAssertTrue(viewModel.selectedCampaigns.isEmpty)
        XCTAssertNotNil(viewModel.pointsInputError)
        XCTAssertEqual(viewModel.result.finalPrice, viewModel.result.subtotal)
    }

    func testViewModelNegativePointsTextIsRejected() {
        // Given: ViewModel ที่เลือก option "Redeem Points"
        let viewModel = CartViewModel()

        // When: พิมพ์จำนวนคะแนนติดลบ
        viewModel.onTopOption = .points
        viewModel.pointsText = "-5"

        // Then: input ถูกปฏิเสธ ไม่มีการสร้างแคมเปญ
        XCTAssertTrue(viewModel.selectedCampaigns.isEmpty)
        XCTAssertNotNil(viewModel.pointsInputError)
    }

    func testViewModelValidPointsProduceResultAndClearInputError() {
        // Given: ViewModel ที่เลือก option "Redeem Points"
        let viewModel = CartViewModel()

        // When: พิมพ์จำนวนคะแนนที่ถูกต้อง (200)
        viewModel.pointsText = "200"

        // When: พิมพ์จำนวนคะแนนที่ถูกต้อง (200)
        viewModel.onTopOption = .points
        viewModel.pointsText = "200"

        // Then: error หายไป และมีแคมเปญ on-top ถูกใช้ในผลลัพธ์
        XCTAssertNil(viewModel.pointsInputError)
        XCTAssertEqual(viewModel.selectedCampaigns.count, 1)
        XCTAssertEqual(viewModel.result.steps.first?.campaign.category, .onTop)
    }

    func testResetClearsEverything() {
        // Given: ViewModel ที่เลือกแคมเปญไว้แล้ว 2 หมวดหมู่
        let viewModel = CartViewModel()
        viewModel.couponOption = .fixedAmount(100)
        viewModel.seasonalOption = .seasonal(perAmount: 300, discount: 40)

        // When: เรียก reset()
        viewModel.reset()

        // Then: ทุกการเลือกถูกเคลียร์ ราคากลับไปเท่า subtotal
        XCTAssertTrue(viewModel.selectedCampaigns.isEmpty)
        XCTAssertTrue(viewModel.result.steps.isEmpty)
        XCTAssertEqual(viewModel.result.finalPrice, viewModel.result.subtotal)
    }

    func testLiveRecalculationReflectsSelectionChanges() {
        // Given: ViewModel ใหม่จาก mock cart (subtotal = 700+999+250+1299 = 3248)
        let viewModel = CartViewModel()
        assertDecimalEqual(viewModel.result.subtotal, 3248)

        // When: เลือกคูปองลดคงที่ 250
        viewModel.couponOption = .fixedAmount(250)

        // Then: คำนวณใหม่ทันที เหลือ 3248 − 250 = 2998
        assertDecimalEqual(viewModel.result.finalPrice, 3248 - 250)

        // When: เพิ่ม seasonal ทุก 300 ลด 40
        viewModel.seasonalOption = .seasonal(perAmount: 300, discount: 40)

        // Then: คำนวณใหม่อีกครั้ง: floor(2998/300) = 9 ก้อน → −360 → 2638
        XCTAssertEqual(viewModel.result.steps.map(\.campaign.category), [.coupon, .seasonal])
        XCTAssertEqual(viewModel.result.steps[1].discountApplied, 360)
        XCTAssertEqual(viewModel.result.finalPrice, 2638)
    }
}
