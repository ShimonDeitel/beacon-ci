import Foundation

enum ItemCategory: String, Codable, CaseIterable, Identifiable {
    case bulb = "Light Bulb"
    case airFilter = "Air Filter"
    case waterFilter = "Water Filter"
    case custom = "Custom"

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .bulb: return "lightbulb.fill"
        case .airFilter: return "wind"
        case .waterFilter: return "drop.fill"
        case .custom: return "shippingbox.fill"
        }
    }

    /// Sensible default lifespan in days for a freshly created item of this category.
    var defaultLifespanDays: Int {
        switch self {
        case .bulb: return 365 * 2       // ~2 years typical LED bulb
        case .airFilter: return 90       // ~3 months HVAC filter
        case .waterFilter: return 180    // ~6 months fridge/under-sink filter
        case .custom: return 90
        }
    }
}

struct TrackedItem: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var category: ItemCategory
    /// Free-form detail: room/fixture for bulbs, HVAC size for filters, brand for water filters.
    var detail: String
    var installDate: Date
    /// Expected lifespan of the item, in days.
    var expectedLifeDays: Int
    var createdDate: Date

    init(
        id: UUID = UUID(),
        name: String,
        category: ItemCategory,
        detail: String = "",
        installDate: Date = Date(),
        expectedLifeDays: Int = 90,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.detail = detail
        self.installDate = installDate
        self.expectedLifeDays = expectedLifeDays
        self.createdDate = createdDate
    }

    var daysSinceInstalled: Double {
        Date().timeIntervalSince(installDate) / 86400.0
    }

    /// 0 = brand new, 1 = fully past expected life.
    var percentUsed: Double {
        guard expectedLifeDays > 0 else { return 1 }
        return min(1, max(0, daysSinceInstalled / Double(expectedLifeDays)))
    }

    var percentRemaining: Double {
        1 - percentUsed
    }

    var daysRemaining: Int {
        expectedLifeDays - Int(daysSinceInstalled)
    }

    var isNearingEnd: Bool {
        percentUsed >= 0.7 && percentUsed < 1.0
    }

    var isExpired: Bool {
        percentUsed >= 1.0
    }

    mutating func replace(now: Date = Date()) {
        installDate = now
    }
}
