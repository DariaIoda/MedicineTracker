import XCTest

/// Сценарий лабораторной работы №1: иерархия хранения и поиск с местоположением.
final class Lab1ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "-seedSampleData"]
        app.launch()
    }

    func testHierarchyAndSearch() throws {
        let homeTitle = app.navigationBars["Инвентарь"]
        homeTitle.waitToAppear()
        ScreenshotHelper.capture("lab1_01_home", in: self)

        // Раскрываем контейнер внутри комнаты
        let tvStand = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Тумба под телевизором")).firstMatch
        tvStand.waitToAppear()
        tvStand.tap()
        app.staticTexts["HDMI-кабель 2 м"].waitToAppear()
        ScreenshotHelper.capture("lab1_02_expanded", in: self)

        // Поиск вещи с указанием местоположения
        let search = app.searchFields.firstMatch
        search.waitToAppear()
        search.tap()
        search.typeText("инструмент")
        app.staticTexts["Шуруповёрт"].waitToAppear()
        ScreenshotHelper.capture("lab1_03_search", in: self)

        app.staticTexts["Шуруповёрт"].tap()
        app.navigationBars["Вещь"].waitToAppear()
        ScreenshotHelper.capture("lab1_04_item", in: self)

        app.navigationBars.buttons.element(boundBy: 0).tap()
        let cancel = app.buttons["Cancel"].exists ? app.buttons["Cancel"] : app.buttons["Отменить"]
        if cancel.exists { cancel.tap() }

        // Переход в комнату и карточку контейнера
        homeTitle.waitToAppear()
        app.scrollTo(app.buttons["openRoom_Кладовая"]).tap()
        app.navigationBars["Кладовая"].waitToAppear()
        ScreenshotHelper.capture("lab1_05_room", in: self)

        app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Инструменты")).firstMatch.tap()
        app.navigationBars["Коробка «Инструменты»"].waitToAppear()
        ScreenshotHelper.capture("lab1_06_container", in: self)
    }
}
