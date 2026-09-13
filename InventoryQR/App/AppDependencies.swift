import Foundation
import Observation

/// Контейнер зависимостей: единственное место, где выбираются конкретные реализации.
@Observable
final class AppDependencies {
    let repository: InventoryRepository
    let qrGenerator: QRCodeGenerating
    let qrDecoder: QRCodeDecoding

    init(repository: InventoryRepository = InMemoryInventoryRepository(),
         qrGenerator: QRCodeGenerating = CoreImageQRCodeGenerator(),
         qrDecoder: QRCodeDecoding = VisionQRCodeDecoder()) {
        self.repository = repository
        self.qrGenerator = qrGenerator
        self.qrDecoder = qrDecoder
    }

    /// Использовать ли mock-сканер вместо камеры (симулятор или запуск UI-тестов).
    var usesMockScanner: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return ProcessInfo.processInfo.arguments.contains("-mockScanner")
        #endif
    }
}
