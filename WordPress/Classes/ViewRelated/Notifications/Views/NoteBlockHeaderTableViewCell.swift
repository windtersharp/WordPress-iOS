import Foundation
import WordPressShared.WPStyleGuide

class NoteBlockHeaderTableViewCell: NoteBlockTableViewCell
{
    // MARK: - Public Properties
    var headerTitle: String? {
        set {
            headerTitleLabel.text  = newValue
        }
        get {
            return headerTitleLabel.text
        }
    }

    var attributedHeaderTitle: NSAttributedString? {
        set {
            headerTitleLabel.attributedText  = newValue
        }
        get {
            return headerTitleLabel.attributedText
        }
    }

    var headerDetails: String? {
        set {
            headerDetailsLabel.text = newValue
        }
        get {
            return headerDetailsLabel.text
        }
    }


    // MARK: - Public Methods
    func downloadGravatarWithURL(url: NSURL?) {
        if url == gravatarURL {
            return
        }

        let placeholderImage = Style.gravatarPlaceholderImage
        let gravatar = url.flatMap { Gravatar($0) }
        gravatarImageView.downloadGravatar(gravatar, placeholder: placeholderImage, animate: true)

        gravatarURL = url
    }

    // MARK: - View Methods
    override func awakeFromNib() {
        super.awakeFromNib()

        accessoryType = .DisclosureIndicator

        backgroundColor = Style.blockBackgroundColor
        headerTitleLabel.font = Style.headerTitleBoldFont
        headerTitleLabel.textColor = Style.headerTitleColor
        headerDetailsLabel.font = Style.headerDetailsRegularFont
        headerDetailsLabel.textColor = Style.headerDetailsColor
        gravatarImageView.image = Style.gravatarPlaceholderImage
    }

    // MARK: - Overriden Methods
    override func refreshSeparators() {
        separatorsView.bottomVisible = true
        separatorsView.bottomInsets = UIEdgeInsetsZero
    }


    // MARK: - Private Alias
    private typealias Style = WPStyleGuide.Notifications

    // MARK: - Private
    private var gravatarURL: NSURL?

    // MARK: - IBOutlets
    @IBOutlet private weak var gravatarImageView: UIImageView!
    @IBOutlet private weak var headerTitleLabel: UILabel!
    @IBOutlet private weak var headerDetailsLabel: UILabel!
}
