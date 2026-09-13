import Foundation
import Observation
import UIKit

/// ViewModel главного экрана: иерархия хранения и поиск.
@Observable
final class InventoryListViewModel {
    private let repository: InventoryRepository

    var searchText = ""
    var expandedContainers: Set<StorageContainer.ID> = []
    var isScannerPresented = false

    init(repository: InventoryRepository) {
        self.repository = repository
    }

    var rooms: [Room] { repository.rooms }
    var isSearching: Bool { !searchText.trimmingCharacters(in: .whitespaces).isEmpty }
    var searchResults: [ItemLocation] { repository.search(searchText) }

    var roomCount: Int { rooms.count }
    var containerCount: Int { rooms.reduce(0) { $0 + $1.containers.count } }
    var itemCount: Int { rooms.reduce(0) { $0 + $1.itemCount } }

    func isExpanded(_ id: StorageContainer.ID) -> Bool {
        expandedContainers.contains(id)
    }

    func setExpanded(_ id: StorageContainer.ID, _ expanded: Bool) {
        if expanded { expandedContainers.insert(id) } else { expandedContainers.remove(id) }
    }
}

/// ViewModel карточки контейнера: перечень вещей и QR-код маркировки.
@Observable
final class ContainerDetailViewModel {
    private let repository: InventoryRepository
    private let generator: QRCodeGenerating
    let containerID: StorageContainer.ID

    @ObservationIgnored private var cachedQR: (payload: String, image: UIImage)?

    init(containerID: StorageContainer.ID, repository: InventoryRepository, generator: QRCodeGenerating) {
        self.containerID = containerID
        self.repository = repository
        self.generator = generator
    }

    var location: ContainerLocation? { repository.container(id: containerID) }
    var title: String { location?.container.name ?? "Контейнер" }
    var roomName: String { location?.room.name ?? "—" }
    var code: String { location?.container.code ?? "" }

    var items: [Item] {
        (location?.container.items ?? [])
            .sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    var positionsCount: Int { items.count }
    var totalQuantity: Int { items.reduce(0) { $0 + $1.quantity } }

    var payload: String { QRPayload(containerCode: code).stringValue }

    /// QR-код строится один раз и переиспользуется, пока не изменится код контейнера.
    var qrImage: UIImage? {
        if let cachedQR, cachedQR.payload == payload { return cachedQR.image }
        guard !code.isEmpty, let image = generator.makeImage(for: payload, side: 600) else { return nil }
        cachedQR = (payload, image)
        return image
    }
}

/// ViewModel экрана вещи.
@Observable
final class ItemDetailViewModel {
    private let repository: InventoryRepository
    let itemID: Item.ID

    init(itemID: Item.ID, repository: InventoryRepository) {
        self.itemID = itemID
        self.repository = repository
    }

    var location: ItemLocation? { repository.location(ofItem: itemID) }
}

/// ViewModel экрана комнаты.
@Observable
final class RoomViewModel {
    private let repository: InventoryRepository
    let roomID: Room.ID

    init(roomID: Room.ID, repository: InventoryRepository) {
        self.roomID = roomID
        self.repository = repository
    }

    var room: Room? { repository.room(id: roomID) }
}

/// ViewModel сканера: разбирает считанный код и находит контейнер.
@Observable
final class ScannerViewModel {
    enum State: Equatable {
        case scanning
        case found(ContainerLocation)
        case unknownContainer(code: String)
        case foreignCode(String)
    }

    private let repository: InventoryRepository
    private(set) var state: State = .scanning
    private(set) var lastRawValue: String?

    init(repository: InventoryRepository) {
        self.repository = repository
    }

    var isFound: Bool {
        if case .found = state { return true }
        return false
    }

    var foundItems: [Item] {
        guard case .found(let location) = state else { return [] }
        return location.container.items.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
    }

    /// Обработка строки, полученной от камеры или mock-сканера.
    func handle(scannedValue raw: String) {
        lastRawValue = raw
        guard let payload = QRPayload.parse(raw) else {
            state = .foreignCode(raw)
            return
        }
        if let location = repository.container(code: payload.containerCode) {
            state = .found(location)
        } else {
            state = .unknownContainer(code: payload.containerCode)
        }
    }

    func reset() {
        state = .scanning
        lastRawValue = nil
    }
}
