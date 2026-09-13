import Foundation
import SwiftData

/// Комната — верхний уровень структуры хранения.
@Model
final class Room {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var createdAt: Date
    /// Идентификатор записи на сервере; nil — комната создана пользователем.
    var remoteID: String?
    /// Пользователь изменял запись, полученную с сервера: синхронизация её не перезаписывает.
    var locallyModified: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \StorageContainer.room)
    var containers: [StorageContainer] = []

    init(id: UUID = UUID(), name: String, icon: String = "house",
         remoteID: String? = nil, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.icon = icon
        self.remoteID = remoteID
        self.createdAt = createdAt
    }

    var sortedContainers: [StorageContainer] {
        containers.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    var itemCount: Int { containers.reduce(0) { $0 + $1.items.count } }
}

/// Контейнер (коробка, ящик, полка), промаркированный QR-кодом.
@Model
final class StorageContainer {
    @Attribute(.unique) var id: UUID
    var name: String
    @Attribute(.unique) var code: String
    var createdAt: Date
    var remoteID: String?
    var locallyModified: Bool = false

    var room: Room?

    @Relationship(deleteRule: .cascade, inverse: \Item.container)
    var items: [Item] = []

    init(id: UUID = UUID(), name: String, code: String, room: Room? = nil,
         remoteID: String? = nil, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.code = code
        self.room = room
        self.remoteID = remoteID
        self.createdAt = createdAt
    }

    var sortedItems: [Item] {
        items.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    var totalQuantity: Int { items.reduce(0) { $0 + $1.quantity } }
}

/// Вещь — материальная ценность внутри контейнера.
@Model
final class Item {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: Int
    /// Ссылка на тип из статического классификатора item_types.json.
    var typeID: String
    var note: String
    var createdAt: Date
    var remoteID: String?
    var locallyModified: Bool = false

    var container: StorageContainer?

    init(id: UUID = UUID(), name: String, quantity: Int = 1, typeID: String = "other",
         note: String = "", container: StorageContainer? = nil,
         remoteID: String? = nil, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.typeID = typeID
        self.note = note
        self.container = container
        self.remoteID = remoteID
        self.createdAt = createdAt
    }

    /// Точное местоположение вещи.
    var path: String {
        let roomName = container?.room?.name ?? "Без комнаты"
        let containerName = container?.name ?? "Без контейнера"
        return "\(roomName) → \(containerName)"
    }
}

/// Отметка об удалении пользователем записи, полученной с сервера,
/// чтобы следующая синхронизация не восстановила её.
@Model
final class DeletedRecord {
    @Attribute(.unique) var remoteID: String
    var deletedAt: Date

    init(remoteID: String, deletedAt: Date = .now) {
        self.remoteID = remoteID
        self.deletedAt = deletedAt
    }
}

/// Маршруты навигации приложения.
enum Route: Hashable {
    case room(UUID)
    case container(UUID)
    case item(UUID)
}
