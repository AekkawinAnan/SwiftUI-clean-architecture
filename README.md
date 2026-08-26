# 🛒 Discount Calculation Module

โมดูลคำนวณราคาสุดท้ายของออเดอร์ โดยการนำแคมเปญส่วนลดหลายตัวมา apply กับตะกร้าสินค้า
พัฒนาบน **SwiftUI + Clean Architecture + MVVM** (Swift 6.2 / Xcode 26)

---

## 📋 Business Rules (หัวใจของโจทย์)

### กติกาข้อ 1 — หนึ่งหมวดหมู่ เลือกได้หนึ่งแคมเปญ
ผู้ใช้เลือกแคมเปญได้หลายตัว แต่**แต่ละหมวดหมู่เลือกได้สูงสุด 1 แคมเปญ**
(สูงสุด = 1 Coupon + 1 On Top + 1 Seasonal)

### กติกาข้อ 2 — ลำดับการ apply เป็น Coupon → On Top → Seasonal เท่านั้น
**output ของขั้นก่อน = input ของขั้นถัดไป**

### กติกาข้อ 3 — Cap ของคะแนนสะสม
1 คะแนน = 1 บาท แต่ลดได้ไม่เกิน **20% ของยอดรวม "ปัจจุบัน" (หลังหักคูปองแล้ว)** —
⚠️ จุดที่พลาดกันบ่อยคือคิด cap จาก subtotal ซึ่งผิด spec

### แคมเปญทั้ง 5

| หมวดหมู่ | แคมเปญ | สูตร |
|---|---|---|
| Coupon | Fixed Amount | ลด = `amount` → **หักจากยอดปัจจุบัน** (clamp ไม่ให้ต่ำกว่า 0) |
| Coupon | Percentage | ลด = `total × percent / 100` → **หักจากยอดปัจจุบัน** |
| On Top | % by Item Category | ลด = `(subtotal เฉพาะหมวด) × percent / 100` → **หักจากยอดปัจจุบัน** (ฐานคือยอดเฉพาะหมวด ไม่ใช่ยอดรวม) |
| On Top | Points | ลด = `min(คะแนน, 20% × ยอดปัจจุบัน)` → **หักจากยอดปัจจุบัน** |
| Seasonal | Every X get Y | ลด = `floor(ยอดปัจจุบัน / X) × Y` (เศษไม่นับ) → **หักจากยอดปัจจุบัน** |

> 📌 ทุกแคมเปญคำนวณ "ยอดส่วนลด" จากสูตรข้างบน แล้ว**หักออกจากยอดรวมปัจจุบัน**เสมอ
> (ยอดปัจจุบัน = ผลลัพธ์ของ step ก่อนหน้า — ตามกติกาข้อ 2)

---

## 🏗 Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│                                                          │
│   SwiftUI Views ──────▶ CartViewModel (@Observable)      │
│   (CartView, PriceSummaryView,      │  inject             │
│    DiscountSelectionSection)        ▼                     │
├─────────────────────────────────────────────────────────┤
│                  Domain Layer (pure Swift)               │
│                                                          │
│   ┌──────────────────┐   implements   ┌───────────────┐ │
│   │ DiscountCalculator│◀──────────────│DiscountCalculating│ │
│   └──────────────────┘                │   (protocol)   │ │
│                                       └───────────────┘ │
│   Models: CartItem · DiscountCampaign · DiscountResult   │
│   Utilities: DecimalExtensions                           │
└─────────────────────────────────────────────────────────┘
```

**หลักการสำคัญ:** Dependency ไหลทางเดียว — View → ViewModel → Protocol ← Engine
ViewModel ไม่รู้จัก concrete type (`DiscountCalculator`) รู้จักแค่ abstraction
(`DiscountCalculating`) ตามหลัก **Dependency Inversion Principle**

## 📁 Project Structure

```
Discount/
├── Domain/                          # Pure Swift — ไม่ import UIKit/SwiftUI
│   ├── Models/
│   │   ├── ItemCategory.swift       # หมวดหมู่สินค้า (clothing/accessories/electronics)
│   │   ├── CartItem.swift           # รายการสินค้า + mock data
│   │   ├── DiscountCampaign.swift   # enum + associated values + DiscountCategory
│   │   └── DiscountResult.swift     # DiscountStep, Result, DiscountError
│   ├── Utilities/
│   │   └── DecimalExtensions.swift  # ปัดเศษเงิน / floor / format THB
│   └── UseCases/
│       └── DiscountCalculator.swift # เอนจินคำนวณ + protocol
├── Presentation/
│   ├── ViewModels/
│   │   ├── CartViewModel.swift      # @Observable state holder
│   │   └── CampaignOptions.swift    # options สำหรับ Picker
│   └── Views/
│       ├── CartView.swift           # หน้าหลัก
│       ├── CartItemRowView.swift
│       ├── DiscountSelectionSection.swift
│       └── PriceSummaryView.swift   # Subtotal → steps → Final Price
└── DiscountTests/                   # XCTest 37 cases (Given–When–Then)
```

## 🔀 Data Flow (ตัวอย่างการทำงานจริง)

**Input:** ตะกร้า = เสื้อยืด 350×2 + แจ็กเก็ตยีนส์ 999 + เข็มขัด 250 + หูฟัง 1,299
**เลือก:** คูปองลด 10% · ใช้คะแนน 300 · Seasonal ทุก 300 ลด 40

```
Subtotal = 700 + 999 + 250 + 1299 = 3,248 บาท

