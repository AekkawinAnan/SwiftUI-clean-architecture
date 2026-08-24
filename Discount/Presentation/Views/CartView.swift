//
//  CartView.swift
//  Discount
//

import SwiftUI

/// หน้าจอหลัก: สินค้าในตะกร้า การเลือกแคมเปญ (หมวดหมู่ละ 1)
/// และสรุปราคาแบบทีละขั้นแบบเรียลไทม์.
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

    // MARK: ส่วนต่าง ๆ ของหน้าจอ

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
        // สั่งคำนวณใหม่เพื่อเคลียร์ error ที่เก็บไว้ โดยไม่เปลี่ยนการเลือกแคมเปญ.
        viewModel.reset()
    }
}

#Preview {
    CartView()
}
