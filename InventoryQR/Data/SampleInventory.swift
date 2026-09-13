import Foundation
import SwiftData

/// Тестовый набор данных. Подставляется только при запуске с аргументом -seedSampleData
/// (UI-тесты); в обычном запуске база данных изначально пуста.
enum SampleInventory {
    static func insert(into context: ModelContext) {
        let plan: [(String, String, [(String, String, [(String, Int, String)])])] = [
            ("Гостиная", "sofa", [
                ("Тумба под телевизором", "BOX-0001", [
                    ("HDMI-кабель 2 м", 3, "electronics"),
                    ("Пульт от кондиционера", 1, "electronics"),
                    ("Батарейки AA", 12, "consumables")
                ]),
                ("Книжный шкаф", "BOX-0002", [
                    ("Фотоальбом 2019", 1, "documents"),
                    ("Настольная игра «Каркассон»", 1, "hobby")
                ])
            ]),
            ("Кухня", "fork.knife", [
                ("Верхний шкаф", "BOX-0003", [
                    ("Сервиз чайный", 6, "dishes"),
                    ("Блендер", 1, "appliances")
                ])
            ]),
            ("Кладовая", "archivebox", [
                ("Коробка «Инструменты»", "BOX-0004", [
                    ("Шуруповёрт", 1, "tools"),
                    ("Набор отвёрток", 1, "tools"),
                    ("Рулетка 5 м", 1, "tools")
                ]),
                ("Коробка «Новый год»", "BOX-0005", [
                    ("Гирлянда светодиодная", 2, "decor"),
                    ("Ёлочные игрушки", 24, "decor")
                ])
            ]),
            ("Гараж", "car", [
                ("Стеллаж у стены", "BOX-0006", [
                    ("Зимние шины", 4, "auto"),
                    ("Насос автомобильный", 1, "auto")
                ])
            ])
        ]
        for (roomName, icon, containers) in plan {
            let room = Room(name: roomName, icon: icon)
            context.insert(room)
            for (containerName, code, items) in containers {
                let container = StorageContainer(name: containerName, code: code)
                context.insert(container)
                container.room = room
                for (itemName, quantity, typeID) in items {
                    let item = Item(name: itemName, quantity: quantity, typeID: typeID)
                    context.insert(item)
                    item.container = container
                }
            }
        }
        try? context.save()
    }
}
