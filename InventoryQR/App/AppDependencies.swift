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

    init(repository: InventoryRepository,
         catalog: ItemTypeCatalog,
         qrGenerator: QRCodeGenerating = CoreImageQRCodeGenerator(),
         qrDecoder: QRCodeDecoding = VisionQRCodeDecoder()) {
        self.repository = repository
        self.catalog = catalog
        self.qrGenerator = qrGenerator
        self.qrDecoder = qrDecoder
    }

    convenience init(context: ModelContext) {
        let catalog: ItemTypeCatalog
        do {
            catalog = try ItemTypeCatalog()
        } catch {
            fatalError("Не удалось прочитать классификатор item_types.json: \(error)")
        }
        self.init(repository: SwiftDataInventoryRepository(context: context), catalog: catalog)
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
