import Foundation

/// Демонстрационный набор данных для первого этапа (интерфейс без хранилища).
enum SampleInventory {
    static let rooms: [Room] = [
        Room(name: "Гостиная", icon: "sofa", containers: [
            StorageContainer(name: "Тумба под телевизором", code: "BOX-0001", items: [
                Item(name: "HDMI-кабель 2 м", quantity: 3, category: "Электроника", icon: "cable.connector"),
                Item(name: "Пульт от кондиционера", category: "Электроника", icon: "av.remote"),
                Item(name: "Батарейки AA", quantity: 12, category: "Расходные материалы", icon: "battery.100")
            ]),
            StorageContainer(name: "Книжный шкаф", code: "BOX-0002", items: [
                Item(name: "Фотоальбом 2019", category: "Документы и книги", icon: "book.closed"),
                Item(name: "Настольная игра «Каркассон»", category: "Хобби", icon: "gamecontroller")
            ])
        ]),
        Room(name: "Кухня", icon: "fork.knife", containers: [
            StorageContainer(name: "Верхний шкаф", code: "BOX-0003", items: [
                Item(name: "Сервиз чайный", quantity: 6, category: "Посуда", icon: "cup.and.saucer"),
                Item(name: "Блендер", category: "Бытовая техника", icon: "blender")
            ])
        ]),
        Room(name: "Кладовая", icon: "archivebox", containers: [
            StorageContainer(name: "Коробка «Инструменты»", code: "BOX-0004", items: [
                Item(name: "Шуруповёрт", category: "Инструменты", icon: "wrench.and.screwdriver"),
                Item(name: "Набор отвёрток", quantity: 1, category: "Инструменты", icon: "screwdriver"),
                Item(name: "Рулетка 5 м", category: "Инструменты", icon: "ruler")
            ]),
            StorageContainer(name: "Коробка «Новый год»", code: "BOX-0005", items: [
                Item(name: "Гирлянда светодиодная", quantity: 2, category: "Декор", icon: "lightbulb"),
                Item(name: "Ёлочные игрушки", quantity: 24, category: "Декор", icon: "sparkles")
            ])
        ]),
        Room(name: "Гараж", icon: "car", containers: [
            StorageContainer(name: "Стеллаж у стены", code: "BOX-0006", items: [
                Item(name: "Зимние шины", quantity: 4, category: "Автотовары", icon: "car.circle"),
                Item(name: "Насос автомобильный", category: "Автотовары", icon: "gauge.with.dots.needle.33percent")
            ])
        ])
    ]
}
