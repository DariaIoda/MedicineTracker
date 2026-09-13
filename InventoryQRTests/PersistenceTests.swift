import SwiftData
import XCTest
@testable import InventoryQR

final class ItemTypeCatalogTests: XCTestCase {
    func testBundledClassifierIsDecoded() throws {
        let catalog = try ItemTypeCatalog()
        XCTAssertEqual(catalog.version, 1)
        XCTAssertEqual(catalog.types.count, 14)
        XCTAssertEqual(catalog.type(id: "tools").category, "Инструменты")
        XCTAssertEqual(catalog.type(id: "tools").icon, "wrench.and.screwdriver")
        XCTAssertEqual(catalog.type(id: "unknown").id, "other", "Неизвестный тип → «Прочее»")
    }

    func testDuplicateIdentifiersAreRejected() {
        let json = #"{"version":1,"types":[{"id":"a","category":"A","icon":"x"},{"id":"a","category":"B","icon":"y"}]}"#
        XCTAssertThrowsError(try ItemTypeCatalog(data: Data(json.utf8))) { error in
            XCTAssertEqual(error as? ItemTypeCatalog.LoadError, .duplicateIdentifier("a"))
        }
    }
}

final class SwiftDataRepositoryTests: XCTestCase {
    private func makeContainer(url: URL? = nil) throws -> ModelContainer {
        let schema = Schema([Room.self, StorageContainer.self, Item.self])
        let configuration = url.map { ModelConfiguration(schema: schema, url: $0) }
            ?? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: configuration)
    }

    func testFullCrudCycle() throws {
        let container = try makeContainer()
        let repository = SwiftDataInventoryRepository(context: ModelContext(container))

        // Create
        let room = try repository.addRoom(name: "  Кладовая ", icon: "archivebox")
        let box = try repository.addContainer(name: "Коробка «Инструменты»", to: room)
        let drill = try repository.addItem(name: "Шуруповёрт", quantity: 1, typeID: "tools", note: "", to: box)
        XCTAssertEqual(room.name, "Кладовая")
        XCTAssertEqual(box.code, "BOX-0001")
        XCTAssertEqual(drill.path, "Кладовая → Коробка «Инструменты»")

        // Read
        XCTAssertEqual(repository.rooms().count, 1)
        XCTAssertEqual(repository.container(code: "box-0001")?.id, box.id)
        XCTAssertEqual(repository.search("шуруп").map(\.id), [drill.id])

        // Update (перемещение вещи в другой контейнер другой комнаты)
        let garage = try repository.addRoom(name: "Гараж", icon: "car")
        let shelf = try repository.addContainer(name: "Стеллаж", to: garage)
        XCTAssertEqual(shelf.code, "BOX-0002")
        try repository.updateItem(drill, name: "Шуруповёрт Bosch", quantity: 2, typeID: "tools",
                                  note: "в кейсе", container: shelf)
        XCTAssertEqual(repository.item(id: drill.id)?.path, "Гараж → Стеллаж")
        XCTAssertTrue(box.items.isEmpty)
        try repository.updateContainer(shelf, name: "Стеллаж у стены", room: room)
        XCTAssertEqual(shelf.room?.name, "Кладовая")

        // Delete (каскадно)
        try repository.deleteRoom(room)
        XCTAssertNil(repository.item(id: drill.id), "Вещь удаляется вместе с комнатой")
        XCTAssertEqual(repository.rooms().map(\.name), ["Гараж"])
    }

    func testValidation() throws {
        let container = try makeContainer()
        let repository = SwiftDataInventoryRepository(context: ModelContext(container))
        XCTAssertThrowsError(try repository.addRoom(name: "   ", icon: "house")) {
            XCTAssertEqual($0 as? InventoryError, .emptyName)
        }
        let room = try repository.addRoom(name: "Кухня", icon: "fork.knife")
        let box = try repository.addContainer(name: "Шкаф", to: room)
        XCTAssertThrowsError(try repository.addItem(name: "Чашка", quantity: 0, typeID: "dishes", note: "", to: box)) {
            XCTAssertEqual($0 as? InventoryError, .invalidQuantity)
        }
    }

    func testDataSurvivesStoreReopening() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("inventory-\(UUID()).store")
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            let container = try makeContainer(url: url)
            let repository = SwiftDataInventoryRepository(context: ModelContext(container))
            let room = try repository.addRoom(name: "Гостиная", icon: "sofa")
            let box = try repository.addContainer(name: "Тумба", to: room)
            try repository.addItem(name: "HDMI-кабель", quantity: 3, typeID: "electronics", note: "", to: box)
        }

        let reopened = try makeContainer(url: url)
        let repository = SwiftDataInventoryRepository(context: ModelContext(reopened))
        let item = try XCTUnwrap(repository.search("HDMI").first)
        XCTAssertEqual(item.quantity, 3)
        XCTAssertEqual(item.path, "Гостиная → Тумба")
    }
}

final class ScannerWithDatabaseTests: XCTestCase {
    func testScanFindsContainerInDatabase() throws {
        let schema = Schema([Room.self, StorageContainer.self, Item.self])
        let container = try ModelContainer(for: schema,
                                           configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        SampleInventory.insert(into: context)
        let viewModel = ScannerViewModel(repository: SwiftDataInventoryRepository(context: context))
        viewModel.handle(scannedValue: "INVQR:1:BOX-0004")
        XCTAssertTrue(viewModel.isFound)
        XCTAssertEqual(viewModel.foundItems.map(\.name), ["Набор отвёрток", "Рулетка 5 м", "Шуруповёрт"])
        viewModel.handle(scannedValue: "INVQR:1:BOX-9999")
        XCTAssertEqual(viewModel.state, .unknownContainer(code: "BOX-9999"))
    }
}
