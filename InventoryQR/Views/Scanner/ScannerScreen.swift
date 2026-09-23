import SwiftUI

struct ScannerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ScannerViewModel
    let dependencies: AppDependencies
    
    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
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
                        Label("Критическая несовместимость", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    } description: {
                        Text("Препарат содержит **\(conflict.substanceA)**, что конфликтует с принимаемым **\(conflict.substanceB)**.\n\nУгроза: \(conflict.danger)")
                    } actions: {
                        Button("Сканировать снова") { viewModel.reset() }
                            .buttonStyle(.borderedProminent)
                    }
                case .safeToAdd(let name):
                    ContentUnavailableView {
                        Label("Препарат безопасен", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    } description: {
                        Text("Распознано: \(name)")
                    } actions: {
                        Button("Добавить в аптечку") { 
                            // Здесь можно открыть форму добавления с предзаполненным именем
                            dismiss() 
                        }
                        .buttonStyle(.borderedProminent)
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