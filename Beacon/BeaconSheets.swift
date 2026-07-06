import SwiftUI

/// One unified sheet enum per screen — stacking multiple `.sheet(item:)` or
/// `.alert(...)` modifiers on the same view is a known SwiftUI bug (only the
/// last-declared one reliably fires). Route every sheet through this enum.
enum ItemSheetMode: Identifiable {
    case add
    case edit(TrackedItem)
    case paywall

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let item): return item.id.uuidString
        case .paywall: return "paywall"
        }
    }
}

struct ItemEditSheet: View {
    let mode: ItemSheetMode
    let onSave: (String, ItemCategory, String, Date, Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var category: ItemCategory
    @State private var detail: String
    @State private var installDate: Date
    @State private var expectedLifeDays: Int

    init(mode: ItemSheetMode, onSave: @escaping (String, ItemCategory, String, Date, Int) -> Void) {
        self.mode = mode
        self.onSave = onSave
        switch mode {
        case .edit(let item):
            _name = State(initialValue: item.name)
            _category = State(initialValue: item.category)
            _detail = State(initialValue: item.detail)
            _installDate = State(initialValue: item.installDate)
            _expectedLifeDays = State(initialValue: item.expectedLifeDays)
        default:
            _name = State(initialValue: "")
            _category = State(initialValue: .bulb)
            _detail = State(initialValue: "")
            _installDate = State(initialValue: Date())
            _expectedLifeDays = State(initialValue: ItemCategory.bulb.defaultLifespanDays)
        }
    }

    private var title: String {
        if case .edit = mode { return "Edit Item" }
        return "New Item"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name (e.g. Kitchen Bulb)", text: $name)
                        .accessibilityIdentifier("itemNameField")

                    Picker("Category", selection: $category) {
                        ForEach(ItemCategory.allCases) { cat in
                            Text(cat.rawValue).tag(cat)
                        }
                    }
                    .accessibilityIdentifier("itemCategoryPicker")
                    .onChange(of: category) { _, newValue in
                        if case .add = mode {
                            expectedLifeDays = newValue.defaultLifespanDays
                        }
                    }

                    TextField("Detail (room, size, brand)", text: $detail)
                        .accessibilityIdentifier("itemDetailField")
                }
                Section("Lifespan") {
                    DatePicker("Installed", selection: $installDate, displayedComponents: .date)
                        .accessibilityIdentifier("itemInstallDatePicker")

                    Stepper("Lasts about \(expectedLifeDays) days", value: $expectedLifeDays, in: 1...1500, step: 5)
                        .accessibilityIdentifier("itemLifeStepper")
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, category, detail, installDate, expectedLifeDays)
                        dismiss()
                    }
                    .accessibilityIdentifier("itemSaveButton")
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .dismissKeyboardOnTap()
    }
}
