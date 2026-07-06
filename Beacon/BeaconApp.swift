import SwiftUI

@main
struct BeaconApp: App {
    @StateObject private var store = BeaconStore()
    @StateObject private var purchases = PurchaseManager()
    @AppStorage("beacon_haptics_enabled") private var hapticsEnabled: Bool = true

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(store)
                .environmentObject(purchases)
                .preferredColorScheme(.dark)
                .onAppear {
                    Haptics.enabled = hapticsEnabled
                }
        }
    }
}
