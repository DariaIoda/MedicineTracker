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

final class ScannerViewModelTests: XCTestCase {
    func testKnownContainerIsFound() {
        let viewModel = ScannerViewModel(repository: InMemoryInventoryRepository())
        viewModel.handle(scannedValue: "INVQR:1:BOX-0004")
        guard case .found(let location) = viewModel.state else {
            return XCTFail("Ожидался найденный контейнер")
        }
        XCTAssertEqual(location.room.name, "Кладовая")
        XCTAssertEqual(viewModel.foundItems.map(\.name), ["Набор отвёрток", "Рулетка 5 м", "Шуруповёрт"])
        XCTAssertTrue(viewModel.isFound)
    }

    func testUnknownAndForeignCodes() {
        let viewModel = ScannerViewModel(repository: InMemoryInventoryRepository())
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
        let repository = InMemoryInventoryRepository()
        let container = try XCTUnwrap(repository.container(code: "BOX-0005"))
        let viewModel = ContainerDetailViewModel(containerID: container.container.id,
                                                 repository: repository,
                                                 generator: CoreImageQRCodeGenerator())
        XCTAssertEqual(viewModel.roomName, "Кладовая")
        XCTAssertEqual(viewModel.positionsCount, 2)
        XCTAssertEqual(viewModel.totalQuantity, 26)
        XCTAssertEqual(viewModel.payload, "INVQR:1:BOX-0005")
        let first = try XCTUnwrap(viewModel.qrImage)
        XCTAssertTrue(first === viewModel.qrImage, "QR-код должен кэшироваться")
    }

    func testListViewModelSearchAndCounters() {
        let viewModel = InventoryListViewModel(repository: InMemoryInventoryRepository())
        XCTAssertEqual(viewModel.roomCount, 4)
        XCTAssertEqual(viewModel.containerCount, 6)
        XCTAssertEqual(viewModel.itemCount, 14)
        viewModel.searchText = "гирлянда"
        XCTAssertTrue(viewModel.isSearching)
        XCTAssertEqual(viewModel.searchResults.first?.path, "Кладовая → Коробка «Новый год»")
    }
}
