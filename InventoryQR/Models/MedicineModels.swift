import Foundation
import SwiftData

/// Модель медикамента для базы данных.
/// Классы предметной области отмечены макросом @Model, который делает их сохраняемыми и наблюдаемыми[cite: 5].
@Model
final class Medicine {
    @Attribute(.unique) var id: UUID
    var name: String
    var expiryDate: Date
    var form: String
    var quantity: Int
    var dosage: String
    var instructions: String
    var remoteID: String?
    
    init(id: UUID = UUID(), name: String, expiryDate: Date, form: String, quantity: Int, dosage: String, instructions: String, remoteID: String? = nil) {
        self.id = id
        self.name = name
        self.expiryDate = expiryDate
        self.form = form
        self.quantity = quantity
        self.dosage = dosage
        self.instructions = instructions
        self.remoteID = remoteID
    }
}