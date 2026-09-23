import SwiftUI

struct MedicineDetailView: View {
    let medicine: Medicine
    
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
                Text(medicine.instructions)
                    .font(.body)
            }
        }
        .navigationTitle("Детали")
        .navigationBarTitleDisplayMode(.inline)
    }
}