import Foundation
import Observation
import UIKit

/// ViewModel главного экрана: иерархия хранения, поиск и удаление.
@Observable
final class InventoryListViewModel {
    private let repository: InventoryRepository
    private let catalog: ItemTypeCatalog

    var searchText = ""
    var expandedContainers: Set<UUID> = []
    var isScannerPresented = false
    var editor: EditorRequest?
    var errorMessage: String?

    init(repository: InventoryRepository, catalog: ItemTypeCatalog) {
        self.repository = repository
        self.catalog = catalog
    }

    var isSearching: Bool { !searchText.trimmingCharacters(in: .whitespaces).isEmpty }

    /// Поиск по названию, заметке и категории классификатора.
    func searchResults(in rooms: [Room]) -> [Item] {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return [] }
        let all = rooms.flatMap(\.containers).flatMap(\.items)
        return all
            .filter {
                $0.name.localizedCaseInsensitiveContains(text)
                    || $0.note.localizedCaseInsensitiveContains(text)
                    || catalog.type(id: $0.typeID).category.localizedCaseInsensitiveContains(text)
            }
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    func isExpanded(_ id: UUID) -> Bool { expandedContainers.contains(id) }

    func setExpanded(_ id: UUID, _ expanded: Bool) {
        if expanded { expandedContainers.insert(id) } else { expandedContainers.remove(id) }
    }

    func delete(_ room: Room) { perform { try repository.deleteRoom(room) } }
    func delete(_ container: StorageContainer) { perform { try repository.deleteContainer(container) } }
    func delete(_ item: Item) { perform { try repository.deleteItem(item) } }

    private func perform(_ action: () throws -> Void) {
        do { try action() } catch { errorMessage = error.localizedDescription }
    }
}

/// Какой редактор открыть (создание или изменение записи).
enum EditorRequest: Identifiable {
    case newRoom
    case editRoom(Room)
    case newContainer(room: Room?)
    case editContainer(StorageContainer)
    case newItem(container: StorageContainer?)
    case editItem(Item)

    var id: String {
        switch self {
        case .newRoom: return "newRoom"
        case .editRoom(let r): return "room-\(r.id)"
        case .newContainer(let r): return "newContainer-\(r?.id.uuidString ?? "-")"
        case .editContainer(let c): return "container-\(c.id)"
        case .newItem(let c): return "newItem-\(c?.id.uuidString ?? "-")"
        case .editItem(let i): return "item-\(i.id)"
        }
    }
}

/// ViewModel формы комнаты.
@Observable
final class RoomFormViewModel {
    static let icons = ["house", "sofa", "bed.double", "fork.knife", "archivebox", "car",
                        "desktopcomputer", "shower", "figure.and.child.holdinghands", "leaf"]

    private let repository: InventoryRepository
    private let room: Room?

    var name: String
    var icon: String
    var errorMessage: String?

    init(repository: InventoryRepository, room: Room? = nil) {
        self.repository = repository
        self.room = room
        name = room?.name ?? ""
        icon = room?.icon ?? "house"
    }

