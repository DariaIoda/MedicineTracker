import SwiftUI

/// Корневой экран: стек навигации «Комната → Контейнер → Вещь».
/// Здесь View получают свои ViewModel с зависимостями из AppDependencies.
struct RootView: View {
    @Environment(AppDependencies.self) private var dependencies
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            InventoryHomeView(
                viewModel: InventoryListViewModel(repository: dependencies.repository),
                onOpenContainer: { id in path.append(Route.container(id)) }
            )
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .room(let id):
                    RoomView(viewModel: RoomViewModel(roomID: id, repository: dependencies.repository))
                case .container(let id):
                    ContainerCardView(viewModel: ContainerDetailViewModel(
                        containerID: id,
                        repository: dependencies.repository,
                        generator: dependencies.qrGenerator))
                case .item(let id):
                    ItemDetailView(viewModel: ItemDetailViewModel(itemID: id, repository: dependencies.repository))
                }
            }
        }
    }
}

#Preview {
    RootView()
        .environment(AppDependencies())
}
