import Foundation
import Observation
import SwiftData

@Observable
final class AppDependencies {
    let repository: MedicineRepository
    let catalog: InteractionCatalog
    let textDecoder: TextDecoding
    
    init(repository: MedicineRepository, catalog: InteractionCatalog, textDecoder: TextDecoding = VisionTextDecoder()) {
        self.repository = repository
        self.catalog = catalog
        self.textDecoder = textDecoder
    }
    
    convenience init(context: ModelContext) {
        let catalog: InteractionCatalog
        do {
            catalog = try InteractionCatalog()
        } catch {
            fatalError("Не удалось прочитать файл interactions.json: \(error)")
        }
        self.init(repository: SwiftDataMedicineRepository(context: context), catalog: catalog)
    }
}