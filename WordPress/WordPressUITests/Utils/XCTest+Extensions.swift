import XCTest

extension XCUIElement {
    /**
     Removes any current text in the field
     */
    func clearTextIfNeeded() -> Void {
        let app = XCUIApplication()
        let content = self.value as! String

        if content.count > 0 && content != self.placeholderValue {
            self.press(forDuration: 1.2)
            app.menuItems["Select All"].tap()
            app.menuItems["Cut"].tap()
        }
    }

    /**
     Removes any current text in the field before typing in the new value
     - Parameter text: the text to enter into the field
     */
    func clearAndEnterText(text: String) -> Void {
        clearTextIfNeeded()
        self.tap()
        self.typeText(text)
    }
}

var isIPhone: Bool {
    return UIDevice.current.userInterfaceIdiom == .phone
}

var isIpad: Bool {
    return UIDevice.current.userInterfaceIdiom == .pad
}

extension XCTestCase {

    public func systemAlertHandler(alertTitle: String, alertButton: String) {
        addUIInterruptionMonitor(withDescription: alertTitle) { (alert) -> Bool in
            alert.buttons[alertButton].tap()
            return true
        }
    }

    public func waitForElementToExist(element: XCUIElement, timeout: TimeInterval? = nil) {
        let timeoutValue = timeout ?? 30
        guard element.waitForExistence(timeout: timeoutValue) else {
            XCTFail("Failed to find \(element) after \(timeoutValue) seconds.")
            return
        }
    }

    public func waitForElementToNotExist(element: XCUIElement, timeout: TimeInterval? = nil) {
        let notExistsPredicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: notExistsPredicate,
                                                    object: element)

        let timeoutValue = timeout ?? 30
        guard XCTWaiter().wait(for: [expectation], timeout: timeoutValue) == .completed else {
            XCTFail("\(element) still exists after \(timeoutValue) seconds.")
            return
        }
    }

    public struct DataHelper {
        static let title = "WordPress for iOS Test Post"
        static let shortText = "Lorem ipsum dolor sit amet."
        static let longText = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam ornare accumsan ante, sollicitudin bibendum erat bibendum nec. Nam congue efficitur leo eget porta. Proin dictum non ligula aliquam varius. Aenean vehicula nunc in sapien rutrum, nec vehicula enim iaculis."
        static let link = "https://wordpress.org/mobile/"
        static let category = "iOS Test"
        static let tag = "tag \(Date().toString())"
    }
}
