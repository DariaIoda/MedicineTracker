import Foundation
import SwiftData

protocol MedicineRepository: AnyObject {
    func medicines() -> [Medicine]
    func addMedicine(name: String, expiryDate: Date, form: String, quantity: Int, dosage: String, instructions: String) throws -> Medicine
    func deleteMedicine(_ medicine: Medicine) throws
}

final class SwiftDataMedicineRepository: MedicineRepository {
    let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func medicines() -> [Medicine] {
        let descriptor = FetchDescriptor<Medicine>(sortBy: [SortDescriptor(\.expiryDate)])
        return (try? context.fetch(descriptor)) ?? []
    }
    
    @discardableResult
    func addMedicine(name: String, expiryDate: Date, form: String, quantity: Int, dosage: String, instructions: String) throws -> Medicine {
        let medicine = Medicine(name: name, expiryDate: expiryDate, form: form, quantity: quantity, dosage: dosage, instructions: instructions)
        context.insert(medicine)
        try context.save()
        return medicine
    }
    
    func deleteMedicine(_ medicine: Medicine) throws {
        context.delete(medicine)
        try context.save()
    }
}