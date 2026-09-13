import SwiftUI

/// Главный экран: иерархия хранения и текстовый поиск по вещам.
struct InventoryHomeView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var viewModel: InventoryListViewModel
    let onOpenContainer: (StorageContainer.ID) -> Void

    init(viewModel: InventoryListViewModel, onOpenContainer: @escaping (StorageContainer.ID) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenContainer = onOpenContainer
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        List {
            if viewModel.isSearching {
                searchResults
            } else {
                summarySection
                ForEach(viewModel.rooms) { room in
                    Section {
                        NavigationLink(value: Route.room(room.id)) {
                            Label("Открыть комнату", systemImage: "arrow.right.circle")
                                .foregroundStyle(.tint)
                        }
                        .accessibilityIdentifier("openRoom_\(room.name)")
                        ForEach(room.containers) { container in
                            containerGroup(container)
                        }
                    } header: {
                        RoomHeader(room: room)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Инвентарь")
        .searchable(text: $viewModel.searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Поиск вещи")
        .toolbar {
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
    }

    private var summarySection: some View {
        Section {
            HStack(spacing: 12) {
                StatBadge(value: viewModel.roomCount, title: "комнат", icon: "house")
                StatBadge(value: viewModel.containerCount, title: "контейнеров", icon: "shippingbox")
                StatBadge(value: viewModel.itemCount, title: "вещей", icon: "cube")
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        }
    }

    private func containerGroup(_ container: StorageContainer) -> some View {
        DisclosureGroup(isExpanded: Binding(
            get: { viewModel.isExpanded(container.id) },
            set: { viewModel.setExpanded(container.id, $0) }
        )) {
            ForEach(container.items) { item in
                NavigationLink(value: Route.item(item.id)) {
                    ItemRow(item: item)
                }
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
        let results = viewModel.searchResults
        if results.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            Section("Найдено: \(results.count)") {
                ForEach(results) { location in
                    NavigationLink(value: Route.item(location.item.id)) {
                        SearchResultRow(location: location, query: viewModel.searchText)
                    }
                }
            }
        }
    }
}
