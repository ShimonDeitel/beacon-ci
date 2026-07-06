import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            ItemListView()
                .tabItem {
                    Label("Home", systemImage: "lightbulb.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(BNTheme.freshGlow)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(BNTheme.surface)
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(BeaconStore())
        .environmentObject(PurchaseManager())
}
