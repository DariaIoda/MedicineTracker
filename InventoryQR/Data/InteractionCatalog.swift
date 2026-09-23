import Foundation

/// Структура взаимодействия объявлена с протоколом Decodable, файл читается из бандла и разбирается JSONDecoder[cite: 5].
struct Interaction: Decodable, Identifiable, Hashable {
    let id: String
    let substanceA: String
    let substanceB: String
    let danger: String
}

private struct InteractionFile: Decodable {
    let version: Int
    let interactions: [Interaction]
}

/// Классификатор несовместимости, загружаемый из JSON-файла. Доступен только для чтения[cite: 5].
final class InteractionCatalog {
    enum LoadError: Error, Equatable {
        case fileNotFound(String)
        case duplicateIdentifier(String)
    }
    
    let version: Int
    let interactions: [Interaction]
    
    init(data: Data) throws {
        let file = try JSONDecoder().decode(InteractionFile.self, from: data)
        version = file.version
        interactions = file.interactions
    }
    
    convenience init(bundle: Bundle = .main, resource: String = "interactions") throws {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw LoadError.fileNotFound(resource)
        }
        try self.init(data: Data(contentsOf: url))
    }
    
    /// Поиск конфликта между отсканированным лекарством и списком текущих
    func checkConflict(scannedName: String, currentMedicines: [String]) -> Interaction? {
        let scanned = scannedName.lowercased()
        for interaction in interactions {
            let a = interaction.substanceA.lowercased()
            let b = interaction.substanceB.lowercased()
            
            if scanned.contains(a) || scanned.contains(b) {
                for current in currentMedicines {
                    let currentLower = current.lowercased()
                    if (scanned.contains(a) && currentLower.contains(b)) ||
                       (scanned.contains(b) && currentLower.contains(a)) {
                        return interaction
                    }
                }
            }
        }
        return nil
    }
}