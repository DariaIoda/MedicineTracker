import SwiftData
import XCTest
@testable import InventoryQR

final class QRPayloadTests: XCTestCase {
    func testFormatAndParseRoundTrip() {
        let payload = QRPayload(containerCode: "BOX-0004")
        XCTAssertEqual(payload.stringValue, "INVQR:1:BOX-0004")
        XCTAssertEqual(QRPayload.parse(payload.stringValue), payload)
    }

    func testForeignCodesAreRejected() {
        XCTAssertNil(QRPayload.parse("https://www.gstu.by"))
        XCTAssertNil(QRPayload.parse("INVQR:2:BOX-0001"))
        XCTAssertNil(QRPayload.parse("INVQR:1:"))
        XCTAssertNil(QRPayload.parse(""))
    }
}

final class QRGenerationTests: XCTestCase {
    func testGeneratedImageIsDecodedBack() throws {
        let generator = CoreImageQRCodeGenerator()
        let image = try XCTUnwrap(generator.makeImage(for: "INVQR:1:BOX-0005", side: 400))
        XCTAssertGreaterThanOrEqual(image.size.width, 300)
        XCTAssertEqual(VisionQRCodeDecoder().decode(image), "INVQR:1:BOX-0005")
    }

    func testMockLabelPhotosAreDecodable() throws {
        let expected = [
            "label_box_0001": "INVQR:1:BOX-0001",
            "label_box_0004": "INVQR:1:BOX-0004",
            "label_box_0005": "INVQR:1:BOX-0005",
            "label_box_9999": "INVQR:1:BOX-9999",
            "label_foreign": "https://www.gstu.by"
        ]
        for (name, value) in expected {
            let image = try XCTUnwrap(MockScannerView.loadImage(named: name), name)
            XCTAssertEqual(VisionQRCodeDecoder().decode(image), value, name)
        }
    }
}

/// Репозиторий SwiftData в памяти с тестовым набором данных.
private func makeSampleRepository() throws -> SwiftDataInventoryRepository {
    let schema = Schema([Room.self, StorageContainer.self, Item.self])
    let container = try ModelContainer(for: schema,
                                       configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
    let context = ModelContext(container)
    SampleInventory.insert(into: context)
    return SwiftDataInventoryRepository(context: context)
}

final class ScannerViewModelTests: XCTestCase {
    func testUnknownAndForeignCodes() throws {
        let viewModel = ScannerViewModel(repository: try makeSampleRepository())
        viewModel.handle(scannedValue: "INVQR:1:BOX-9999")
        XCTAssertEqual(viewModel.state, .unknownContainer(code: "BOX-9999"))
        viewModel.handle(scannedValue: "https://www.gstu.by")
        XCTAssertEqual(viewModel.state, .foreignCode("https://www.gstu.by"))
        viewModel.reset()
        XCTAssertEqual(viewModel.state, .scanning)
    }
}

final class ContainerDetailViewModelTests: XCTestCase {
    func testContainerCardData() throws {
        let repository = try makeSampleRepository()
        let container = try XCTUnwrap(repository.container(code: "BOX-0005"))
        let viewModel = ContainerDetailViewModel(containerID: container.id,
                                                 repository: repository,
                                                 generator: CoreImageQRCodeGenerator())
        XCTAssertEqual(viewModel.roomName, "Кладовая")
        XCTAssertEqual(viewModel.positionsCount, 2)
        XCTAssertEqual(viewModel.totalQuantity, 26)
        XCTAssertEqual(viewModel.payload, "INVQR:1:BOX-0005")
        let first = try XCTUnwrap(viewModel.qrImage)
        XCTAssertTrue(first === viewModel.qrImage, "QR-код должен кэшироваться")
    }

    func testListViewModelSearchUsesClassifier() throws {
        let repository = try makeSampleRepository()
        let viewModel = InventoryListViewModel(repository: repository, catalog: try ItemTypeCatalog())
        viewModel.searchText = "гирлянда"
        XCTAssertTrue(viewModel.isSearching)
        XCTAssertEqual(viewModel.searchResults(in: repository.rooms()).first?.path, "Кладовая → Коробка «Новый год»")
        viewModel.searchText = "инструмент"            // совпадение по категории из item_types.json
        XCTAssertEqual(viewModel.searchResults(in: repository.rooms()).count, 3)
    }

    func testItemFormCreatesItemInChosenContainer() throws {
        let repository = try makeSampleRepository()
        let box = try XCTUnwrap(repository.container(code: "BOX-0004"))
        let form = ItemFormViewModel(repository: repository, catalog: try ItemTypeCatalog(), container: box)
        XCTAssertFalse(form.canSave)
        form.name = "Уровень строительный"
        form.typeID = "tools"
        form.quantity = 2
        XCTAssertTrue(form.save())
        XCTAssertEqual(box.items.count, 4)
        XCTAssertEqual(repository.search("уровень").first?.path, "Кладовая → Коробка «Инструменты»")
    }
}
