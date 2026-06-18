# Threadline

A wardrobe tracking app for iOS that helps you make smarter clothing decisions. Log outfits daily, track cost-per-wear, spot neglected items, and evaluate purchases before you make them.

## The Problem

People budget their money but wing their clothing decisions. Most wardrobe apps stop at cataloging - they show you a number on a dashboard but don't change your behavior. Threadline puts wardrobe data in context: before you buy something new, when you're getting dressed, and when items are collecting dust.

## Features

### Today Tab
- **Quick outfit logging** - tap items you wore today from a visual grid, done in under 5 seconds
- **Streak tracking** - consecutive days of logging with a flame counter
- **Daily insights** - shows your most-worn and least-worn items with thumbnails
- **Stats at a glance** - item count, total wardrobe value, total wears
- **Neglected items** - surfaces items not worn in 30+ days so you can shop your own closet

### Closet Tab
- **Visual wardrobe grid** - 2-column photo grid of all active items
- **Category filtering** - horizontal chip bar to filter by tops, bottoms, outerwear, shoes, accessories, dresses
- **7 sort options** - name, price (high/low), most/least worn, recently added, color
- **Search** - find items by name
- **Multi-select** - bulk archive or delete items
- **Item detail** - photo, cost-per-wear, total wears, last worn date, full wear history, purchase info
- **Archive system** - archive, mark for resale, or donate items with confirmation dialogs; restore from archived view
- **Add items** - name, category (with icons), color (23 options with swatches), price, date, photo from library or camera

### Insights Tab
- **Wardrobe Health Score** - composite metric (0-100) combining utilization (40%), cost-per-wear (35%), and category balance (25%), displayed as an animated ring
- **Utilization tracker** - progress bar showing how many items you've actually worn in the last 30 days
- **Spending analysis** - average cost-per-wear with qualitative verdict, monthly spend total
- **Category balance** - bar chart (Swift Charts) showing distribution across categories
- **Top performers** - 3 lowest cost-per-wear items ranked with thumbnails
- **Underperformers** - items not worn in 30+ days with thumbnails and days-since-worn count
- **Gating** - requires 5+ items before unlocking full analytics

### Should I Buy This?
- **Category-first comparison** - select what type of item you're considering from a visual grid showing how many you already own
- **Price input** - enter the price for cost-per-wear projections
- **Tiered verdicts** - color-coded recommendations based on how many similar items you own (0 = go for it, 1-2 = could be good, 3-4 = think twice, 5+ = probably don't need)
- **CPW projection** - shows projected cost-per-wear at 10 and 30 wears vs your category average
- **Visual inventory** - thumbnail grid of items you already own in that category
- **Optional photo** - snap a photo of the item you're considering via camera or photo library

### Profile Tab
- **Customizable goals** - monthly spend target and utilization target with stepper controls
- **Data export** - CSV export via iOS share sheet
- **App version info**

## Tech Stack

- **SwiftUI** - declarative UI with iOS 17+ APIs
- **SwiftData** - on-device persistence with `@Model` classes and `@Query` property wrapper
- **Swift Charts** - native charting for category distribution
- **PhotosUI** - `PhotosPicker` for photo library access
- **UIKit bridge** - `UIImagePickerController` via `UIViewControllerRepresentable` for camera capture
- **No backend** - all data stays on device

## Architecture

```
Threadline/
├── ThreadlineApp.swift          App entry point, SwiftData container
├── ContentView.swift            TabView (4 tabs) + ProfileView
├── Models/
│   ├── ClothingItem.swift       @Model: item data, category/status/season/color enums, computed CPW
│   ├── WearLog.swift            @Model: date + item relationship
│   └── HealthScore.swift        Composite score calculation (utilization × CPW × category balance)
├── Views/
│   ├── Today/
│   │   ├── TodayView.swift      Daily hub: log button, streak, stats, insights, neglected items
│   │   └── QuickLogView.swift   Multi-select outfit logging grid
│   ├── Closet/
│   │   ├── ClosetGridView.swift Filterable/sortable item grid + ArchivedItemsView
│   │   ├── ItemDetailView.swift Single item: photo, stats, wear history, archive/delete
│   │   └── AddItemView.swift    Form: photo, details, purchase info + CameraPickerView
│   ├── Insights/
│   │   └── InsightsDashboardView.swift  Health score ring, utilization bar, spending, charts, rankings
│   ├── Purchase/
│   │   └── PurchaseCheckView.swift      Pre-purchase category comparison with verdict system
│   └── Shared/
│       ├── EmptyStateView.swift         Reusable empty state with icon, text, CTA
│       └── ItemCardView.swift           Grid card: photo, name, CPW, wear count, warning badge
├── Components/
│   └── HealthScoreRing.swift    Animated circular progress indicator
├── Services/
│   ├── WardrobeAnalytics.swift  Computed properties: utilization, CPW, underperformers, category breakdown
│   └── MockDataService.swift    Seeds 10 realistic items with wear history on first launch
└── Utilities/
    ├── ColorTokens.swift        Semantic colors: brand, background, text, status
    └── Spacing.swift            8pt spacing scale (xxs through xxxxl)
```

## Data Model

**ClothingItem** - name, category, purchase price, purchase date, photo (as Data), color, seasons, status (active/stored/archived/donated/for sale), wear logs relationship

**WearLog** - date, occasion, back-reference to ClothingItem

Persistence via `@AppStorage` for user goals (monthly spend target, utilization target).

## Running It

1. Clone this repo
2. Open `Threadline.xcodeproj` in Xcode 15+
3. Build and run on an iPhone simulator or device (iOS 17+)

The app seeds 10 realistic items with plausible wear patterns on first launch so you can explore every feature immediately.

## Design Decisions

**Category-based purchase check** - Without ML/AI, matching by item name is unreliable. The purchase check uses category as the comparison axis, which is the dimension that actually matters when evaluating wardrobe gaps vs redundancy.

**Financial framing** - "Smart spending" and portfolio language (ROI, utilization, underperformers) drives behavior change more effectively than sustainability messaging. The app treats your wardrobe like an investment portfolio.

**Progressive disclosure** - The purchase check reveals each step (category → price → verdict) sequentially with spring animations, keeping the interface focused instead of overwhelming.

**Alert over overlay** - Success feedback after logging an outfit uses a native `.alert()` instead of a full-screen overlay, keeping the interaction lightweight and letting the user immediately continue.

**Mock data on first launch** - The #1 reason users abandon wardrobe apps is the setup wall. Threadline ships with 10 curated items so users see value before investing effort.
