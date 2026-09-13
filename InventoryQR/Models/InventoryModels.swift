import Foundation

/// Вещь, хранящаяся в контейнере.
struct Item: Identifiable, Hashable {
    let id: UUID
    var name: String
    var quantity: Int
    var category: String
    var icon: String
    var note: String

    init(id: UUID = UUID(), name: String, quantity: Int = 1,
         category: String, icon: String, note: String = "") {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.category = category
        self.icon = icon
        self.note = note
    }
}

/// Контейнер (коробка, ящик, полка) внутри комнаты.
struct StorageContainer: Identifiable, Hashable {
    let id: UUID
    var name: String
    var code: String
    var items: [Item]

    init(id: UUID = UUID(), name: String, code: String, items: [Item] = []) {
        self.id = id
        self.name = name
        self.code = code
        self.items = items
    }

    var totalQuantity: Int { items.reduce(0) { $0 + $1.quantity } }
}

/// Комната — верхний уровень структуры хранения.
struct Room: Identifiable, Hashable {
    let id: UUID
    var name: String
    var icon: String
    var containers: [StorageContainer]

    init(id: UUID = UUID(), name: String, icon: String, containers: [StorageContainer] = []) {
        self.id = id
        self.name = name
        self.icon = icon
        self.containers = containers
    }

    var itemCount: Int { containers.reduce(0) { $0 + $1.items.count } }
}

/// Результат поиска: вещь вместе с точным местоположением.
struct ItemLocation: Identifiable, Hashable {
    let room: Room
    let container: StorageContainer
    let item: Item

    var id: UUID { item.id }
    var path: String { "\(room.name) → \(container.name)" }
}

/// Маршруты навигации приложения.
enum Route: Hashable {
    case room(Room.ID)
    case container(StorageContainer.ID)
    case item(Item.ID)
}
