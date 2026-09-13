import Foundation
import Observation

/// Контракт слоя данных. ViewModel зависят только от протокола,
/// поэтому реализацию (память, база данных, сеть) можно подменить.
protocol InventoryRepository: AnyObject {
    var rooms: [Room] { get }
    func room(id: Room.ID) -> Room?
    func container(id: StorageContainer.ID) -> ContainerLocation?
    func container(code: String) -> ContainerLocation?
    func location(ofItem id: Item.ID) -> ItemLocation?
    func search(_ query: String) -> [ItemLocation]
}

/// Контейнер вместе с комнатой, в которой он находится.
struct ContainerLocation: Hashable {
    let room: Room
    let container: StorageContainer
}

/// Реализация репозитория в оперативной памяти.
@Observable
final class InMemoryInventoryRepository: InventoryRepository {
    private(set) var rooms: [Room]

    init(rooms: [Room] = SampleInventory.rooms) {
        self.rooms = rooms
    }

    func room(id: Room.ID) -> Room? {
        rooms.first { $0.id == id }
    }

    func container(id: StorageContainer.ID) -> ContainerLocation? {
        allContainers.first { $0.container.id == id }
    }

    func container(code: String) -> ContainerLocation? {
        allContainers.first { $0.container.code.caseInsensitiveCompare(code) == .orderedSame }
    }

    func location(ofItem id: Item.ID) -> ItemLocation? {
        allLocations.first { $0.item.id == id }
    }

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

    private var allContainers: [ContainerLocation] {
        rooms.flatMap { room in room.containers.map { ContainerLocation(room: room, container: $0) } }
    }

    private var allLocations: [ItemLocation] {
        rooms.flatMap { room in
            room.containers.flatMap { container in
                container.items.map { ItemLocation(room: room, container: container, item: $0) }
            }
        }
    }
}
