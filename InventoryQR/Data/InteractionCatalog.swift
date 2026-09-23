import Foundation

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

final class InteractionCatalog {
    let interactions: [Interaction]
    
    init(data: Data) throws {
        let file = try JSONDecoder().decode(InteractionFile.self, from: data)
        interactions = file.interactions
    }
    
    convenience init(bundle: Bundle = .main, resource: String = "interactions") throws {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw NSError(domain: "InteractionCatalog", code: 404, userInfo: nil)
        }
        try self.init(data: Data(contentsOf: url))
    }
    
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