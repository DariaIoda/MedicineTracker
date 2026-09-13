import SwiftUI

/// Экран комнаты: список её контейнеров.
struct RoomView: View {
    @Environment(InventoryStore.self) private var store
    let roomID: Room.ID

    var body: some View {
        if let room = store.room(id: roomID) {
            List {
                Section("Контейнеры") {
                    ForEach(room.containers) { container in
                        NavigationLink(value: Route.container(container.id)) {
                            ContainerRow(container: container)
                        }
                    }
                }
            }
            .navigationTitle(room.name)
        } else {
            ContentUnavailableView("Комната не найдена", systemImage: "house.slash")
        }
    }
}

/// Экран контейнера: перечень вещей внутри.
struct ContainerView: View {
    @Environment(InventoryStore.self) private var store
    let containerID: StorageContainer.ID

    var body: some View {
        if let found = store.container(id: containerID) {
            List {
                Section {
                    LabeledContent("Комната", value: found.room.name)
                    LabeledContent("Код маркировки", value: found.container.code)
                    LabeledContent("Всего предметов", value: "\(found.container.totalQuantity)")
                }
                Section("Вещи") {
                    ForEach(found.container.items) { item in
                        NavigationLink(value: Route.item(item.id)) {
                            ItemRow(item: item)
                        }
                    }
                }
            }
            .navigationTitle(found.container.name)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("Контейнер не найден", systemImage: "shippingbox")
        }
    }
}

/// Экран вещи с местоположением.
struct ItemDetailView: View {
    @Environment(InventoryStore.self) private var store
    let itemID: Item.ID

    var body: some View {
        if let location = store.location(ofItem: itemID) {
            List {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: location.item.icon)
                            .font(.system(size: 56))
                            .foregroundStyle(.blue)
                        Text(location.item.name)
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                Section("Сведения") {
                    LabeledContent("Категория", value: location.item.category)
                    LabeledContent("Количество", value: "\(location.item.quantity)")
                    if !location.item.note.isEmpty {
                        LabeledContent("Заметка", value: location.item.note)
                    }
                }
                Section("Местоположение") {
                    Label(location.room.name, systemImage: location.room.icon)
                    Label(location.container.name, systemImage: "shippingbox")
                }
            }
            .navigationTitle("Вещь")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("Вещь не найдена", systemImage: "cube")
        }
    }
}
