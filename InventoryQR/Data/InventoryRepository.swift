import Foundation
import SwiftData

/// Ошибки операций с инвентарём.
enum InventoryError: LocalizedError, Equatable {
    case emptyName
    case invalidQuantity
    case duplicateCode(String)
    case notFound

    var errorDescription: String? {
        switch self {
        case .emptyName: return "Название не может быть пустым"
        case .invalidQuantity: return "Количество должно быть больше нуля"
        case .duplicateCode(let code): return "Код \(code) уже используется"
        case .notFound: return "Запись не найдена"
        }
    }
}

/// Контракт слоя данных: чтение, поиск и полный цикл CRUD.
protocol InventoryRepository: AnyObject {
    func rooms() -> [Room]
    func room(id: UUID) -> Room?
    func container(id: UUID) -> StorageContainer?
    func container(code: String) -> StorageContainer?
    func item(id: UUID) -> Item?
    func search(_ query: String) -> [Item]

    @discardableResult func addRoom(name: String, icon: String) throws -> Room
    func updateRoom(_ room: Room, name: String, icon: String) throws
    func deleteRoom(_ room: Room) throws

    @discardableResult func addContainer(name: String, to room: Room) throws -> StorageContainer
    func updateContainer(_ container: StorageContainer, name: String, room: Room) throws
    func deleteContainer(_ container: StorageContainer) throws

    @discardableResult func addItem(name: String, quantity: Int, typeID: String, note: String,
                                    to container: StorageContainer) throws -> Item
    func updateItem(_ item: Item, name: String, quantity: Int, typeID: String, note: String,
                    container: StorageContainer) throws
    func deleteItem(_ item: Item) throws
}

/// Реализация репозитория поверх SwiftData (ModelContext).
final class SwiftDataInventoryRepository: InventoryRepository {
    let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: чтение

    func rooms() -> [Room] {
        let descriptor = FetchDescriptor<Room>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    func room(id: UUID) -> Room? {
        var descriptor = FetchDescriptor<Room>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    func container(id: UUID) -> StorageContainer? {
        var descriptor = FetchDescriptor<StorageContainer>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    func container(code: String) -> StorageContainer? {
        let normalized = code.uppercased()
        var descriptor = FetchDescriptor<StorageContainer>(predicate: #Predicate { $0.code == normalized })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    func item(id: UUID) -> Item? {
        var descriptor = FetchDescriptor<Item>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    /// Поиск по названию и заметке без учёта регистра.
    func search(_ query: String) -> [Item] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }
        let descriptor = FetchDescriptor<Item>(
            predicate: #Predicate { item in
                item.name.localizedStandardContains(text) || item.note.localizedStandardContains(text)
            },
            sortBy: [SortDescriptor(\.name)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: комнаты

    @discardableResult
    func addRoom(name: String, icon: String) throws -> Room {
        let room = Room(name: try validName(name), icon: icon)
        context.insert(room)
        try context.save()
        return room
    }

    func updateRoom(_ room: Room, name: String, icon: String) throws {
        room.name = try validName(name)
        room.icon = icon
        try context.save()
    }

    func deleteRoom(_ room: Room) throws {
        context.delete(room)          // контейнеры и вещи удаляются каскадно
        try context.save()
    }

    // MARK: контейнеры

    @discardableResult
    func addContainer(name: String, to room: Room) throws -> StorageContainer {
        let container = StorageContainer(name: try validName(name), code: nextContainerCode())
        context.insert(container)
        container.room = room
        try context.save()
        return container
    }

    func updateContainer(_ container: StorageContainer, name: String, room: Room) throws {
        container.name = try validName(name)
        container.room = room
        try context.save()
    }

    func deleteContainer(_ container: StorageContainer) throws {
        context.delete(container)     // вещи удаляются каскадно
        try context.save()
    }

    // MARK: вещи

    @discardableResult
    func addItem(name: String, quantity: Int, typeID: String, note: String,
                 to container: StorageContainer) throws -> Item {
        guard quantity > 0 else { throw InventoryError.invalidQuantity }
        let item = Item(name: try validName(name), quantity: quantity, typeID: typeID,
                        note: note.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(item)
        item.container = container
        try context.save()
        return item
    }

    func updateItem(_ item: Item, name: String, quantity: Int, typeID: String, note: String,
                    container: StorageContainer) throws {
        guard quantity > 0 else { throw InventoryError.invalidQuantity }
        item.name = try validName(name)
        item.quantity = quantity
        item.typeID = typeID
        item.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        item.container = container
        try context.save()
    }

    func deleteItem(_ item: Item) throws {
        context.delete(item)
        try context.save()
    }

    // MARK: вспомогательное

    private func validName(_ name: String) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw InventoryError.emptyName }
        return trimmed
    }

    /// Следующий свободный код маркировки вида BOX-0007.
    func nextContainerCode() -> String {
        let codes = ((try? context.fetch(FetchDescriptor<StorageContainer>())) ?? []).map(\.code)
        let numbers = codes.compactMap { code -> Int? in
            guard code.hasPrefix("BOX-") else { return nil }
            return Int(code.dropFirst(4))
        }
        return String(format: "BOX-%04d", (numbers.max() ?? 0) + 1)
    }
}
