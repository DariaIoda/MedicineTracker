import SwiftData
import SwiftUI

struct MedicineListView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Query(sort: \Medicine.expiryDate, order: .forward) private var medicines: [Medicine]
    
    @State private var selectedForm: String = "Все"
    @State private var isScannerPresented = false
    @State private var isAddFormPresented = false
    
    let forms = ["Все", "Таблетки", "Сиропы", "Капли", "Ампулы", "Мази"]
    
    var filteredMedicines: [Medicine] {
        selectedForm == "Все" ? medicines : medicines.filter { $0.form == selectedForm }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Форма выпуска", selection: $selectedForm) {
                    ForEach(forms, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()
                
                List {
                    if filteredMedicines.isEmpty {
                        ContentUnavailableView("Аптечка пуста", systemImage: "cross.case")
                    } else {
                        ForEach(filteredMedicines) { medicine in
                            NavigationLink(destination: MedicineDetailView(medicine: medicine, repository: dependencies.repository)) {
                                MedicineRow(medicine: medicine)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Моя Аптечка")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { isAddFormPresented = true }) { Label("Добавить", systemImage: "plus") }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isScannerPresented = true }) { Label("Сканировать", systemImage: "text.viewfinder") }
                }
            }
            .sheet(isPresented: $isScannerPresented) {
                ScannerScreen(dependencies: dependencies, isAddFormPresented: $isAddFormPresented)
            }
            .sheet(isPresented: $isAddFormPresented) {
                MedicineFormView(repository: dependencies.repository)
            }
        }
    }
}

struct MedicineRow: View {
    let medicine: Medicine
    var isCritical: Bool { medicine.expiryDate < Date().addingTimeInterval(30 * 24 * 60 * 60) }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(medicine.name).font(.headline)
                Text(medicine.form).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing) {
                Text("Остаток: \(medicine.quantity)").font(.subheadline)
                Text(medicine.expiryDate.formatted(date: .numeric, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(isCritical ? .red : .secondary)
            }
        }
    }
}