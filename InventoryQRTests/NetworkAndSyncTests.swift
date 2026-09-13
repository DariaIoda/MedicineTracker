import Combine
import SwiftData
import XCTest
@testable import InventoryQR

/// Подменный URLProtocol: отдаёт заранее заданные ответы вместо реальной сети.
final class StubURLProtocol: URLProtocol {
    static var responses: [String: (status: Int, body: Data)] = [:]

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let path = request.url?.lastPathComponent ?? ""
        let stub = Self.responses[path] ?? (404, Data())
        let response = HTTPURLResponse(url: request.url!, statusCode: stub.status, httpVersion: nil,
                                       headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: stub.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

final class InventoryAPIClientTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    private func makeClient() -> InventoryAPIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return InventoryAPIClient(baseURL: URL(string: "https://example.test/api")!,
                                  session: URLSession(configuration: configuration))
    }

    override func setUp() {
        StubURLProtocol.responses = [
            "rooms": (200, Data(#"[{"id":"room-1","name":"Кладовая","icon":"archivebox"}]"#.utf8)),
            "containers": (200, Data(#"[{"id":"cont-1","name":"Коробка","code":"BOX-0001","room_id":"room-1"}]"#.utf8)),
            "items": (200, Data(#"[{"id":"item-1","name":"Шуруповёрт","quantity":1,"type_id":"tools","container_id":"cont-1","note":null}]"#.utf8))
        ]
    }

    func testSnapshotIsDecodedWithSnakeCaseKeys() {
        let done = expectation(description: "snapshot")
        makeClient().fetchSnapshot().sink { completion in
            if case .failure(let error) = completion { XCTFail("\(error)") }
        } receiveValue: { snapshot in
            XCTAssertEqual(snapshot.containers.first?.roomID, "room-1")
            XCTAssertEqual(snapshot.items.first?.typeID, "tools")
            XCTAssertNil(snapshot.items.first?.note)
            done.fulfill()
        }.store(in: &cancellables)
        wait(for: [done], timeout: 5)
    }

    func testServerErrorIsReported() {
        StubURLProtocol.responses["items"] = (503, Data())
        let done = expectation(description: "error")
        makeClient().fetchSnapshot().sink { completion in
            if case .failure(let error) = completion {
                XCTAssertEqual(error, .badStatus(503))
                done.fulfill()
            }
        } receiveValue: { _ in XCTFail("Ожидалась ошибка") }
        .store(in: &cancellables)
        wait(for: [done], timeout: 5)
    }

    func testBrokenJSONIsReported() {
        StubURLProtocol.responses["rooms"] = (200, Data("{не json".utf8))
        let done = expectation(description: "decoding")
        makeClient().request([RoomDTO].self, path: "rooms").sink { completion in
            if case .failure(.decoding) = completion { done.fulfill() }
        } receiveValue: { _ in XCTFail("Ожидалась ошибка разбора") }
        .store(in: &cancellables)
        wait(for: [done], timeout: 5)
    }
}

final class InventorySyncTests: XCTestCase {
    private struct NoNetwork: InventoryAPI {
        func fetchSnapshot() -> AnyPublisher<InventorySnapshot, APIError> {
            Fail(error: .transport("offline")).eraseToAnyPublisher()
        }
    }

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Room.self, StorageContainer.self, Item.self, DeletedRecord.self])
        let container = try ModelContainer(for: schema,
                                           configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        return ModelContext(container)
    }

    private func snapshot(itemName: String = "Шуруповёрт") -> InventorySnapshot {
        InventorySnapshot(
            rooms: [RoomDTO(id: "room-1", name: "Кладовая", icon: "archivebox")],
            containers: [ContainerDTO(id: "cont-1", name: "Коробка «Инструменты»", code: "BOX-0001", roomID: "room-1")],
            items: [ItemDTO(id: "item-1", name: itemName, quantity: 1, typeID: "tools", containerID: "cont-1", note: nil),
                    ItemDTO(id: "item-2", name: "Рулетка 5 м", quantity: 1, typeID: "tools", containerID: "cont-1", note: "")]
        )
    }

    func testEmptyDatabaseIsFilledAndRepeatedSyncIsIdempotent() throws {
        let context = try makeContext()
        let sync = InventorySyncService(api: NoNetwork(), context: context)
        XCTAssertEqual(try sync.apply(snapshot()), SyncReport(inserted: 4, updated: 0))
        XCTAssertEqual(try sync.apply(snapshot()), SyncReport(inserted: 0, updated: 0))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Item>()), 2)
    }

    func testUserDataSurvivesServerUpdates() throws {
        let context = try makeContext()
        let repository = SwiftDataInventoryRepository(context: context)
        let sync = InventorySyncService(api: NoNetwork(), context: context)
        try sync.apply(snapshot())

        // Пользователь добавляет свою вещь в серверный контейнер и свою комнату
        let box = try XCTUnwrap(repository.container(code: "BOX-0001"))
        let own = try repository.addItem(name: "Уровень строительный", quantity: 1, typeID: "tools", note: "", to: box)
        let garage = try repository.addRoom(name: "Гараж", icon: "car")
        // Пользователь изменяет серверную вещь и удаляет другую
        let tape = try XCTUnwrap(repository.search("Рулетка").first)
        let drill = try XCTUnwrap(repository.search("Шуруповёрт").first)
        try repository.updateItem(drill, name: "Шуруповёрт Bosch", quantity: 2, typeID: "tools", note: "", container: box)
        try repository.deleteItem(tape)

        // Следующий старт: сервер прислал обновлённые данные
        let report = try sync.apply(snapshot(itemName: "Шуруповёрт Makita"))
        XCTAssertEqual(report.inserted, 0, "Удалённая пользователем вещь не восстанавливается")
        XCTAssertEqual(repository.item(id: own.id)?.container?.code, "BOX-0001")
        XCTAssertNotNil(repository.room(id: garage.id))
        XCTAssertEqual(repository.item(id: drill.id)?.name, "Шуруповёрт Bosch", "Правка пользователя сохраняется")
        XCTAssertTrue(repository.search("Рулетка").isEmpty)
    }

    func testUntouchedServerRecordsAreUpdated() throws {
        let context = try makeContext()
        let sync = InventorySyncService(api: NoNetwork(), context: context)
        try sync.apply(snapshot())
        let report = try sync.apply(snapshot(itemName: "Шуруповёрт Makita"))
        XCTAssertEqual(report.updated, 1)
        XCTAssertEqual(SwiftDataInventoryRepository(context: context).search("Makita").count, 1)
    }

    func testUserContainerCodeClashIsResolved() throws {
        let context = try makeContext()
        let repository = SwiftDataInventoryRepository(context: context)
        let room = try repository.addRoom(name: "Своя комната", icon: "house")
        let mine = try repository.addContainer(name: "Моя коробка", to: room)
        XCTAssertEqual(mine.code, "BOX-0001")
        try InventorySyncService(api: NoNetwork(), context: context).apply(snapshot())
        XCTAssertEqual(mine.code, "BOX-0002", "Код пользовательского контейнера сдвигается")
        XCTAssertEqual(repository.container(code: "BOX-0001")?.remoteID, "cont-1")
    }

    func testOfflineLaunchKeepsDataAndReportsError() throws {
        let context = try makeContext()
        let sync = InventorySyncService(api: NoNetwork(), context: context)
        try sync.apply(snapshot())
        let done = expectation(description: "offline")
        sync.syncOnLaunch()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if case .failed = sync.state { done.fulfill() }
        }
        wait(for: [done], timeout: 3)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<Item>()), 2)
    }
}

