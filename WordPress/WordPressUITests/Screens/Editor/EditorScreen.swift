import Foundation
import XCTest

class EditorScreen: BaseScreen {
    enum Mode {
        case rich
        case html

        func toggle() -> Mode {
            return self == .rich ? .html : .rich
        }
    }

    let mode: Mode
    var textView: XCUIElement

    private var richTextField = "Rich Content"
    private var htmlTextField = "HTMLContentView"

    let titleView = XCUIApplication().textViews["Title"]

    lazy var mediaButton = XCUIApplication().buttons["format_toolbar_insert_media"]
    lazy var headerButton = XCUIApplication().buttons["format_toolbar_select_paragraph_style"]
    lazy var boldButton = XCUIApplication().buttons["format_toolbar_toggle_bold"]
    lazy var italicButton = XCUIApplication().buttons["format_toolbar_toggle_italic"]
    lazy var underlineButton = XCUIApplication().buttons["format_toolbar_toggle_underline"]
    lazy var strikethroughButton = XCUIApplication().buttons["format_toolbar_toggle_strikethrough"]
    lazy var blockquoteButton = XCUIApplication().buttons["format_toolbar_toggle_blockquote"]
    lazy var listButton = XCUIApplication().buttons["format_toolbar_toggle_list_unordered"]
    lazy var linkButton = XCUIApplication().buttons["format_toolbar_insert_link"]
    lazy var horizontalrulerButton = XCUIApplication().buttons["format_toolbar_insert_horizontal_ruler"]
    lazy var sourcecodeButton = XCUIApplication().buttons["format_toolbar_toggle_html_view"]
    lazy var moreButton = XCUIApplication().buttons["format_toolbar_insert_more"]

    let unorderedListOption = XCUIApplication().buttons["Unordered List"]
    let orderedListOption = XCUIApplication().buttons["Ordered List"]

    init(mode: Mode) {
        var textField = ""
        self.mode = mode
        switch mode {
        case .rich:
            textField = richTextField
        case .html:
            textField = htmlTextField
        }

        let app = XCUIApplication()
        textView = app.textViews[textField]

        if !textView.exists {
            if app.otherElements[textField].exists {
                textView = app.otherElements[textField]
            }
        }

        super.init(element: textView)

        showOptionsStrip()
    }

    func showOptionsStrip() {
        textView.coordinate(withNormalizedOffset: .zero).tap()
        expandOptionsSctrip()
    }

    func expandOptionsSctrip() {
        let expandButton = app.children(matching: .window).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .button).element

