import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: BeaconStore
    @EnvironmentObject private var purchases: PurchaseManager
    @AppStorage("beacon_haptics_enabled") private var hapticsEnabled: Bool = true
    @AppStorage("beacon_notify_enabled") private var notifyEnabled: Bool = false
    /// Pro bonus feature: configurable per-item reminder lead-time in days,
    /// feeding directly into the local notification schedule. Free users get
    /// a fixed 3-day lead time whenever notifications are on.
    @AppStorage("beacon_notify_lead_days") private var notifyLeadDays: Int = 3

    @State private var showingDeleteConfirm = false
    @State private var sheetMode: ItemSheetMode?

    var body: some View {
        NavigationStack {
            ZStack {
                BNTheme.backdrop.ignoresSafeArea()

                Form {
                    Section {
                        if purchases.isPro {
                            HStack {
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(BNTheme.freshGlow)
                                Text("Beacon Pro unlocked")
                                    .foregroundStyle(BNTheme.ink)
                            }
                        } else {
                            Button {
                                sheetMode = .paywall
                            } label: {
                                HStack {
                                    Image(systemName: "star.fill").foregroundStyle(BNTheme.freshGlow)
                                    Text("Unlock Beacon Pro")
                                        .foregroundStyle(BNTheme.ink)
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundStyle(BNTheme.inkFaded)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listRowBackground(BNTheme.surface)

                    Section("Items") {
                        ForEach(store.items) { item in
                            HStack {
                                Text(item.name).foregroundStyle(BNTheme.ink)
                                Spacer()
                                Text(item.category.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(BNTheme.inkFaded)
                                Button {
                                    sheetMode = .edit(item)
                                } label: {
                                    Image(systemName: "pencil.circle").foregroundStyle(BNTheme.inkFaded)
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("editItem_\(item.name)")
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    store.deleteItem(item.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .accessibilityIdentifier("deleteItemSwipe_\(item.name)")
                            }
                        }
                        .onMove { source, destination in
                            store.moveItems(from: source, to: destination)
                        }

                        Button {
                            if store.canAddItem(isPro: purchases.isPro) {
                                sheetMode = .add
                            } else {
                                sheetMode = .paywall
                            }
                        } label: {
                            Label("Add Item", systemImage: "plus.circle")
                                .foregroundStyle(BNTheme.freshGlow)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("settingsAddItemButton")

                        if !purchases.isPro {
                            Text("\(store.items.count)/\(BeaconStore.freeItemLimit) free items used")
                                .font(.caption)
                                .foregroundStyle(BNTheme.inkFaded)
                        }
                    }
                    .listRowBackground(BNTheme.surface)

                    Section("Reminders") {
                        Toggle(isOn: $notifyEnabled) {
                            Label("Notify before items expire", systemImage: "bell.badge.fill")
                                .foregroundStyle(BNTheme.ink)
                        }
                        .tint(BNTheme.freshGlow)
                        .accessibilityIdentifier("notifyToggle")
                        .onChange(of: notifyEnabled) { _, newValue in
                            if newValue {
                                store.requestNotificationAuthorization()
                            }
                            store.rescheduleNotifications(enabled: newValue, leadDays: purchases.isPro ? notifyLeadDays : 3)
                        }

                        if purchases.isPro {
                            Stepper("Remind \(notifyLeadDays) days before", value: $notifyLeadDays, in: 1...30)
                                .foregroundStyle(BNTheme.ink)
                                .accessibilityIdentifier("notifyLeadStepper")
                                .disabled(!notifyEnabled)
                                .onChange(of: notifyLeadDays) { _, newValue in
                                    store.rescheduleNotifications(enabled: notifyEnabled, leadDays: newValue)
                                }
                        } else {
                            Text("Pro unlocks a custom reminder lead-time. Free plan reminds 3 days ahead.")
                                .font(.caption)
                                .foregroundStyle(BNTheme.inkFaded)
                        }
                    }
                    .listRowBackground(BNTheme.surface)

                    Section("Preferences") {
                        Toggle(isOn: $hapticsEnabled) {
                            Label("Haptics", systemImage: "hand.tap.fill")
                                .foregroundStyle(BNTheme.ink)
                        }
                        .tint(BNTheme.freshGlow)
                        .onChange(of: hapticsEnabled) { _, newValue in
                            Haptics.enabled = newValue
                        }

                        Button {
                            Task { await purchases.restore() }
                        } label: {
                            Label("Restore Purchases", systemImage: "arrow.clockwise")
                                .foregroundStyle(BNTheme.ink)
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(BNTheme.surface)

                    Section("About") {
                        Link(destination: URL(string: "https://shimondeitel.github.io/cool-apps-legal/beacon/privacy.html")!) {
                            Label("Privacy Policy", systemImage: "hand.raised.fill")
                                .foregroundStyle(BNTheme.ink)
                        }
                        Link(destination: URL(string: "https://shimondeitel.github.io/cool-apps-legal/beacon/support.html")!) {
                            Label("Support", systemImage: "questionmark.circle")
                                .foregroundStyle(BNTheme.ink)
                        }
                        Link(destination: URL(string: "mailto:s0533495227@gmail.com")!) {
                            Label("Contact Support", systemImage: "envelope.fill")
                                .foregroundStyle(BNTheme.ink)
                        }
                        HStack {
                            Text("Version").foregroundStyle(BNTheme.ink)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundStyle(BNTheme.inkFaded)
                        }
                    }
                    .listRowBackground(BNTheme.surface)

                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirm = true
                        } label: {
                            Label("Delete All Data", systemImage: "trash.fill")
                        }
                        .buttonStyle(.plain)
                    }
                    .listRowBackground(BNTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .toolbarBackground(BNTheme.backdrop, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar { EditButton() }
            .sheet(item: $sheetMode) { mode in
                switch mode {
                case .paywall:
                    PaywallView().environmentObject(purchases)
                case .add, .edit:
                    ItemEditSheet(mode: mode) { name, category, detail, installDate, life in
                        switch mode {
                        case .add:
                            store.addItem(name: name, category: category, detail: detail, installDate: installDate, expectedLifeDays: life, isPro: purchases.isPro)
                        case .edit(let item):
                            store.updateItem(item.id, name: name, category: category, detail: detail, installDate: installDate, expectedLifeDays: life)
                        case .paywall:
                            break
                        }
                    }
                }
            }
            .alert("Delete All Data?", isPresented: $showingDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    store.deleteAllData()
                }
            } message: {
                Text("This permanently removes every tracked item. This cannot be undone.")
            }
        }
        .dismissKeyboardOnTap()
    }
}

#Preview {
    SettingsView()
        .environmentObject(BeaconStore())
        .environmentObject(PurchaseManager())
}