┌─ Step 1: Coupon (10%) ─────────────────────────────┐
│ 3,248 × 10% = −324.80                              │
│ 3,248 ───────────────────────────▶ 2,923.20        │
└────────────────────────────────────────────────────┘
                        │ output → input
                        ▼
┌─ Step 2: On Top — Points ──────────────────────────┐
│ cap = 20% × 2,923.20 = 584.64                      │
│ min(300, 584.64) = −300   ← ไม่โดน cap             │
│ 2,923.20 ────────────────────────▶ 2,623.20        │
└────────────────────────────────────────────────────┘
                        │ output → input
                        ▼
┌─ Step 3: Seasonal (ทุก 300 ลด 40) ─────────────────┐
│ floor(2623.20 / 300) = 8 ก้อน → 8 × 40 = −320      │
│ 2,623.20 ────────────────────────▶ 2,303.20        │
└────────────────────────────────────────────────────┘

💰 Final Price: ฿2,303.20  (ส่วนลดรวม ฿944.80)
```

ทุก step ถูกเก็บเป็น `DiscountStep` (amountBefore → discountApplied → amountAfter)
ทำให้ UI แสดง **breakdown แบบทีละขั้น** พร้อม note อธิบายได้ทันที

## 🧩 Key Design Decisions

### 1️⃣ `enum` with Associated Values สำหรับแคมเปญ

```swift
enum DiscountCampaign: Hashable, Codable {
    case fixedAmount(amount: Decimal)
    case percentage(percent: Decimal)
    case percentageByCategory(percent: Decimal, category: ItemCategory)
    case points(count: Decimal)
    case seasonal(perAmount: Decimal, discount: Decimal)
}
```

- **Type safety:** สร้างแคมเปญ config ไม่ครบไม่ได้ตั้งแต่ compile time
- **Exhaustiveness:** เพิ่ม case ใหม่ → compiler force ให้ handle ครบทุก switch
- **Hashable/Codable ฟรี** จาก synthesis

### 2️⃣ `Decimal` ทุกที่ ห้าม `Double`

`Double` เกิด binary rounding error (`0.1 + 0.2 ≠ 0.3`) — พบจริงตอนเขียน test:
literal `120.01` กลายเป็น `120.01000000000002…` จึงกำหนดให้ fixture ค่าเงิน
สร้างจาก `Decimal(string:)` เสมอ

### 3️⃣ Rounding Strategy ชัดเจนสองแบบ

| Function | โหมด | ใช้เมื่อไร |
|---|---|---|
| `roundedMoney()` | `.plain` (half-away-from-zero, scale 2) | ปัดผลคำนวณส่วนลดทุก step — วิธีเดียวกับ POS/ใบเสร็จ |
| `floored()` | `.down` (scale 0) | นับก้อน "ทุก X บาท" — เศษไม่นับ |

### 4️⃣ Defense in Depth — กติกาถูกบังคับสองชั้น

- **ชั้น UI:** ViewModel มี selection slot เดียวต่อหมวด → เลือกซ้ำไม่ได้ตาม design
- **ชั้น Engine:** `pipeline(from:)` sort ตาม `applicationOrder` + dedupe ด้วย `Set`
  → แม้ feed `[seasonal, onTop, coupon]` หรือ duplicate ผลลัพธ์ก็ spec-compliant เสมอ

### 5️⃣ Error Philosophy — "config ผิด throw / ลดเกิน clamp"

| สถานการณ์ | พฤติกรรม | เหตุผล |
|---|---|---|
| amount ติดลบ, % > 100, X = 0 | `throw DiscountError` | programmer error ต้อง expose |
| ส่วนลด > ยอดรวม, คะแนน > cap | **clamp** + note อธิบาย | business edge case ต้อง graceful |
| final price < 0 | clamp ที่ 0 | ราคาติดลบไม่มีความหมาย |

## ⚡ Swift Concurrency & `nonisolated`

Xcode 26 template ตั้ง `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — ทุก type ถูก
infer เป็น MainActor โดยอัตโนมัติ ซึ่งไม่เหมาะกับ Domain layer ที่เป็น pure logic

