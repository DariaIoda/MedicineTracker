import Foundation
import SwiftData

@Model
final class Medicine {
    @Attribute(.unique) var id: UUID
    var name: String
    var expiryDate: Date
    var form: String
    var quantity: Int
    var dosage: String
    var instructions: String
    
    init(id: UUID = UUID(), name: String, expiryDate: Date, form: String, quantity: Int, dosage: String, instructions: String) {
        self.id = id
        self.name = name
        self.expiryDate = expiryDate
        self.form = form
        self.quantity = quantity
        self.dosage = dosage
        self.instructions = instructions
    }
}