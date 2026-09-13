import SwiftUI

/// Главный экран: иерархия хранения и текстовый поиск по вещам.
struct InventoryHomeView: View {
    @Environment(InventoryStore.self) private var store
    @State private var searchText = ""
    @State private var expanded: Set<StorageContainer.ID> = []

    var body: some View {
        List {
            if searchText.isEmpty {
                summarySection
                ForEach(store.rooms) { room in
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
            } else {
                searchResults
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Инвентарь")
        .searchable(text: $searchText,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Поиск вещи")
        .accessibilityIdentifier("homeList")
    }

    private var summarySection: some View {
        Section {
            HStack(spacing: 12) {
                StatBadge(value: store.rooms.count, title: "комнат", icon: "house")
                StatBadge(value: store.containerCount, title: "контейнеров", icon: "shippingbox")
                StatBadge(value: store.itemCount, title: "вещей", icon: "cube")
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
        }
    }

    private func containerGroup(_ container: StorageContainer) -> some View {
        DisclosureGroup(isExpanded: binding(for: container.id)) {
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
        let results = store.search(searchText)
        if results.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            Section("Найдено: \(results.count)") {
                ForEach(results) { location in
                    NavigationLink(value: Route.item(location.item.id)) {
                        SearchResultRow(location: location, query: searchText)
                    }
                }
            }
        }
    }

    private func binding(for id: StorageContainer.ID) -> Binding<Bool> {
        Binding(
            get: { expanded.contains(id) },
            set: { isOn in
                if isOn { expanded.insert(id) } else { expanded.remove(id) }
            }
        )
    }
}

#Preview {
    NavigationStack {
        InventoryHomeView()
    }
    .environment(InventoryStore())
}