| ส่วน | Isolation | เหตุผล |
|---|---|---|
| Domain (Models, Calculator) | `nonisolated` | pure logic ปลอดภัยต่อเธรด เรียกได้จาก actor ใดก็ได้ |
| `CartViewModel` | `@MainActor @Observable` | state ที่ View ผูกติด ต้องอยู่บน main actor |

ผลลัพธ์: Engine reuse ได้จาก background task / server-side Swift โดยไม่มี
actor hopping overhead — ViewModel (MainActor) เรียก engine แบบ synchronous ได้เลย

## 🧪 Testing Strategy — 37 cases, Given–When–Then

```
DiscountTests/
├── DiscountCalculatorTestCase.swift      # base class: fixture + assert helpers
├── DiscountCalculatorCouponTests         # fixed amount + percentage + rounding
├── DiscountCalculatorOnTopTests          # % by category + points cap
├── DiscountCalculatorSeasonalTests       # bucket math + clamping
├── DiscountCalculatorRulesTests          # Rules 1&2 + full pipeline + empty cart
└── CartViewModelTests                    # selection slots + input validation
```

**หลักการครอบคลุม:**

- ✅ Happy path ของแคมเปญทุกประเภท
- ✅ **Cap จาก current total**: คูปอง 500 → ยอด 850 → cap = 170 (ไม่ใช่ 270 จาก subtotal)
- ✅ **Clamping**: ส่วนลดเกินยอด → ลดได้เท่ายอดรวม ราคาไม่ติดลบ
- ✅ **Rounding**: `13.335 → 13.34` (half-away-from-zero)
- ✅ **Validation errors**: negative amount / %>100 / X=0 → typed error
- ✅ **Order enforcement**: input สลับลำดับ → output เหมือน canonical order
- ✅ **ViewModel**: invalid points text → ไม่สร้างแคมเปญ + error message

```swift
// ตัวอย่างโครงสร้าง Given–When–Then
func testPointsAboveCapAreCappedAt20PercentOfCurrentTotal() throws {
    // Given: ยอดรวม 1,350 บาท (cap = 270) แต่ขอใช้คะแนน 300
    let campaigns: [DiscountCampaign] = [.points(count: 300)]

    // When: คำนวณส่วนลด
    let result = try calculate(campaigns)

    // Then: ลดได้จริงแค่ 270 (cap) พร้อม note อธิบายว่าโดนจำกัด
    assertDecimalEqual(result.steps[0].discountApplied, 270)
    XCTAssertNotNil(result.steps[0].note)
}
```

รัน test: `xcodebuild test -scheme Discount -destination 'platform=iOS Simulator,name=iPhone 17'`

## 🔭 Trade-offs & Future Work

| Trade-off ที่ยอมรับ | Next Step ใน production จริง |
|---|---|
| Campaign options hardcode ฝั่ง UI | ดึง campaign catalog จาก API + remote config |
| Display strings เป็นอังกฤษ | Localization (th/en) ผ่าน String Catalog |
| Mock cart data in-memory | Persistence layer + repository pattern |
| ไม่มี UI tests | Snapshot testing ของ summary view |

## 🚀 Getting Started

1. เปิด `Discount.xcodeproj` ด้วย Xcode 26+
2. Run (`⌘R`) — แอปเปิดหน้า cart พร้อม mock items
3. Test (`⌘U`) — 37 unit tests รันผ่านทั้งหมด


