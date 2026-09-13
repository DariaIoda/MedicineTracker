import SwiftUI

@main
struct InventoryQRApp: App {
    @State private var store = InventoryStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
        }
    }
}
