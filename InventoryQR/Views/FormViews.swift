import SwiftUI

/// Форма создания и редактирования комнаты.
struct RoomFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: RoomFormViewModel

    init(viewModel: RoomFormViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Например, Кладовая", text: $viewModel.name)
                        .accessibilityIdentifier("roomName")
                }
                Section("Значок") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(RoomFormViewModel.icons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 48, height: 48)
                                .background(viewModel.icon == icon ? Color.accentColor.opacity(0.2) : .clear,
                                            in: RoundedRectangle(cornerRadius: 10))
                                .contentShape(Rectangle())
                                .onTapGesture { viewModel.icon = icon }
                                .accessibilityAddTraits(.isButton)
                                .accessibilityIdentifier("icon_\(icon)")
                        }
                    }
                    .padding(.vertical, 4)
                }
                if let message = viewModel.errorMessage {
                    Text(message).foregroundStyle(.red)
                }
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { formToolbar(canSave: viewModel.canSave) { viewModel.save() } }
        }
    }

    @ToolbarContentBuilder
    private func formToolbar(canSave: Bool, save: @escaping () -> Bool) -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Отмена") { dismiss() }
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Сохранить") { if save() { dismiss() } }
                .disabled(!canSave)
                .accessibilityIdentifier("saveButton")
        }
    }
}

/// Форма создания и редактирования контейнера.
struct ContainerFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ContainerFormViewModel

    init(viewModel: ContainerFormViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section("Название") {
                    TextField("Например, Коробка «Инструменты»", text: $viewModel.name)
                        .accessibilityIdentifier("containerName")
                }
                Section("Местоположение") {
                    Picker("Комната", selection: $viewModel.roomID) {
                        ForEach(viewModel.rooms) { room in
                            Label(room.name, systemImage: room.icon).tag(Optional(room.id))
                        }
                    }
                }
                if let code = viewModel.code {
                    Section("Маркировка") {
                        LabeledContent("Код", value: code)
                    }
                } else {
                    Section {
                        Text("Код маркировки и QR-код будут созданы автоматически")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                if let message = viewModel.errorMessage {
                    Text(message).foregroundStyle(.red)
                }
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { if viewModel.save() { dismiss() } }
                        .disabled(!viewModel.canSave)
                        .accessibilityIdentifier("saveButton")
                }
            }
        }
    }
}

/// Форма создания и редактирования вещи.
struct ItemFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ItemFormViewModel

    init(viewModel: ItemFormViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            Form {
                Section("Вещь") {
                    TextField("Название", text: $viewModel.name)
                        .accessibilityIdentifier("itemName")
                    Stepper("Количество: \(viewModel.quantity)", value: $viewModel.quantity, in: 1...9999)
                        .accessibilityIdentifier("itemQuantity")
                }
                Section("Тип имущества") {
                    Picker("Тип", selection: $viewModel.typeID) {
                        ForEach(viewModel.catalog.types) { type in
                            Label(type.category, systemImage: type.icon).tag(type.id)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .accessibilityIdentifier("itemType")
                }
                Section("Местоположение") {
                    Picker("Контейнер", selection: $viewModel.containerID) {
                        ForEach(viewModel.containerChoices) { group in
                            Section(group.room.name) {
                                ForEach(group.containers) { container in
                                    Text(container.name).tag(Optional(container.id))
                                }
                            }
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                Section("Заметка") {
                    TextField("Необязательно", text: $viewModel.note, axis: .vertical)
                        .lineLimit(2...4)
                }
                if let message = viewModel.errorMessage {
                    Text(message).foregroundStyle(.red)
                }
            }
            .navigationTitle(viewModel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { if viewModel.save() { dismiss() } }
                        .disabled(!viewModel.canSave)
                        .accessibilityIdentifier("saveButton")
                }
            }
        }
    }
}
