import Combine
import Foundation
import Observation
import SwiftData

/// Итог слияния данных с сервера с локальной базой.
struct SyncReport: Equatable {
    var inserted = 0
    var updated = 0
    var total: Int { inserted + updated }
}

/// Загрузка начальных данных через REST API при каждом старте приложения и их слияние с SwiftData.
/// Записи сервера сопоставляются по remoteID: новые добавляются, существующие обновляются.
/// Данные, созданные пользователем (remoteID == nil), никогда не изменяются и не удаляются.
@Observable
final class InventorySyncService {
    enum State: Equatable {
        case idle
        case loading
        case synced(SyncReport, Date)
        case failed(String)
    }

    private(set) var state: State = .idle

    private let api: InventoryAPI
    private let context: ModelContext
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init(api: InventoryAPI, context: ModelContext) {
        self.api = api
        self.context = context
    }

    /// Асинхронная цепочка Combine: сеть в фоне → слияние на главном потоке.
    func syncOnLaunch() {
        guard state != .loading else { return }
        state = .loading
        api.fetchSnapshot()
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.state = .failed(error.localizedDescription)
                }
            } receiveValue: { [weak self] snapshot in
                guard let self else { return }
                do {
                    let report = try self.apply(snapshot)
                    self.state = .synced(report, .now)
                } catch {
                    self.state = .failed(error.localizedDescription)
                }
            }
            .store(in: &cancellables)
    }

    /// Слияние снимка сервера с локальной базой данных.
    @discardableResult
    func apply(_ snapshot: InventorySnapshot) throws -> SyncReport {
        var report = SyncReport()
        let deleted = Set(try context.fetch(FetchDescriptor<DeletedRecord>()).map(\.remoteID))

        let rooms = try context.fetch(FetchDescriptor<Room>())
        var roomsByRemote = Dictionary(rooms.compactMap { r in r.remoteID.map { ($0, r) } }, uniquingKeysWith: { first, _ in first })
        for dto in snapshot.rooms where !deleted.contains(dto.id) {
            if let room = roomsByRemote[dto.id] {
                if !room.locallyModified, room.name != dto.name || room.icon != dto.icon {
                    room.name = dto.name
                    room.icon = dto.icon
                    report.updated += 1
                }
            } else {
                let room = Room(name: dto.name, icon: dto.icon, remoteID: dto.id)
                context.insert(room)
                roomsByRemote[dto.id] = room
                report.inserted += 1
            }
        }

        let containers = try context.fetch(FetchDescriptor<StorageContainer>())
        var containersByRemote = Dictionary(containers.compactMap { c in c.remoteID.map { ($0, c) } }, uniquingKeysWith: { first, _ in first })
        var usedCodes = Set(containers.map(\.code))
        for dto in snapshot.containers where !deleted.contains(dto.id) {
            guard let room = roomsByRemote[dto.roomID] else { continue }
            if let container = containersByRemote[dto.id] {
                if !container.locallyModified, container.name != dto.name || container.room?.id != room.id {
                    container.name = dto.name
                    container.room = room
                    report.updated += 1
                }
            } else {
                // Если пользователь уже занял этот код, его контейнер получает следующий свободный код
                if let clash = containers.first(where: { $0.code == dto.code && $0.remoteID == nil }) {
                    clash.code = Self.nextFreeCode(after: usedCodes.union([dto.code]))
                    usedCodes.insert(clash.code)
                }
                let container = StorageContainer(name: dto.name, code: dto.code, remoteID: dto.id)
                context.insert(container)
                container.room = room
                containersByRemote[dto.id] = container
                usedCodes.insert(dto.code)
                report.inserted += 1
            }
        }

        let items = try context.fetch(FetchDescriptor<Item>())
        let itemsByRemote = Dictionary(items.compactMap { i in i.remoteID.map { ($0, i) } }, uniquingKeysWith: { first, _ in first })
        for dto in snapshot.items where !deleted.contains(dto.id) {
            guard let container = containersByRemote[dto.containerID] else { continue }
            let note = dto.note ?? ""
            if let item = itemsByRemote[dto.id] {
                if !item.locallyModified, item.name != dto.name || item.quantity != dto.quantity || item.typeID != dto.typeID
                    || item.note != note || item.container?.id != container.id {
                    item.name = dto.name
                    item.quantity = dto.quantity
                    item.typeID = dto.typeID
                    item.note = note
                    item.container = container
                    report.updated += 1
                }
            } else {
                let item = Item(name: dto.name, quantity: dto.quantity, typeID: dto.typeID,
                                note: note, remoteID: dto.id)
                context.insert(item)
                item.container = container
                report.inserted += 1
            }
        }

        try context.save()
        return report
    }

    static func nextFreeCode(after codes: Set<String>) -> String {
        let maxNumber = codes.compactMap { $0.hasPrefix("BOX-") ? Int($0.dropFirst(4)) : nil }.max() ?? 0
        return String(format: "BOX-%04d", maxNumber + 1)
    }
}
