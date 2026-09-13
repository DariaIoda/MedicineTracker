import XCTest

/// Сценарий лабораторной работы №2: карточка контейнера с QR-кодом и сканирование.
final class Lab2ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-uiTesting", "-seedSampleData", "-offline"]
        app.launch()
    }

    func testContainerCardWithQRCode() throws {
        app.navigationBars["Инвентарь"].waitToAppear(90)
        app.scrollTo(app.buttons["openRoom_Кладовая"]).tap()
        app.navigationBars["Кладовая"].waitToAppear()
        app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Инструменты")).firstMatch
            .waitToAppear().tap()
        app.images["containerQR"].waitToAppear()
        ScreenshotHelper.capture("lab2_01_container_card", in: self)

        app.swipeUp()
        ScreenshotHelper.capture("lab2_02_container_items", in: self)

        app.swipeDown()
        app.images["containerQR"].waitToAppear().tap()
        app.buttons["Готово"].waitToAppear()
        ScreenshotHelper.capture("lab2_03_qr_fullscreen", in: self)
        app.buttons["Готово"].tap()
    }

    func testScanningFlow() throws {
        app.navigationBars["Инвентарь"].waitToAppear(90)
        app.buttons["scanButton"].waitToAppear().tap()
        app.buttons["mock_label_box_0004"].waitToAppear()
        ScreenshotHelper.capture("lab2_04_scanner_mock", in: self)

        app.buttons["mock_label_box_0004"].tap()
        // заголовок секции списка отображается прописными буквами, поэтому ждём содержимое
        app.staticTexts["Коробка «Инструменты»"].waitToAppear()
        app.staticTexts["Шуруповёрт"].waitToAppear()
        ScreenshotHelper.capture("lab2_05_scan_found", in: self)

        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Открыть карточку контейнера")).firstMatch.tap()
        app.images["containerQR"].waitToAppear()
        ScreenshotHelper.capture("lab2_06_opened_from_scan", in: self)

        if !app.buttons["scanButton"].exists {
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        app.buttons["scanButton"].waitToAppear().tap()
        app.scrollTo(app.buttons["mock_label_box_9999"]).tap()
        app.staticTexts["Контейнер не найден"].waitToAppear()
        ScreenshotHelper.capture("lab2_07_scan_unknown", in: self)

        app.buttons["Сканировать снова"].firstMatch.tap()
        app.scrollTo(app.buttons["mock_label_foreign"]).tap()
        app.staticTexts["Это не метка инвентаря"].waitToAppear()
        ScreenshotHelper.capture("lab2_08_scan_foreign", in: self)
    }
}
