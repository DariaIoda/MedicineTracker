import SwiftUI

/// Экспорт списка вещей коробки: выбор формата, предпросмотр и передача файла через системное меню «Поделиться».
struct ExportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ExportViewModel

    init(viewModel: ExportViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            List {
                Section {
                    Picker("Формат", selection: $viewModel.format) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.title).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("exportFormat")
                } footer: {
                    Text("Файл можно отправить другому пользователю через AirDrop, почту, мессенджер или сохранить в «Файлы».")
                }

                if let url = viewModel.fileURL {
                    Section("Файл") {
                        LabeledContent("Имя", value: url.lastPathComponent)
                        LabeledContent("Размер", value: viewModel.fileSizeText)
                        LabeledContent("Вещей", value: "\(viewModel.itemCount)")
                        ShareLink(item: url) {
                            Label("Поделиться файлом", systemImage: "square.and.arrow.up")
                        }
                        .accessibilityIdentifier("shareExport")
                    }
                    Section("Предпросмотр") {
                        Text(viewModel.previewText)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                            .accessibilityIdentifier("exportPreview")
                    }
                }

                if let error = viewModel.errorMessage {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Экспорт \(viewModel.containerCode)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
            .onAppear { viewModel.prepare() }
            .onChange(of: viewModel.format) { viewModel.prepare() }
        }
    }
}
