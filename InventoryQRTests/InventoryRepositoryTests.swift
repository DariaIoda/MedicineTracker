import XCTest
@testable import InventoryQR

final class InventoryRepositoryTests: XCTestCase {
    func testSearchReturnsExactLocation() {
        let repository = InMemoryInventoryRepository()
        let results = repository.search("шуруп")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.item.name, "Шуруповёрт")
        XCTAssertEqual(results.first?.path, "Кладовая → Коробка «Инструменты»")
    }

    func testSearchIsCaseInsensitiveAndMatchesCategory() {
        XCTAssertEqual(InMemoryInventoryRepository().search("ИНСТРУМЕНТЫ").count, 3)
    }

    func testEmptyQueryReturnsNothing() {
        XCTAssertTrue(InMemoryInventoryRepository().search("   ").isEmpty)
    }

    func testLookupByIdentifiersAndCode() throws {
        let repository = InMemoryInventoryRepository()
        let room = try XCTUnwrap(repository.rooms.first)
        let container = try XCTUnwrap(room.containers.first)
        let item = try XCTUnwrap(container.items.first)
        XCTAssertEqual(repository.room(id: room.id)?.name, room.name)
        XCTAssertEqual(repository.container(id: container.id)?.room.id, room.id)
        XCTAssertEqual(repository.container(code: "box-0001")?.container.id, container.id)
        XCTAssertEqual(repository.location(ofItem: item.id)?.container.id, container.id)
        XCTAssertNil(repository.container(code: "BOX-9999"))
    }
}
