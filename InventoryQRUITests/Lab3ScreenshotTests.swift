import XCTest

/// Сценарий лабораторной работы №3: пустая база данных и полный цикл CRUD через интерфейс.
final class Lab3ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "-offline"]   // пустая база в памяти, без тестовых и серверных данных
        app.launch()
    }

    private func tapSave() {
        app.buttons["saveButton"].waitToAppear().tap()
    }

    func testCrudCycle() throws {
        app.navigationBars["Инвентарь"].waitToAppear()
        app.staticTexts["Инвентарь пуст"].waitToAppear()
        ScreenshotHelper.capture("lab3_01_empty_database", in: self)

        // Create: комната
        app.buttons["Добавить комнату"].tap()
        let roomName = app.textFields["roomName"].waitToAppear()
        roomName.tap()
        roomName.typeText("Кладовая")
        app.dismissKeyboardTip()
        app.descendants(matching: .any)["icon_archivebox"].firstMatch.waitToAppear().tap()
        ScreenshotHelper.capture("lab3_02_room_form", in: self)
        tapSave()

        // Create: контейнер
        app.buttons["addMenu"].waitToAppear().tap()
        app.buttons["Контейнер"].waitToAppear().tap()
        let containerName = app.textFields["containerName"].waitToAppear()
        containerName.tap()
        containerName.typeText("Коробка «Инструменты»")
        app.dismissKeyboardTip()
        ScreenshotHelper.capture("lab3_03_container_form", in: self)
        tapSave()

        // Create: вещь с типом из JSON-классификатора
        app.buttons["addMenu"].waitToAppear().tap()
        app.buttons["Вещь"].waitToAppear().tap()
        let itemName = app.textFields["itemName"].waitToAppear()
        itemName.tap()
        itemName.typeText("Шуруповёрт")
        app.dismissKeyboardTip()
        app.buttons["itemType"].waitToAppear().tap()
        app.staticTexts["Инструменты"].waitToAppear()
        ScreenshotHelper.capture("lab3_04_type_classifier", in: self)
        app.staticTexts["Инструменты"].tap()
        app.textFields["itemName"].waitToAppear()
        app.dismissKeyboardTip()
        sleep(1)                                       // ждём окончания анимации возврата к форме
        ScreenshotHelper.capture("lab3_05_item_form", in: self)
        tapSave()

        // Вторая вещь
        app.buttons["addMenu"].waitToAppear().tap()
        app.buttons["Вещь"].waitToAppear().tap()
        let second = app.textFields["itemName"].waitToAppear()
        second.tap()
        second.typeText("Рулетка 5 м")
        app.buttons["itemType"].tap()
        app.staticTexts["Инструменты"].waitToAppear().tap()
        tapSave()

        // Read: иерархия
        let group = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Инструменты")).firstMatch
        group.waitToAppear().tap()
        app.staticTexts["Шуруповёрт"].waitToAppear()
        ScreenshotHelper.capture("lab3_06_hierarchy_after_create", in: self)

        // Update: изменение вещи
        app.staticTexts["Шуруповёрт"].tap()
        app.buttons["editItem"].waitToAppear().tap()
        let editName = app.textFields["itemName"].waitToAppear()
        editName.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
        editName.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 20))
        editName.typeText("Шуруповёрт Bosch")
        let increment = app.buttons["itemQuantity-Increment"]
        if increment.exists {
            increment.tap()
        } else {
            app.buttons["Increment"].firstMatch.tap()
        }
        ScreenshotHelper.capture("lab3_07_item_edit", in: self)
        tapSave()
        app.staticTexts["Шуруповёрт Bosch"].waitToAppear()
        ScreenshotHelper.capture("lab3_08_item_updated", in: self)

        // Delete: удаление вещи
        app.buttons["Удалить вещь"].tap()
        app.navigationBars["Инвентарь"].waitToAppear()
        XCTAssertFalse(app.staticTexts["Шуруповёрт Bosch"].waitForExistence(timeout: 2))
        ScreenshotHelper.capture("lab3_09_after_delete", in: self)

        // Delete свайпом: контейнер вместе с вещами
        let row = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Инструменты")).firstMatch
        row.swipeLeft()
        app.buttons["Удалить"].waitToAppear()
        ScreenshotHelper.capture("lab3_10_swipe_delete", in: self)
        app.buttons["Удалить"].tap()
        XCTAssertFalse(app.staticTexts["Рулетка 5 м"].waitForExistence(timeout: 2))
    }
}
