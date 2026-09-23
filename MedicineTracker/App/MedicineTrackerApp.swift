import SwiftData
import SwiftUI

@main
struct MedicineTrackerApp: App {
    private let modelContainer: ModelContainer
    @State private var dependencies: AppDependencies

    init() {
        let schema = Schema([Medicine.self])
        let configuration = ModelConfiguration("MedicineTracker", schema: schema)
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