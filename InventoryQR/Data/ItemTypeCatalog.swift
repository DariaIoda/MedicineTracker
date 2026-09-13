import Foundation

/// Тип имущества из статического классификатора (только чтение).
struct ItemType: Decodable, Identifiable, Hashable {
    let id: String
    let category: String
    let icon: String
}

/// Корневой объект файла item_types.json.
private struct ItemTypeFile: Decodable {
    let version: Int
    let types: [ItemType]
}

/// Классификатор типов имущества, загружаемый из JSON-файла в бандле приложения.
/// Файл входит в ресурсы приложения и не изменяется из программы.
final class ItemTypeCatalog {
    enum LoadError: Error, Equatable {
        case fileNotFound(String)
        case duplicateIdentifier(String)
    }

    static let fallback = ItemType(id: "other", category: "Прочее", icon: "shippingbox")

    let version: Int
    let types: [ItemType]
    private let byID: [String: ItemType]

    init(data: Data) throws {
        let file = try JSONDecoder().decode(ItemTypeFile.self, from: data)
        var map: [String: ItemType] = [:]
        for type in file.types {
            guard map[type.id] == nil else { throw LoadError.duplicateIdentifier(type.id) }
            map[type.id] = type
        }
        version = file.version
        types = file.types
        byID = map
    }

    convenience init(bundle: Bundle = .main, resource: String = "item_types") throws {
        guard let url = bundle.url(forResource: resource, withExtension: "json") else {
            throw LoadError.fileNotFound(resource)
        }
        try self.init(data: Data(contentsOf: url))
    }

    func type(id: String) -> ItemType {
        byID[id] ?? byID[Self.fallback.id] ?? Self.fallback
    }

    func contains(_ id: String) -> Bool { byID[id] != nil }
}
