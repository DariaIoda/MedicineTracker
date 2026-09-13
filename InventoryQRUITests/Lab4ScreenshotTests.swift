import XCTest

/// Сценарий лабораторной работы №4: загрузка начальных данных через REST API при каждом старте,
/// сохранение пользовательских данных между запусками и экспорт списка вещей коробки.
final class Lab4ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func waitForSync() {
        let synced = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Данные с сервера загружены")).firstMatch
        XCTAssertTrue(synced.waitForExistence(timeout: 60), "Данные с сервера не загрузились")
    }

    func testRestSyncAndExport() throws {
        // Первый запуск: база данных на диске пуста, все данные приходят с сервера
        app.launchArguments = ["-resetStore"]
        app.launch()
        app.navigationBars["Инвентарь"].waitToAppear()
        waitForSync()
        app.staticTexts["Гостиная"].waitToAppear()
        ScreenshotHelper.capture("lab4_01_synced_from_rest", in: self)

        // Пользователь добавляет свою комнату
        app.buttons["addMenu"].waitToAppear().tap()
        app.buttons["Комната"].waitToAppear().tap()
        let roomName = app.textFields["roomName"].waitToAppear()
        roomName.tap()
        roomName.typeText("Балкон")
        app.buttons["saveButton"].tap()
        app.staticTexts["Балкон"].waitToAppear()

        // Повторный запуск: снова загрузка с сервера, данные пользователя сохранились
        app.terminate()
        app.launchArguments = []
        app.launch()
        app.navigationBars["Инвентарь"].waitToAppear()
        waitForSync()
        app.staticTexts["Балкон"].waitToAppear()
        XCTAssertTrue(app.staticTexts["Гостиная"].exists)
        ScreenshotHelper.capture("lab4_02_relaunch_user_data_kept", in: self)

        // Карточка контейнера и экспорт
        let group = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Инструменты")).firstMatch
        app.scrollTo(group).tap()
        app.scrollTo(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Карточка контейнера")).firstMatch).tap()
        app.images["containerQR"].waitToAppear()
        app.buttons["exportContainer"].waitToAppear()
        ScreenshotHelper.capture("lab4_03_container_export_button", in: self)
        app.buttons["exportContainer"].tap()
        app.staticTexts["exportPreview"].waitToAppear()
        ScreenshotHelper.capture("lab4_04_export_json", in: self)

        app.buttons["CSV (для таблиц)"].tap()
        sleep(1)
        ScreenshotHelper.capture("lab4_05_export_csv", in: self)

        app.buttons["shareExport"].tap()
        sleep(3)
        ScreenshotHelper.capture("lab4_06_share_sheet", in: self)
    }
}
