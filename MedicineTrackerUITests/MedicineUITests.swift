import XCTest

final class MedicineUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAddMedicineFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()

        // 1. Проверяем, что открылся пустой список
        XCTAssertTrue(app.staticTexts["Аптечка пуста"].waitForExistence(timeout: 5))

        // 2. Нажимаем добавить
        app.buttons["Добавить"].tap()

        // 3. Вводим название
        let nameField = app.textFields["Название препарата"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 2))
        nameField.tap()
        nameField.typeText("Парацетамол")

        // 4. Сохраняем
        app.buttons["Сохранить"].tap()

        // 5. Проверяем, что лекарство появилось в списке
        XCTAssertTrue(app.staticTexts["Парацетамол"].waitForExistence(timeout: 5))
    }
}