import SwiftUI

/// Экран комнаты: список её контейнеров.
struct RoomView: View {
    @State private var viewModel: RoomViewModel

    init(viewModel: RoomViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        if let room = viewModel.room {
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

/// Экран вещи с местоположением.
struct ItemDetailView: View {
    @State private var viewModel: ItemDetailViewModel

    init(viewModel: ItemDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        if let location = viewModel.location {
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
                    NavigationLink(value: Route.container(location.container.id)) {
                        Label(location.container.name, systemImage: "shippingbox")
                    }
                }
            }
            .navigationTitle("Вещь")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("Вещь не найдена", systemImage: "cube")
        }
    }
}
