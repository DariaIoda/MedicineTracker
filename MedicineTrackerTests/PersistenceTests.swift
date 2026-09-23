import XCTest
import SwiftData
@testable import MedicineTracker 

final class PersistenceTests: XCTestCase {
    var context: ModelContext!
    var repository: SwiftDataMedicineRepository!

    @MainActor
    override func setUpWithError() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Medicine.self, configurations: config)
        context = container.mainContext
        repository = SwiftDataMedicineRepository(context: context)
    }

    override func tearDownWithError() throws {
        context = nil
        repository = nil
    }

    func testAddMedicine() throws {
        let medicine = try repository.addMedicine(
            name: "Аспирин", expiryDate: Date(), form: "Таблетки", quantity: 10, dosage: "500 мг", instructions: ""
        )
        let allMedicines = repository.medicines()
        XCTAssertEqual(allMedicines.count, 1)
        XCTAssertEqual(allMedicines.first?.name, "Аспирин")
    }
    
    func testDeleteMedicine() throws {
        let medicine = try repository.addMedicine(
            name: "Нурофен", expiryDate: Date(), form: "Сиропы", quantity: 1, dosage: "10 мл", instructions: ""
        )
        try repository.deleteMedicine(medicine)
        XCTAssertTrue(repository.medicines().isEmpty)
    }

    func testInteractionCatalogConflictDetected() throws {
        let json = """
        {
          "version": 1,
          "interactions": [
            { "id": "1", "substanceA": "Аспирин", "substanceB": "Ибупрофен", "danger": "Риск" }
          ]
        }
        """.data(using: .utf8)!

        let catalog = try InteractionCatalog(data: json)
        let conflict = catalog.checkConflict(scannedName: "Аспирин", currentMedicines: ["Ибупрофен"])
        XCTAssertNotNil(conflict)
    }
}