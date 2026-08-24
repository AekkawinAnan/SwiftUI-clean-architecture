//
//  DiscountCalculatorTestCase.swift
//  DiscountTests
//
//  Shared fixture & assertion helpers for all discount engine tests.
//

import XCTest
@testable import Discount

/// Base class for the discount engine test suites.
class DiscountCalculatorTestCase: XCTestCase {

    var sut: DiscountCalculator!

    /// Fixture: 500×2 (Clothing) + 200×1 (Accessories) + 150×1 (Electronics) = 1,350 THB
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

    // MARK: Helpers

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

/// Exact equality for `Decimal` money values.
func assertDecimalEqual(
    _ lhs: Decimal,
    _ rhs: Decimal,
    _ message: String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    XCTAssertTrue(lhs == rhs, "\(message) (expected \(rhs), got \(lhs))", file: file, line: line)
}