    var title: String { room == nil ? "Новая комната" : "Комната" }
    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    func save() -> Bool {
        do {
            if let room {
                try repository.updateRoom(room, name: name, icon: icon)
            } else {
                try repository.addRoom(name: name, icon: icon)
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

/// ViewModel формы контейнера.
@Observable
final class ContainerFormViewModel {
    private let repository: InventoryRepository
    private let container: StorageContainer?

    var name: String
    var roomID: UUID?
    var errorMessage: String?

    init(repository: InventoryRepository, container: StorageContainer? = nil, room: Room? = nil) {
        self.repository = repository
        self.container = container
        name = container?.name ?? ""
        roomID = container?.room?.id ?? room?.id ?? repository.rooms().first?.id
    }

    var title: String { container == nil ? "Новый контейнер" : "Контейнер" }
    var code: String? { container?.code }
    var rooms: [Room] { repository.rooms() }
    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && roomID != nil }

    func save() -> Bool {
        guard let roomID, let room = repository.room(id: roomID) else {
            errorMessage = "Выберите комнату"
            return false
        }
        do {
            if let container {
                try repository.updateContainer(container, name: name, room: room)
            } else {
                try repository.addContainer(name: name, to: room)
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

/// Контейнеры одной комнаты для выбора местоположения вещи.
struct ContainerGroup: Identifiable {
    let room: Room
    let containers: [StorageContainer]
    var id: UUID { room.id }
}

/// ViewModel формы вещи.
@Observable
final class ItemFormViewModel {
    private let repository: InventoryRepository
    private let item: Item?
    let catalog: ItemTypeCatalog

    var name: String
    var quantity: Int
    var typeID: String
    var note: String
    var containerID: UUID?
    var errorMessage: String?

    init(repository: InventoryRepository, catalog: ItemTypeCatalog,
         item: Item? = nil, container: StorageContainer? = nil) {
        self.repository = repository
        self.catalog = catalog
        self.item = item
        name = item?.name ?? ""
        quantity = item?.quantity ?? 1
        typeID = item?.typeID ?? catalog.types.first?.id ?? ItemTypeCatalog.fallback.id
        note = item?.note ?? ""
        containerID = item?.container?.id ?? container?.id
            ?? repository.rooms().flatMap(\.sortedContainers).first?.id
    }

    var title: String { item == nil ? "Новая вещь" : "Вещь" }
    var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && containerID != nil && quantity > 0 }

    /// Контейнеры, сгруппированные по комнатам, для выбора местоположения.
    var containerChoices: [ContainerGroup] {
        repository.rooms()
            .map { ContainerGroup(room: $0, containers: $0.sortedContainers) }
            .filter { !$0.containers.isEmpty }
    }

    func save() -> Bool {
        guard let containerID, let container = repository.container(id: containerID) else {
            errorMessage = "Выберите контейнер"
            return false
        }
        do {
            if let item {
                try repository.updateItem(item, name: name, quantity: quantity, typeID: typeID,
                                          note: note, container: container)
            } else {
                try repository.addItem(name: name, quantity: quantity, typeID: typeID,
                                       note: note, to: container)
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

/// ViewModel карточки контейнера: перечень вещей и QR-код маркировки.
@Observable
final class ContainerDetailViewModel {
    private let repository: InventoryRepository
    private let generator: QRCodeGenerating
    let containerID: UUID

    @ObservationIgnored private var cachedQR: (payload: String, image: UIImage)?

    init(containerID: UUID, repository: InventoryRepository, generator: QRCodeGenerating) {
        self.containerID = containerID
        self.repository = repository
        self.generator = generator
    }

    var container: StorageContainer? { repository.container(id: containerID) }
    var title: String { container?.name ?? "Контейнер" }
    var roomName: String { container?.room?.name ?? "—" }
    var code: String { container?.code ?? "" }
    var items: [Item] { container?.sortedItems ?? [] }
    var positionsCount: Int { items.count }
    var totalQuantity: Int { items.reduce(0) { $0 + $1.quantity } }
    var payload: String { QRPayload(containerCode: code).stringValue }

    var qrImage: UIImage? {
        if let cachedQR, cachedQR.payload == payload { return cachedQR.image }
        guard !code.isEmpty, let image = generator.makeImage(for: payload, side: 600) else { return nil }
        cachedQR = (payload, image)
        return image
    }

    func delete(_ item: Item) {
        try? repository.deleteItem(item)
    }
}

/// ViewModel сканера: разбирает считанный код и находит контейнер.
@Observable
final class ScannerViewModel {
    enum State: Equatable {
        case scanning
        case found(UUID)
        case unknownContainer(code: String)
        case foreignCode(String)
    }

    private let repository: InventoryRepository
    private(set) var state: State = .scanning

    init(repository: InventoryRepository) {
        self.repository = repository
    }

    var isFound: Bool {
        if case .found = state { return true }
        return false
    }

    var foundContainer: StorageContainer? {
        guard case .found(let id) = state else { return nil }
        return repository.container(id: id)
    }

    var foundItems: [Item] { foundContainer?.sortedItems ?? [] }

    func handle(scannedValue raw: String) {
        guard let payload = QRPayload.parse(raw) else {
            state = .foreignCode(raw)
            return
        }
        if let container = repository.container(code: payload.containerCode) {
            state = .found(container.id)
        } else {
            state = .unknownContainer(code: payload.containerCode)
        }
    }

    func reset() { state = .scanning }
}

/// ViewModel экрана комнаты.
@Observable
final class RoomViewModel {
    private let repository: InventoryRepository
    let roomID: UUID
    var editor: EditorRequest?
    var confirmDelete = false

    init(roomID: UUID, repository: InventoryRepository) {
        self.roomID = roomID
        self.repository = repository
    }

    var room: Room? { repository.room(id: roomID) }

    func delete(_ container: StorageContainer) {
        try? repository.deleteContainer(container)
    }

    /// Удаляет комнату; контейнеры и вещи удаляются каскадно.
    func deleteRoom() -> Bool {
        guard let room else { return false }
        return (try? repository.deleteRoom(room)) != nil
    }
}

/// ViewModel экрана вещи.
@Observable
final class ItemDetailViewModel {
    private let repository: InventoryRepository
    private let catalog: ItemTypeCatalog
    let itemID: UUID
    var editor: EditorRequest?

    init(itemID: UUID, repository: InventoryRepository, catalog: ItemTypeCatalog) {
        self.itemID = itemID
        self.repository = repository
        self.catalog = catalog
    }

    var item: Item? { repository.item(id: itemID) }
    var type: ItemType { catalog.type(id: item?.typeID ?? ItemTypeCatalog.fallback.id) }

    func delete() -> Bool {
        guard let item else { return false }
        return (try? repository.deleteItem(item)) != nil
    }
}
