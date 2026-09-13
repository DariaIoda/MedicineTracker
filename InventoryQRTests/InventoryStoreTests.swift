import XCTest
@testable import InventoryQR

final class InventoryStoreTests: XCTestCase {
    func testCountsMatchSampleData() {
        let store = InventoryStore()
        XCTAssertEqual(store.rooms.count, 4)
        XCTAssertEqual(store.containerCount, 6)
        XCTAssertEqual(store.itemCount, 14)
    }

    func testSearchReturnsExactLocation() {
        let store = InventoryStore()
        let results = store.search("шуруп")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.item.name, "Шуруповёрт")
        XCTAssertEqual(results.first?.path, "Кладовая → Коробка «Инструменты»")
    }

    func testSearchIsCaseInsensitiveAndMatchesCategory() {
        let store = InventoryStore()
        XCTAssertEqual(store.search("ИНСТРУМЕНТЫ").count, 3)
    }

    func testEmptyQueryReturnsNothing() {
        let store = InventoryStore()
        XCTAssertTrue(store.search("   ").isEmpty)
    }

    func testLookupByIdentifiers() throws {
        let store = InventoryStore()
        let room = try XCTUnwrap(store.rooms.first)
        let container = try XCTUnwrap(room.containers.first)
        let item = try XCTUnwrap(container.items.first)
        XCTAssertEqual(store.room(id: room.id)?.name, room.name)
        XCTAssertEqual(store.container(id: container.id)?.room.id, room.id)
        XCTAssertEqual(store.location(ofItem: item.id)?.container.id, container.id)
    }
}
