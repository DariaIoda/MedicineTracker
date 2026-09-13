import Foundation
import Observation

/// Источник данных интерфейса. На этом этапе хранит демонстрационные данные в памяти.
@Observable
final class InventoryStore {
    var rooms: [Room]

    init(rooms: [Room] = SampleInventory.rooms) {
        self.rooms = rooms
    }

    var containerCount: Int { rooms.reduce(0) { $0 + $1.containers.count } }
    var itemCount: Int { rooms.reduce(0) { $0 + $1.itemCount } }

    func room(id: Room.ID) -> Room? {
        rooms.first { $0.id == id }
    }

    func container(id: StorageContainer.ID) -> (room: Room, container: StorageContainer)? {
        for room in rooms {
            if let container = room.containers.first(where: { $0.id == id }) {
                return (room, container)
            }
        }
        return nil
    }

    func location(ofItem id: Item.ID) -> ItemLocation? {
        allLocations.first { $0.item.id == id }
    }

    var allLocations: [ItemLocation] {
        rooms.flatMap { room in
            room.containers.flatMap { container in
                container.items.map { ItemLocation(room: room, container: container, item: $0) }
            }
        }
    }

    /// Текстовый поиск по названию, категории и заметке вещи.
    func search(_ query: String) -> [ItemLocation] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }
        return allLocations
            .filter {
                $0.item.name.localizedCaseInsensitiveContains(text)
                    || $0.item.category.localizedCaseInsensitiveContains(text)
                    || $0.item.note.localizedCaseInsensitiveContains(text)
            }
            .sorted { $0.item.name.localizedCompare($1.item.name) == .orderedAscending }
    }
}
