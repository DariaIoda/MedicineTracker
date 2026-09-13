import SwiftUI
import UIKit

/// Карточка контейнера: перечень материальных ценностей, QR-код маркировки и управление содержимым.
struct ContainerCardView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: ContainerDetailViewModel
    @State private var isQRFullScreen = false
    @State private var editor: EditorRequest?

    init(viewModel: ContainerDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        if let container = viewModel.container {
            List {
                Section {
                    qrBlock
                }
                Section("Сведения") {
                    LabeledContent("Комната", value: viewModel.roomName)
                    LabeledContent("Код маркировки", value: viewModel.code)
                    LabeledContent("Позиций", value: "\(viewModel.positionsCount)")
                    LabeledContent("Всего предметов", value: "\(viewModel.totalQuantity)")
                }
                Section("Содержимое") {
                    if viewModel.items.isEmpty {
                        Text("Контейнер пуст").foregroundStyle(.secondary)
                    }
                    ForEach(viewModel.items) { item in
                        NavigationLink(value: Route.item(item.id)) {
                            ItemRow(item: item, type: dependencies.catalog.type(id: item.typeID))
                        }
                        .swipeActions {
                            Button(role: .destructive) { viewModel.delete(item) } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        }
                    }
                    Button {
                        editor = .newItem(container: container)
                    } label: {
                        Label("Добавить вещь", systemImage: "plus.circle")
                    }
                    .accessibilityIdentifier("addItemToContainer")
                }
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Изменить") { editor = .editContainer(container) }
                        .accessibilityIdentifier("editContainer")
                }
            }
            .sheet(isPresented: $isQRFullScreen) {
                QRFullScreenView(image: viewModel.qrImage, title: viewModel.title, code: viewModel.code)
            }
            .sheet(item: $editor) { EditorSheet(request: $0) }
        } else {
            ContentUnavailableView("Контейнер не найден", systemImage: "shippingbox")
        }
    }

    private var qrBlock: some View {
        VStack(spacing: 10) {
            if let image = viewModel.qrImage {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 220, maxHeight: 220)
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityIdentifier("containerQR")
                    .onTapGesture { isQRFullScreen = true }
            }
            Text(viewModel.payload)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

/// Полноэкранный показ QR-кода маркировки.
struct QRFullScreenView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage?
    let title: String
    let code: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                if let image {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .padding(24)
                        .background(.white, in: RoundedRectangle(cornerRadius: 20))
                        .padding(.horizontal, 32)
                }
                Text(title).font(.title2.weight(.semibold))
                Text(code).font(.title3.monospaced()).foregroundStyle(.secondary)
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }
    }
}
