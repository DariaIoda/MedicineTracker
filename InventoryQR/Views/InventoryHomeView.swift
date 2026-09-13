import SwiftData
import SwiftUI

/// Главный экран: иерархия хранения из SwiftData, поиск и управление записями.
struct InventoryHomeView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Query(sort: \Room.name) private var rooms: [Room]
    @State private var viewModel: InventoryListViewModel
    let onOpenContainer: (UUID) -> Void

    init(viewModel: InventoryListViewModel, onOpenContainer: @escaping (UUID) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenContainer = onOpenContainer
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        List {
            if viewModel.isSearching {
                searchResults
            } else if rooms.isEmpty {
                emptyState
            } else {
                summarySection
                ForEach(rooms) { room in
                    roomSection(room)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Инвентарь")
        .searchable(text: $viewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Поиск вещи")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                addMenu
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.isScannerPresented = true
                } label: {
                    Label("Сканировать QR", systemImage: "qrcode.viewfinder")
                }
                .accessibilityIdentifier("scanButton")
            }
        }
        .sheet(isPresented: $viewModel.isScannerPresented) {
            ScannerScreen(dependencies: dependencies, onOpenContainer: onOpenContainer)
        }
        .sheet(item: $viewModel.editor) { request in
            EditorSheet(request: request)
        }
        .alert("Ошибка", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var addMenu: some View {
        Menu {
            Button { viewModel.editor = .newRoom } label: {
                Label("Комната", systemImage: "house")
            }
            Button { viewModel.editor = .newContainer(room: nil) } label: {
                Label("Контейнер", systemImage: "shippingbox")
            }
            .disabled(rooms.isEmpty)
            Button { viewModel.editor = .newItem(container: nil) } label: {
                Label("Вещь", systemImage: "cube")
            }
            .disabled(rooms.allSatisfy { $0.containers.isEmpty })
        } label: {
            Label("Добавить", systemImage: "plus")
        }
        .accessibilityIdentifier("addMenu")
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Инвентарь пуст", systemImage: "shippingbox")
        } description: {
            Text("Добавьте комнату, затем контейнеры и вещи в них.")
        } actions: {
            Button("Добавить комнату") { viewModel.editor = .newRoom }
                .buttonStyle(.borderedProminent)
        }
        .listRowBackground(Color.clear)
    }

    private var summarySection: some View {
        let containers = rooms.flatMap(\.containers)
        return Section {
            HStack(spacing: 12) {
                StatBadge(value: rooms.count, title: "комнат", icon: "house")
                StatBadge(value: containers.count, title: "контейнеров", icon: "shippingbox")
                StatBadge(value: containers.reduce(0) { $0 + $1.items.count }, title: "вещей", icon: "cube")
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        }
    }

    private func roomSection(_ room: Room) -> some View {
        Section {
            NavigationLink(value: Route.room(room.id)) {
                Label("Открыть комнату", systemImage: "arrow.right.circle")
                    .foregroundStyle(.tint)
            }
            .accessibilityIdentifier("openRoom_\(room.name)")
            ForEach(room.sortedContainers) { container in
                containerGroup(container)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) { viewModel.delete(container) } label: {
                            Label("Удалить", systemImage: "trash")
                        }
                        Button { viewModel.editor = .editContainer(container) } label: {
                            Label("Изменить", systemImage: "pencil")
                        }
                        .tint(.orange)
                    }
            }
        } header: {
            RoomHeader(room: room)
                .contextMenu {
                    Button { viewModel.editor = .editRoom(room) } label: {
                        Label("Изменить комнату", systemImage: "pencil")
                    }
                    Button(role: .destructive) { viewModel.delete(room) } label: {
                        Label("Удалить комнату", systemImage: "trash")
                    }
                }
        }
    }

    private func containerGroup(_ container: StorageContainer) -> some View {
        DisclosureGroup(isExpanded: Binding(
            get: { viewModel.isExpanded(container.id) },
            set: { viewModel.setExpanded(container.id, $0) }
        )) {
            ForEach(container.sortedItems) { item in
                NavigationLink(value: Route.item(item.id)) {
                    ItemRow(item: item, type: dependencies.catalog.type(id: item.typeID))
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) { viewModel.delete(item) } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                    Button { viewModel.editor = .editItem(item) } label: {
                        Label("Изменить", systemImage: "pencil")
                    }
                    .tint(.orange)
                }
            }
            Button {
                viewModel.editor = .newItem(container: container)
            } label: {
                Label("Добавить вещь", systemImage: "plus.circle")
                    .font(.subheadline)
            }
            NavigationLink(value: Route.container(container.id)) {
                Label("Карточка контейнера", systemImage: "list.bullet.rectangle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } label: {
            ContainerRow(container: container)
        }
    }

    @ViewBuilder
    private var searchResults: some View {
        let results = viewModel.searchResults(in: rooms)
        if results.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            Section("Найдено: \(results.count)") {
                ForEach(results) { item in
                    NavigationLink(value: Route.item(item.id)) {
                        SearchResultRow(item: item, type: dependencies.catalog.type(id: item.typeID),
                                        query: viewModel.searchText)
                    }
                }
            }
        }
    }
}

/// Лист с нужной формой редактирования.
struct EditorSheet: View {
    @Environment(AppDependencies.self) private var dependencies
    let request: EditorRequest

    var body: some View {
        switch request {
        case .newRoom:
            RoomFormView(viewModel: RoomFormViewModel(repository: dependencies.repository))
        case .editRoom(let room):
            RoomFormView(viewModel: RoomFormViewModel(repository: dependencies.repository, room: room))
        case .newContainer(let room):
            ContainerFormView(viewModel: ContainerFormViewModel(repository: dependencies.repository, room: room))
        case .editContainer(let container):
            ContainerFormView(viewModel: ContainerFormViewModel(repository: dependencies.repository,
                                                                container: container))
        case .newItem(let container):
            ItemFormView(viewModel: ItemFormViewModel(repository: dependencies.repository,
                                                      catalog: dependencies.catalog, container: container))
        case .editItem(let item):
            ItemFormView(viewModel: ItemFormViewModel(repository: dependencies.repository,
                                                      catalog: dependencies.catalog, item: item))
        }
    }
}