final class ExportTests: XCTestCase {
    func testJSONAndCSVExport() throws {
        let schema = Schema([Room.self, StorageContainer.self, Item.self, DeletedRecord.self])
        let modelContainer = try ModelContainer(for: schema,
                                                configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let repository = SwiftDataInventoryRepository(context: ModelContext(modelContainer))
        let room = try repository.addRoom(name: "Кладовая", icon: "archivebox")
        let box = try repository.addContainer(name: "Коробка «Инструменты»", to: room)
        try repository.addItem(name: "Шуруповёрт", quantity: 1, typeID: "tools", note: "в кейсе; с зарядкой", to: box)
        try repository.addItem(name: "Рулетка 5 м", quantity: 2, typeID: "tools", note: "", to: box)

        let exporter = ContainerExporter(catalog: try ItemTypeCatalog(),
                                         now: { Date(timeIntervalSince1970: 1_780_000_000) })
        let jsonURL = try exporter.writeFile(for: box, format: .json)
        XCTAssertEqual(jsonURL.lastPathComponent, "BOX-0001.inventory.json")
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(ContainerExport.self, from: Data(contentsOf: jsonURL))
        XCTAssertEqual(decoded.roomName, "Кладовая")
        XCTAssertEqual(decoded.items.map(\.name), ["Рулетка 5 м", "Шуруповёрт"])
        XCTAssertEqual(decoded.items.first?.category, "Инструменты")

        let csv = String(decoding: try exporter.data(for: box, format: .csv), as: UTF8.self)
        XCTAssertTrue(csv.hasPrefix("\u{FEFF}Код;Контейнер"))
        XCTAssertTrue(csv.contains("\"в кейсе; с зарядкой\""), "Поле с разделителем экранируется")
    }
}

final class DebouncedSearchTests: XCTestCase {
    func testOnlyLastQueryAfterPauseIsApplied() {
        let search = DebouncedSearch(delay: .milliseconds(200))
        var applied: [String] = []
        search.send("ш")
        search.send("шу")
        search.send("шуруп ")
        XCTAssertEqual(search.appliedQuery, "", "До паузы запрос не применяется")
        let done = expectation(description: "debounce")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            applied.append(search.appliedQuery)
            search.send("шуруп")                      // тот же запрос после обрезки пробелов
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                applied.append(search.appliedQuery)
                done.fulfill()
            }
        }
        wait(for: [done], timeout: 3)
        XCTAssertEqual(applied, ["шуруп", "шуруп"])
    }
}
