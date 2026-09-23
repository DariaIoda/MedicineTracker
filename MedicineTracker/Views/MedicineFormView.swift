import SwiftUI

struct MedicineFormView: View {
    @Environment(\.dismiss) private var dismiss
    let repository: MedicineRepository
    
    @State private var name = ""
    @State private var form = "Таблетки"
    @State private var quantity = 1
    @State private var dosage = ""
    @State private var instructions = ""
    @State private var expiryDate = Date()
    
    let forms = ["Таблетки", "Сиропы", "Капли", "Ампулы", "Мази"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Основное") {
                    TextField("Название препарата", text: $name)
                    Picker("Форма выпуска", selection: $form) {
                        ForEach(forms, id: \.self) { Text($0).tag($0) }
                    }
                    Stepper("Количество: \(quantity)", value: $quantity, in: 1...1000)
                    DatePicker("Годен до", selection: $expiryDate, displayedComponents: .date)
                }
                Section("Инструкция") {
                    TextField("Дозировка (напр. 500 мг)", text: $dosage)
                    TextField("Правила приема", text: $instructions, axis: .vertical).lineLimit(3...6)
                }
            }
            .navigationTitle("Новое лекарство")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") {
                        try? repository.addMedicine(name: name, expiryDate: expiryDate, form: form, quantity: quantity, dosage: dosage, instructions: instructions)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
        }
    }
}