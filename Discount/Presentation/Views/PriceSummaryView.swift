//
//  PriceSummaryView.swift
//  Discount
//

import SwiftUI

/// Subtotal → breakdown ส่วนลดแบบทีละขั้น (พร้อมคำอธิบาย) → ราคาสุดท้าย.
struct PriceSummaryView: View {
    let result: DiscountCalculationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LabeledContent("Subtotal") {
                Text(result.subtotal.thb)
                    .monospacedDigit()
            }

            if result.hasAnyDiscount {
                ForEach(result.steps) { step in
                    stepRow(step)
                }

                Divider()

                LabeledContent("Total Discount") {
                    Text("−\(result.totalDiscount.thb)")
                        .foregroundStyle(.red)
                        .monospacedDigit()
                        .fontWeight(.semibold)
                }
            } else {
                Text("No discount campaign selected.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            LabeledContent("Final Price") {
                Text(result.finalPrice.thb)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.green)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: แถวแสดงผลแต่ละขั้น

    private func stepRow(_ step: DiscountStep) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            LabeledContent {
                Text("−\(step.discountApplied.thb)")
                    .foregroundStyle(.red)
                    .monospacedDigit()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(step.campaign.displayName)
                            .font(.subheadline.weight(.medium))
                        Text("\(step.amountBefore.thb) → \(step.amountAfter.thb)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }

            if let note = step.note {
                Text(note)
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
    }
}

#Preview {
    List {
        Section("Summary") {
            PriceSummaryView(
                result: DiscountCalculationResult(
                    subtotal: 1350,
                    steps: [
                        DiscountStep(
                            campaign: .percentage(percent: 10),
                            amountBefore: 1350,
                            discountApplied: 135,
                            amountAfter: 1215
                        ),
                        DiscountStep(
                            campaign: .points(count: 300),
                            amountBefore: 1215,
                            discountApplied: 243,
                            amountAfter: 972,
                            note: "Capped at 20% of current total"
                        ),
                    ],
                    finalPrice: 852
                )
            )
        }
    }
}
