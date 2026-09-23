import SwiftUI

struct ScannerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ScannerViewModel
    let dependencies: AppDependencies
    @Binding var isAddFormPresented: Bool
    
    init(dependencies: AppDependencies, isAddFormPresented: Binding<Bool>) {
        self.dependencies = dependencies
        self._isAddFormPresented = isAddFormPresented
        _viewModel = State(initialValue: ScannerViewModel(repository: dependencies.repository, catalog: dependencies.catalog))
    }
    
    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .scanning:
                    MockScannerView(decoder: dependencies.textDecoder) { viewModel.handle(scannedValue: $0) }
                case .conflictFound(let conflict):
                    ContentUnavailableView {
                        Label("Критическая несовместимость", systemImage: "exclamationmark.triangle.fill").foregroundStyle(.red)
                    } description: {
                        Text("Препарат **\(conflict.substanceA)** конфликтует с **\(conflict.substanceB)**.\nУгроза: \(conflict.danger)")
                    } actions: {
                        Button("Сканировать снова") { viewModel.reset() }.buttonStyle(.borderedProminent)
                    }
                case .safeToAdd(let name):
                    ContentUnavailableView {
                        Label("Препарат безопасен", systemImage: "checkmark.seal.fill").foregroundStyle(.green)
                    } description: {
                        Text("Распознано: \(name)")
                    } actions: {
                        Button("Добавить в аптечку") {
                            dismiss()
                            isAddFormPresented = true
                        }.buttonStyle(.borderedProminent)
                    }
                case .noTextFound:
                    ContentUnavailableView {
                        Label("Текст не найден", systemImage: "text.magnifyingglass").foregroundStyle(.orange)
                    } description: {
                        Text("Не удалось распознать название на изображении.")
                    } actions: {
                        Button("Сканировать снова") { viewModel.reset() }.buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Сканирование упаковки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}