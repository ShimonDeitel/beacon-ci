import Foundation
import UserNotifications

@MainActor
final class BeaconStore: ObservableObject {
    @Published private(set) var items: [TrackedItem] = []

    static let freeItemLimit = 3

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("beacon_items.json")
        if ProcessInfo.processInfo.arguments.contains("-uiTestReset") {
            try? FileManager.default.removeItem(at: fileURL)
        }
        load()
        if items.isEmpty {
            seedDefaults()
        }
    }

    private func seedDefaults() {
        items = [
            TrackedItem(name: "Kitchen Bulb", category: .bulb, detail: "Ceiling fixture",
                        installDate: Calendar.current.date(byAdding: .day, value: -400, to: Date())!,
                        expectedLifeDays: ItemCategory.bulb.defaultLifespanDays),
            TrackedItem(name: "HVAC Filter", category: .airFilter, detail: "16x25x1",
                        installDate: Calendar.current.date(byAdding: .day, value: -60, to: Date())!,
                        expectedLifeDays: ItemCategory.airFilter.defaultLifespanDays)
        ]
        save()
    }

    func canAddItem(isPro: Bool) -> Bool {
        isPro || items.count < Self.freeItemLimit
    }

    @discardableResult
    func addItem(name: String, category: ItemCategory, detail: String, installDate: Date, expectedLifeDays: Int, isPro: Bool) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canAddItem(isPro: isPro) else { return false }
        let item = TrackedItem(name: trimmed, category: category, detail: detail, installDate: installDate, expectedLifeDays: max(1, expectedLifeDays))
        items.append(item)
        save()
        return true
    }

    func updateItem(_ id: UUID, name: String, category: ItemCategory, detail: String, installDate: Date, expectedLifeDays: Int) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].name = trimmed
        items[idx].category = category
        items[idx].detail = detail
        items[idx].installDate = installDate
        items[idx].expectedLifeDays = max(1, expectedLifeDays)
        save()
    }

    func replaceItem(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].replace()
        save()
    }

    func deleteItem(_ id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func moveItems(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
        save()
    }

    func deleteAllData() {
        items = []
        seedDefaults()
    }

    // MARK: - Persistence

    private struct Snapshot: Codable {
        var items: [TrackedItem]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode(Snapshot.self, from: data) {
            items = decoded.items
        }
    }

    private func save() {
        let snapshot = Snapshot(items: items)
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    // MARK: - Notification scheduling (Pro bonus feature)

    /// Reschedules local notifications for every item, firing `leadDays` days
    /// before each item's expected end-of-life. Pro-only lead time is
    /// configurable via Settings; free users get a fixed 3-day lead time
    /// when notifications are enabled at all.
    func rescheduleNotifications(enabled: Bool, leadDays: Int) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard enabled else { return }

        for item in items {
            guard !item.isExpired else { continue }
            let fireDate = Calendar.current.date(
                byAdding: .day,
                value: item.expectedLifeDays - max(0, leadDays),
                to: item.installDate
            )
            guard let fireDate, fireDate > Date() else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Beacon reminder"
            content.body = "\(item.name) will need replacing soon."
            content.sound = .default

            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)
            center.add(request)
        }
    }

    func requestNotificationAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
