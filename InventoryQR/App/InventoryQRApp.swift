import SwiftData
import SwiftUI

@main
struct InventoryQRApp: App {
    private let modelContainer: ModelContainer
    @State private var dependencies: AppDependencies

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let inMemory = arguments.contains("-uiTesting")
        let schema = Schema([Room.self, StorageContainer.self, Item.self])
        let configuration = ModelConfiguration("Inventory", schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Не удалось открыть базу данных: \(error)")
        }
        let context = modelContainer.mainContext
        if arguments.contains("-seedSampleData") {
            SampleInventory.insert(into: context)
        }
        _dependencies = State(initialValue: AppDependencies(context: context))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(dependencies)
        }
        .modelContainer(modelContainer)
    }
}
