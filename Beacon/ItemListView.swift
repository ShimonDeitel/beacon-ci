import SwiftUI

struct ItemListView: View {
    @EnvironmentObject private var store: BeaconStore
    @EnvironmentObject private var purchases: PurchaseManager

    @State private var sheetMode: ItemSheetMode?
    @State private var deletingItem: TrackedItem?
    @State private var replacedItemName: String?

    var body: some View {
        NavigationStack {
            ZStack {
                BNTheme.backdrop.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        HStack {
                            Text("Beacon")
                                .font(BNTheme.titleFont)
                                .foregroundStyle(BNTheme.ink)
                            Spacer()
                            Button {
                                if store.canAddItem(isPro: purchases.isPro) {
                                    sheetMode = .add
                                } else {
                                    sheetMode = .paywall
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundStyle(BNTheme.freshGlow)
                            }
                            .accessibilityIdentifier("addItemButton")
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 8)

                        if store.items.isEmpty {
                            emptyState
                        } else {
                            VStack(spacing: 12) {
                                ForEach(store.items) { item in
                                    ItemRow(item: item) {
                                        Haptics.success()
                                        store.replaceItem(item.id)
                                        replacedItemName = item.name
                                        Task {
                                            try? await Task.sleep(nanoseconds: 1_800_000_000)
                                            if replacedItemName == item.name { replacedItemName = nil }
                                        }
                                    } onEdit: {
                                        sheetMode = .edit(item)
                                    } onDelete: {
                                        Haptics.warning()
                                        deletingItem = item
                                    }
                                }
                            }
                            .padding(.horizontal, 18)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: store.items)

                            if !purchases.isPro {
                                Text("Free plan: \(store.items.count)/\(BeaconStore.freeItemLimit) items used")
                                    .font(.caption)
                                    .foregroundStyle(BNTheme.inkFaded)
                                    .padding(.horizontal, 18)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }

                if let name = replacedItemName {
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                            Text("\(name) refreshed!")
                                .font(.subheadline.weight(.semibold))
                        }
                        .foregroundStyle(BNTheme.backdrop)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(BNTheme.freshCore)
                        .clipShape(Capsule())
                        .padding(.bottom, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .allowsHitTesting(false)
                }
            }
            .navigationBarHidden(true)
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
            .confirmationDialog(
                "Remove \(deletingItem?.name ?? "Item")?",
                isPresented: Binding(
                    get: { deletingItem != nil },
                    set: { if !$0 { deletingItem = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Remove", role: .destructive) {
                    if let deletingItem {
                        store.deleteItem(deletingItem.id)
                    }
                    deletingItem = nil
                }
                Button("Cancel", role: .cancel) { deletingItem = nil }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "lightbulb.slash.fill")
                .font(.system(size: 34))
                .foregroundStyle(BNTheme.inkFaded)
            Text("Nothing tracked yet. Tap + to add your first item.")
                .font(.subheadline)
                .foregroundStyle(BNTheme.inkFaded)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

/// The quirky signature visual: a glowing beacon glyph whose glow color
/// interpolates from warm incandescent amber (fresh) to cool dim slate-blue
/// (near end of life), with the glow radius and opacity continuously
/// shrinking as percent-of-life-used rises. Snaps back to a bright wide
/// glow instantly when the item is replaced.
private struct ItemRow: View {
    let item: TrackedItem
    let onReplace: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var statusText: String {
        if item.isExpired {
            return "Replace now"
        }
        let d = item.daysRemaining
        return d <= 0 ? "Replace soon" : "~\(d)d left"
    }

    private var statusColor: Color {
        if item.isExpired { return BNTheme.danger }
        if item.isNearingEnd { return BNTheme.warning }
        return BNTheme.freshGlow
    }

    var body: some View {
        HStack(spacing: 14) {
            BeaconGlow(percentUsed: item.percentUsed, symbolName: item.category.symbolName)
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BNTheme.ink)
                HStack(spacing: 6) {
                    Text(item.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(BNTheme.inkFaded)
                    if !item.detail.isEmpty {
                        Text("·")
                            .foregroundStyle(BNTheme.inkFaded)
                        Text(item.detail)
                            .font(.caption)
                            .foregroundStyle(BNTheme.inkFaded)
                    }
                    Text("·")
                        .foregroundStyle(BNTheme.inkFaded)
                    Text(statusText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(statusColor)
                }
            }

            Spacer()

            Button(action: onReplace) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(BNTheme.backdrop)
                    .padding(10)
                    .background(Circle().fill(BNTheme.freshGlow))
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("replaceButton_\(item.name)")

            Menu {
                Button(action: onEdit) {
                    Label("Edit Item", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("Remove Item", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(BNTheme.inkFaded)
                    .padding(8)
            }
            .accessibilityIdentifier("itemMenu_\(item.name)")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(BNTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(statusColor.opacity(0.4), lineWidth: 1.5)
        )
    }
}

/// Animated glow: a filled glyph whose core color and surrounding halo
/// interpolate continuously with percent-of-life-used via BNTheme's color
/// ramp, animated with SwiftUI's implicit animation on state change.
struct BeaconGlow: View {
    let percentUsed: Double
    let symbolName: String

    private var core: Color { BNTheme.coreColor(percentUsed: percentUsed) }
    private var glow: Color { BNTheme.glowColor(percentUsed: percentUsed) }
    private var radius: CGFloat { BNTheme.glowRadius(percentUsed: percentUsed) }
    private var glowOpacity: Double { BNTheme.glowOpacity(percentUsed: percentUsed) }

    var body: some View {
        ZStack {
            Circle()
                .fill(BNTheme.surfaceRaised)
            Image(systemName: symbolName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(core)
                .shadow(color: glow.opacity(glowOpacity), radius: radius)
                .shadow(color: glow.opacity(glowOpacity * 0.6), radius: radius * 1.6)
        }
        .animation(.easeInOut(duration: 0.6), value: percentUsed)
    }
}

#Preview {
    ItemListView()
        .environmentObject(BeaconStore())
        .environmentObject(PurchaseManager())
}
