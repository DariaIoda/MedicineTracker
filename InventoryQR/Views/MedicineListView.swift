import SwiftData
import SwiftUI

/// Главный экран получает данные из базы обёрткой свойства @Query. При изменении данных SwiftData автоматически обновляет список[cite: 5].
struct MedicineListView: View {
    @Query(sort: \Medicine.expiryDate, order: .forward) private var medicines: [Medicine]
    @State private var selectedForm: String = "Все"
    @State private var isScannerPresented = false
    
    let forms = ["Все", "Таблетки", "Сиропы", "Капли", "Ампулы"]
    
    var filteredMedicines: [Medicine] {
        if selectedForm == "Все" {
            return medicines
        } else {
            return medicines.filter { $0.form == selectedForm }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Форма выпуска", selection: $selectedForm) {
                    ForEach(forms, id: \.self) { form in
                        Text(form).tag(form)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                List {
                    if filteredMedicines.isEmpty {
                        ContentUnavailableView("Аптечка пуста", systemImage: "cross.case")
                    } else {
                        ForEach(filteredMedicines) { medicine in
                            NavigationLink(destination: MedicineDetailView(medicine: medicine)) {
                                MedicineRow(medicine: medicine)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Моя Аптечка")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isScannerPresented = true
                    } label: {
                        Label("Сканировать", systemImage: "text.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $isScannerPresented) {
                // Подключение View для сканирования и передачи названия во ViewModel
                Text("Экран сканирования (заглушка)")
            }
        }
    }
}

struct MedicineRow: View {
    let medicine: Medicine
    var isCritical: Bool {
        medicine.expiryDate < Date().addingTimeInterval(30 * 24 * 60 * 60) // Менее 30 дней
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(medicine.name)
                    .font(.headline)
                Text(medicine.form)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("Остаток: \(medicine.quantity)")
                    .font(.subheadline)
                Text(medicine.expiryDate.formatted(date: .numeric, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(isCritical ? .red : .secondary)
            }
        }
    }
}