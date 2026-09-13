import SwiftData
import SwiftUI

@main
struct InventoryQRApp: App {
    private let modelContainer: ModelContainer
    private let isOffline: Bool
    @State private var dependencies: AppDependencies

    init() {
        let arguments = ProcessInfo.processInfo.arguments
        let schema = Schema([Room.self, StorageContainer.self, Item.self, DeletedRecord.self])
        let configuration: ModelConfiguration
        if arguments.contains("-uiTesting") {
            configuration = ModelConfiguration("Inventory", schema: schema, isStoredInMemoryOnly: true)
        } else {
            let url = Self.storeURL
            if arguments.contains("-resetStore") {
                Self.removeStore(at: url)
            }
            configuration = ModelConfiguration(schema: schema, url: url)
        }
        do {
            modelContainer = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Не удалось открыть базу данных: \(error)")
        }
        let context = modelContainer.mainContext
        if arguments.contains("-seedSampleData") {
            SampleInventory.insert(into: context)
        }
        isOffline = arguments.contains("-offline")
        _dependencies = State(initialValue: AppDependencies(context: context))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(dependencies)
                .task {
                    // Начальные данные загружаются через REST API при каждом старте приложения
                    if !isOffline { dependencies.sync.syncOnLaunch() }
                }
        }
        .modelContainer(modelContainer)
    }

    /// Файл базы данных SwiftData в папке Application Support.
    private static var storeURL: URL {
        let folder = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appending(path: "Inventory.store")
    }

    /// Удаляет базу данных вместе со служебными файлами журнала (используется UI-тестами).
    private static func removeStore(at url: URL) {
        for suffix in ["", "-shm", "-wal"] {
            try? FileManager.default.removeItem(at: URL(fileURLWithPath: url.path + suffix))
        }
    }
}
