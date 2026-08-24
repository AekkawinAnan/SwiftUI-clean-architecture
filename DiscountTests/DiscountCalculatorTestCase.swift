//
//  DiscountCalculatorTestCase.swift
//  DiscountTests
//
//  Fixture และ assertion helpers ที่ใช้ร่วมกันของทุกชุด test เอนจินส่วนลด.
//

import XCTest
@testable import Discount

/// Base class ของชุด test เอนจินส่วนลดทุกชุด.
class DiscountCalculatorTestCase: XCTestCase {

    var sut: DiscountCalculator!

    /// Fixture: 500×2 (เสื้อผ้า) + 200×1 (เครื่องประดับ) + 150×1 (อิเล็กทรอนิกส์) = 1,350 บาท
    let cart = [
        CartItem(name: "Shirt", category: .clothing, price: 500, quantity: 2),
        CartItem(name: "Hat", category: .accessories, price: 200, quantity: 1),
        CartItem(name: "Cable", category: .electronics, price: 150, quantity: 1),
    ]

    override func setUp() {
        super.setUp()
        sut = DiscountCalculator()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: ตัวช่วย

    func calculate(
        _ campaigns: [DiscountCampaign],
        cart overrideCart: [CartItem]? = nil
    ) throws -> DiscountCalculationResult {
        try sut.calculate(cartItems: overrideCart ?? cart, campaigns: campaigns)
    }

    func assertThrows(
        _ expectedError: DiscountError,
        campaigns: [DiscountCampaign],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertThrowsError(try calculate(campaigns), file: file, line: line) { error in
            XCTAssertEqual(error as? DiscountError, expectedError, file: file, line: line)
        }
    }
}

/// เทียบค่าเงิน `Decimal` แบบ exact equality.
func assertDecimalEqual(
    _ lhs: Decimal,
    _ rhs: Decimal,
    _ message: String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertTrue(lhs == rhs, "\(message) (expected \(rhs), got \(lhs))", file: file, line: line)
}
