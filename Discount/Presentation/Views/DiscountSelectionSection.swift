//
//  DiscountSelectionSection.swift
//  Discount
//

import SwiftUI

/// One `Picker` per discount category (Rule 1: max one selection each),
/// plus conditional sub-controls for parameterized on-top campaigns.
struct DiscountSelectionSection: View {
    @Bindable var viewModel: CartViewModel

    var body: some View {
        Group {
            couponPicker
            onTopPicker
            if showsCategoryControls {
                categoryPicker
            }
            if viewModel.onTopOption == .points {
                pointsInput
            }
            seasonalPicker
        }
    }

    // MARK: Coupon

    private var couponPicker: some View {
        Picker("Coupon", selection: $viewModel.couponOption) {
            ForEach(CouponOption.options) { option in
                Text(option.label).tag(option)
            }
        }
    }

    // MARK: On Top

    private var onTopPicker: some View {
        Picker("On Top", selection: $viewModel.onTopOption) {
            ForEach(OnTopOption.options) { option in
                Text(option.label).tag(option)
            }
        }
    }

    private var showsCategoryControls: Bool {
        if case .categoryPercentage = viewModel.onTopOption {
            return true
        }
        return false
    }

    private var categoryPicker: some View {
        Picker("Category", selection: $viewModel.onTopCategory) {
            ForEach(ItemCategory.allCases, id: \.self) { category in
                Text(category.displayName).tag(category)
            }
        }
    }

    private var pointsInput: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Points")
                Spacer()
                TextField("e.g. 200", text: $viewModel.pointsText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 140)
            }

            if let error = viewModel.pointsInputError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if let points = OnTopOption.parsedPoints(from: viewModel.pointsText), points > 0 {
                // Build as plain String: Decimal must not be interpolated directly
                // into `Text` (localized-interpolation deprecation).
                let summary = "\(points) pt = \(points.thb) (max 20% of current total)"
                Text(summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Seasonal

    private var seasonalPicker: some View {
        Picker("Seasonal", selection: $viewModel.seasonalOption) {
            ForEach(SeasonalOption.options) { option in
                Text(option.label).tag(option)
            }
        }
    }
}

#Preview {
    List {
        Section("Discount Campaigns") {
            DiscountSelectionSection(viewModel: CartViewModel())
        }
    }
}
