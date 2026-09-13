import XCTest

/// Сохраняет снимки экрана в папку, заданную переменной SCREENSHOT_DIR
/// (в CI передаётся как TEST_RUNNER_SCREENSHOT_DIR), и прикладывает их к отчёту теста.
enum ScreenshotHelper {
    static func capture(_ name: String, in testCase: XCTestCase) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        testCase.add(attachment)

        guard let dir = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"], !dir.isEmpty else { return }
        let device = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? "device"
        let folder = URL(fileURLWithPath: dir).appendingPathComponent(device.replacingOccurrences(of: " ", with: "_"))
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try? shot.pngRepresentation.write(to: folder.appendingPathComponent("\(name).png"))
    }
}

extension XCUIApplication {
    /// Прокручивает список, пока элемент не появится на экране (строки List создаются лениво).
    @discardableResult
    func scrollTo(_ element: XCUIElement, maxSwipes: Int = 8) -> XCUIElement {
        var swipes = 0
        while !(element.exists && element.isHittable) && swipes < maxSwipes {
            swipeUp()
            swipes += 1
        }
        return element.waitToAppear()
    }
}

extension XCUIElement {
    @discardableResult
    func waitToAppear(_ timeout: TimeInterval = 10) -> XCUIElement {
        XCTAssertTrue(waitForExistence(timeout: timeout), "Не найден элемент: \(self)")
        return self
    }
}
