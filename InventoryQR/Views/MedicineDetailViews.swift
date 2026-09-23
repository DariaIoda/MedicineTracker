import SwiftUI

struct MedicineDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let medicine: Medicine
    let repository: MedicineRepository
    
    var body: some View {
        List {
            Section("Сведения о препарате") {
                LabeledContent("Название", value: medicine.name)
                LabeledContent("Форма выпуска", value: medicine.form)
                LabeledContent("Остаток", value: "\(medicine.quantity)")
                LabeledContent("Дозировка", value: medicine.dosage)
                LabeledContent("Срок годности", value: medicine.expiryDate.formatted(date: .long, time: .omitted))
            }
            
            Section("Правила приема и инструкция") {
                Text(medicine.instructions).font(.body)
            }
            
            Section {
                Button("Удалить препарат", role: .destructive) {
                    try? repository.deleteMedicine(medicine)
                    dismiss()
                }
            }
        }
        .navigationTitle("Детали")
        .navigationBarTitleDisplayMode(.inline)
    }
}