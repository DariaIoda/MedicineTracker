import Foundation
import Observation
import SwiftData

/// Контейнер зависимостей: единственное место, где выбираются конкретные реализации.
@Observable
final class AppDependencies {
    let repository: InventoryRepository
    let catalog: ItemTypeCatalog
    let qrGenerator: QRCodeGenerating
    let qrDecoder: QRCodeDecoding
    let sync: InventorySyncService
    let exporter: ContainerExporter

    init(repository: InventoryRepository,
         catalog: ItemTypeCatalog,
         sync: InventorySyncService,
         qrGenerator: QRCodeGenerating = CoreImageQRCodeGenerator(),
         qrDecoder: QRCodeDecoding = VisionQRCodeDecoder()) {
        self.repository = repository
        self.catalog = catalog
        self.sync = sync
        self.qrGenerator = qrGenerator
        self.qrDecoder = qrDecoder
        self.exporter = ContainerExporter(catalog: catalog)
    }

    convenience init(context: ModelContext) {
        let catalog: ItemTypeCatalog
        do {
            catalog = try ItemTypeCatalog()
        } catch {
            fatalError("Не удалось прочитать классификатор item_types.json: \(error)")
        }
        let api: InventoryAPI
        if let override = ProcessInfo.processInfo.environment["INVENTORY_API_URL"], let url = URL(string: override) {
            api = InventoryAPIClient(baseURL: url)
        } else {
            api = InventoryAPIClient()
        }
        self.init(repository: SwiftDataInventoryRepository(context: context),
                  catalog: catalog,
                  sync: InventorySyncService(api: api, context: context))
    }

    /// Использовать ли mock-сканер вместо камеры (симулятор или явный аргумент запуска).
    var usesMockScanner: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return ProcessInfo.processInfo.arguments.contains("-mockScanner")
        #endif
    }
}
