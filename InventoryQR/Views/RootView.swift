import SwiftUI

/// Корневой экран: стек навигации «Комната → Контейнер → Вещь».
struct RootView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            InventoryHomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .room(let id):
                        RoomView(roomID: id)
                    case .container(let id):
                        ContainerView(containerID: id)
                    case .item(let id):
                        ItemDetailView(itemID: id)
                    }
                }
        }
    }
}

#Preview {
    RootView()
        .environment(InventoryStore())
}
