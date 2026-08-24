//
//  CartView.swift
//  Discount
//

import SwiftUI

/// Main screen: cart items, campaign selection (max 1 per category) and the
/// live step-by-step price summary.
struct CartView: View {
    @State private var viewModel = CartViewModel()

    var body: some View {
        NavigationStack {
            List {
                cartSection
                discountSection
                summarySection
            }
            .listStyle(.insetGrouped)
            .navigationTitle("My Cart")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Reset") {
                        viewModel.reset()
                    }
                }
            }
            .alert(
                "Invalid Discount",
                isPresented: .init(
                    get: { viewModel.lastError != nil },
                    set: { if !$0 { dismissError() } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.lastError?.errorDescription ?? "Unknown error")
            }
        }
    }

    // MARK: Sections

    private var cartSection: some View {
        Section("Cart Items") {
            ForEach(viewModel.cartItems) { item in
                CartItemRowView(item: item)
            }
        }
    }

    private var discountSection: some View {
        Section("Discount Campaigns") {
            DiscountSelectionSection(viewModel: viewModel)
        }
    }

    private var summarySection: some View {
        Section("Summary") {
            PriceSummaryView(result: viewModel.result)
        }
    }

    private func dismissError() {
        // Re-triggering recalculation clears the stored error without changing selections.
        viewModel.reset()
    }
}

#Preview {
    CartView()
}
