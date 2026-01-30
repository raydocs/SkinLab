import XCTest

class SkinLabUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        element.waitForExistence(timeout: timeout)
    }

    func tapButton(_ identifier: String) {
        let button = app.buttons[identifier]
        XCTAssertTrue(waitForElement(button), "Button '\(identifier)' not found")
        button.tap()
    }

    func tapNavigationButton(_ identifier: String) {
        let button = app.navigationBars.buttons[identifier]
        XCTAssertTrue(waitForElement(button), "Navigation button '\(identifier)' not found")
        button.tap()
    }

    func enterText(_ identifier: String, text: String) {
        let textField = app.textFields[identifier]
        XCTAssertTrue(waitForElement(textField), "TextField '\(identifier)' not found")
        textField.tap()
        textField.typeText(text)
    }

    func assertElementExists(_ identifier: String, type: XCUIElement.ElementType = .any) {
        let element: XCUIElement = switch type {
        case .button:
            app.buttons[identifier]
        case .staticText:
            app.staticTexts[identifier]
        case .image:
            app.images[identifier]
        case .textField:
            app.textFields[identifier]
        default:
            app.otherElements[identifier]
        }
        XCTAssertTrue(waitForElement(element), "Element '\(identifier)' of type '\(type)' not found")
    }

    func assertTextExists(_ text: String) {
        let element = app.staticTexts[text]
        XCTAssertTrue(waitForElement(element), "Text '\(text)' not found on screen")
    }

    func swipeUp(on element: XCUIElement? = nil) {
        (element ?? app).swipeUp()
    }

    func swipeDown(on element: XCUIElement? = nil) {
        (element ?? app).swipeDown()
    }

    func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func dismissKeyboard() {
        if app.keyboards.count > 0 {
            app.keyboards.buttons["Return"].tap()
        }
    }

    func waitForLoadingToComplete(timeout: TimeInterval = 10) {
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            let notExists = NSPredicate(format: "exists == false")
            expectation(for: notExists, evaluatedWith: loadingIndicator)
            waitForExpectations(timeout: timeout)
        }
    }
}
