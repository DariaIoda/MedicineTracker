import SwiftUI

/// Экран комнаты: список контейнеров с добавлением, изменением и удалением.
struct RoomView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RoomViewModel

    init(viewModel: RoomViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        if let room = viewModel.room {
            List {
                Section("Контейнеры") {
                    if room.containers.isEmpty {
                        Text("В комнате пока нет контейнеров").foregroundStyle(.secondary)
                    }
                    ForEach(room.sortedContainers) { container in
                        NavigationLink(value: Route.container(container.id)) {
                            ContainerRow(container: container)
                        }
                        .swipeActions {
                            Button(role: .destructive) { viewModel.delete(container) } label: {
                                Label("Удалить", systemImage: "trash")
                            }
                        }
                    }
                    Button {
                        viewModel.editor = .newContainer(room: room)
                    } label: {
                        Label("Добавить контейнер", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle(room.name)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button { viewModel.editor = .editRoom(room) } label: {
                            Label("Изменить комнату", systemImage: "pencil")
                        }
                        Button(role: .destructive) { viewModel.confirmDelete = true } label: {
                            Label("Удалить комнату", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityIdentifier("roomMenu")
                }
            }
            .sheet(item: $viewModel.editor) { EditorSheet(request: $0) }
            .confirmationDialog("Удалить комнату «\(room.name)» вместе со всеми контейнерами и вещами?",
                                isPresented: $viewModel.confirmDelete, titleVisibility: .visible) {
                Button("Удалить", role: .destructive) {
                    if viewModel.deleteRoom() { dismiss() }
                }
            }
        } else {
            ContentUnavailableView("Комната не найдена", systemImage: "house.slash")
        }
    }
}

/// Экран вещи с местоположением.
struct ItemDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ItemDetailViewModel

    init(viewModel: ItemDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        if let item = viewModel.item {
            let type = viewModel.type
            List {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: type.icon)
                            .font(.system(size: 56))
                            .foregroundStyle(.blue)
                        Text(item.name)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                Section("Сведения") {
                    LabeledContent("Тип имущества", value: type.category)
                    LabeledContent("Количество", value: "\(item.quantity)")
                    if !item.note.isEmpty {
                        LabeledContent("Заметка", value: item.note)
                    }
                }
                if let container = item.container {
                    Section("Местоположение") {
                        Label(container.room?.name ?? "—", systemImage: container.room?.icon ?? "house")
                        NavigationLink(value: Route.container(container.id)) {
                            Label(container.name, systemImage: "shippingbox")
                        }
                    }
                }
                Section {
                    Button(role: .destructive) {
                        if viewModel.delete() { dismiss() }
                    } label: {
                        Label("Удалить вещь", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Вещь")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Изменить") { viewModel.editor = .editItem(item) }
                        .accessibilityIdentifier("editItem")
                }
            }
            .sheet(item: $viewModel.editor) { EditorSheet(request: $0) }
        } else {
            ContentUnavailableView("Вещь не найдена", systemImage: "cube")
        }
    }
}
