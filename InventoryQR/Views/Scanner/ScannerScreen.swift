import SwiftUI

/// Экран автоматизированного поиска: сканирование QR-кода и вывод содержимого коробки.
struct ScannerScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ScannerViewModel

    private let dependencies: AppDependencies
    private let onOpenContainer: (UUID) -> Void

    init(dependencies: AppDependencies, onOpenContainer: @escaping (UUID) -> Void) {
        self.dependencies = dependencies
        self.onOpenContainer = onOpenContainer
        _viewModel = State(initialValue: ScannerViewModel(repository: dependencies.repository))
    }

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .scanning:
                    scanner
                case .found:
                    if let container = viewModel.foundContainer {
                        foundView(container)
                    }
                case .unknownContainer(let code):
                    messageView(title: "Контейнер не найден",
                                text: "Код \(code) не зарегистрирован в инвентаре.",
                                icon: "shippingbox.and.arrow.backward")
                case .foreignCode(let raw):
                    messageView(title: "Это не метка инвентаря",
                                text: "Считано: \(raw)",
                                icon: "qrcode")
                }
            }
            .navigationTitle("Сканирование QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
                if viewModel.isFound {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Сканировать снова") { viewModel.reset() }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var scanner: some View {
        if dependencies.usesMockScanner {
            MockScannerView(decoder: dependencies.qrDecoder) { viewModel.handle(scannedValue: $0) }
        } else {
            ZStack(alignment: .bottom) {
                CameraScannerView { viewModel.handle(scannedValue: $0) }
                    .ignoresSafeArea()
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white, lineWidth: 4)
                    .frame(width: 260, height: 260)
                    .frame(maxHeight: .infinity)
                Text("Наведите камеру на QR-код коробки")
                    .padding()
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(.bottom, 40)
            }
        }
    }

    private func foundView(_ container: StorageContainer) -> some View {
        List {
            Section {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(container.name).font(.headline)
                        Text("\(container.room?.name ?? "—") · \(container.code)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                }
            } header: {
                Text("Код распознан")
            }
            Section("Вещи в коробке: \(viewModel.foundItems.count)") {
                ForEach(viewModel.foundItems) { item in
                    ItemRow(item: item, type: dependencies.catalog.type(id: item.typeID))
                }
            }
            Section {
                Button {
                    dismiss()
                    onOpenContainer(container.id)
                } label: {
                    Label("Открыть карточку контейнера", systemImage: "list.bullet.rectangle")
                }
            }
        }
    }

    private func messageView(title: String, text: String, icon: String) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(text)
        } actions: {
            Button("Сканировать снова") { viewModel.reset() }
                .buttonStyle(.borderedProminent)
        }
    }
}