        if expandButton.exists && expandButton.isHittable && !sourcecodeButton.exists {
            expandButton.tap()
        }
    }

    @discardableResult
    func addList(type: String) -> EditorScreen {
        tapToolbarButton(button: listButton)
        if type == "ul" {
            unorderedListOption.tap()
        } else if type == "ol" {
            orderedListOption.tap()
        }

        return self
    }

    func addListWithLines(type: String, lines: Array<String>) -> EditorScreen {
        addList(type: type)

        let returnButton = app.buttons["Return"]
        for (index, line) in lines.enumerated() {
            enterText(text: line)
            if index != (lines.count - 1) {
                returnButton.tap()
            }
        }
        return self
    }

    /**
     Tapping on toolbar button. And swipes if needed.
     */
    @discardableResult
    func tapToolbarButton(button: XCUIElement) -> EditorScreen {
        let swipeElement = mediaButton.isHittable ? mediaButton : linkButton

        if !button.exists || !button.isHittable {
            swipeElement.swipeLeft()
        }
        Logger.log(message: "Tapping on Toolbar button: \(button)", event: .d)
        button.tap()

        return self
    }

    /**
     Tapping in to textView by specific coordinate. Its always tricky to know what cooridnates to click.
     Here is a list of "known" coordinates:
     30:32 - first word in 2d indented line (list)
     30:72 - first word in 3d intended line (blockquote)
     */
    func tapByCordinates(x: Int, y: Int) -> EditorScreen {
        // textView frames on different devices:
        // iPhone X (0.0, 88.0, 375.0, 391.0)
        // iPhone SE (0.0, 64.0, 320.0, 504.0)
        let frame = textView.frame
        var vector = CGVector(dx: frame.minX + CGFloat(x), dy: frame.minY + CGFloat(y))
        if frame.minY == 88 {
            let yDiff = frame.minY - 64 // 64 - is minY for "normal" devices
            vector = CGVector(dx: frame.minX + CGFloat(x), dy: frame.minY - yDiff + CGFloat(y))
        }

        textView.coordinate(withNormalizedOffset: CGVector.zero).withOffset(vector).tap()
        sleep(1) // to make sure that "paste" manu wont show up.
        return self
    }

    /**
     Switches between Rich and HTML view.
     */
    func switchContentView() -> EditorScreen {
        tapToolbarButton(button: sourcecodeButton)


        return EditorScreen(mode: mode.toggle())
    }

    /**
     Common method to type in different text fields
     */
    @discardableResult
    func enterText(text: String) -> EditorScreen {
        textView.tap()
        textView.typeText(text)
        return self
    }

    /**
     Enters text into title field.
     - Parameter text: the test to enter into the title
     */
    func enterTextInTitle(text: String) -> EditorScreen {
        titleView.tap()
        titleView.typeText(text)

        return self
    }

    @discardableResult
    func deleteText(chars: Int) -> EditorScreen {
        for _ in 1...chars {
            app.keys["delete"].tap()
        }

        return self
    }

    func getViewContent() -> String {
        if  mode == .rich {
            return getTextContent()
        }

        return getHTMLContent()
    }

    /**
     Selects all entered text in provided textView element
     */
    func selectAllText() -> EditorScreen {
        textView.coordinate(withNormalizedOffset: CGVector.zero).press(forDuration: 1)
        app.menuItems["Select All"].tap()

        return self
    }

    func makeLink() -> EditorEditLinkScreen {
        tapToolbarButton(button: linkButton)

        return EditorEditLinkScreen()
    }
    /*
     Select Image from Camera Roll by its ID. Starts with 0
     Simulator range: 0..4
     */
    func addImageByOrder(id: Int) -> EditorScreen {
        tapToolbarButton(button: mediaButton)

        // Allow access to device media
        app.tap() // trigger the media permissions alert handler

        // Inject the first picture
        app.cells.element(boundBy: 0).tap()
        app.buttons["Insert 1"].tap()

        return self
    }

    // returns void since return screen depends on from which screen it loaded
    func goBack() {
        let navBar = app.navigationBars["Azctec Editor Navigation Bar"]
        navBar.buttons["Close"].tap()
        let notSavedState = app.staticTexts["You have unsaved changes."]
        if notSavedState.exists {
            Logger.log(message: "Discarding unsaved changes", event: .v)
            app.buttons["Discard"].tap()
        }
    }

    func publish() -> EditorNoticeComponent {
        app.buttons["Publish"].tap()
        confirmPublish()

        return EditorNoticeComponent(withNotice: "Post published", andAction: "View")
    }

    private func confirmPublish() {
        if FancyAlertComponent.isLoaded() {
            FancyAlertComponent().acceptAlert()
        } else {
            if isIpad {
                app.alerts.buttons["Publish"].tap()
            } else {
                app.sheets.buttons["Publish"].tap()
            }
        }
    }

    func openPostSettings() -> EditorPostSettings {
        app.buttons["More"].tap()
        if isIpad {
            app.alerts.buttons["Post Settings"].tap()
        } else {
            app.sheets.buttons["Post Settings"].tap()
        }

        return EditorPostSettings()
    }

    private func getHTMLContent() -> String {
        let text = textView.value as! String

        // Remove spaces between HTML tags.
        let regex = try! NSRegularExpression(pattern: ">\\s+?<", options: .caseInsensitive)
        let range = NSMakeRange(0, text.count)
        let strippedText = regex.stringByReplacingMatches(in: text, options: .reportCompletion, range: range, withTemplate: "><")

        return strippedText
    }

    private func getTextContent() -> String {
        return textView.value as! String
    }
}
