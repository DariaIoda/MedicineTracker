import SwiftData
import SwiftUI

@main
struct MedicineTrackerApp: App {
    private let modelContainer: ModelContainer
    @State private var dependencies: AppDependencies

    init() {
        // Читаем аргументы запуска (чтобы понять, запущен ли UI-тест)
        let arguments = ProcessInfo.processInfo.arguments
        let inMemory = arguments.contains("-uiTesting")
        
        // Принудительно создаем папку Application Support только если это физическая БД
        if !inMemory {
            let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            if !FileManager.default.fileExists(atPath: appSupportDir.path) {
                try? FileManager.default.createDirectory(at: appSupportDir, withIntermediateDirectories: true, attributes: nil)
            }
        }

        let schema = Schema([Medicine.self])
        // Передаем флаг inMemory в конфигурацию
        let configuration = ModelConfiguration("MedicineTracker", schema: schema, isStoredInMemoryOnly: inMemory)
        
        do {
            modelContainer = try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Не удалось открыть базу данных: \(error)")
        }
        
        let context = modelContainer.mainContext
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