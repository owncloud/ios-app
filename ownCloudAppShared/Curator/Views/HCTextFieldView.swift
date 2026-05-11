import UIKit
import SnapKit

extension ThemeCSSSelector {
	public static let hcTextField = ThemeCSSSelector(rawValue: "hcTextField")
}

open class HCTextFieldView: HCFieldView {
	private enum Constants {
		static let textFontSize = 16.0
	}

	private var placeholderColor: UIColor?
	private var textColor: UIColor?

	open var isEmpty: Bool {
		textField.text?.isEmpty ?? true
	}

	private lazy var stackView: UIStackView = {
		let stackView = UIStackView()
		stackView.backgroundColor = .clear
		stackView.axis = .horizontal
		stackView.spacing = 8
		return stackView
	}()

	public lazy var textField: UITextField = {
		let textField = UITextField()
		textField.borderStyle = .none
		textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
		textField.addTarget(self, action: #selector(editingDidBegin), for: .editingDidBegin)
		textField.addTarget(self, action: #selector(editingDidEnd), for: .editingDidEnd)
		textField.font = UIFont.systemFont(ofSize: Constants.textFontSize)
		return textField
	}()

	private(set) public lazy var clearButton: UIButton = {
		let button = UIButton(type: .custom)
		button.setImage(UIImage(named: "xmark-circle", in: Bundle.sharedAppBundle, with: nil), for: .normal)
		button.addTarget(self, action: #selector(clearTextField), for: .touchUpInside)
		return button
	}()

	private lazy var iconView: UIImageView = {
		let imageView = UIImageView()
		imageView.contentMode = .scaleAspectFit
		imageView.snp.makeConstraints { $0.width.height.equalTo(24) }
		return imageView
	}()

	open var title: String? {
		didSet {
			borderView.title = title
			updateAppearance()
		}
	}

	open var placeholder: String? {
		didSet {
			updateAppearance()
		}
	}

	open var leftIcon: UIImage? {
		didSet {
			updateAppearance()
		}
	}

	public override var contentView: UIView {
		stackView
	}

	public override var isActive: Bool {
		textField.isFirstResponder
	}

	public override init(frame: CGRect) {
		super.init(frame: frame)

		commonInit()
	}

	public required init?(coder: NSCoder) {
		super.init(coder: coder)

		commonInit()
	}

	private func commonInit() {
		cssSelectors = (cssSelectors ?? []) + [.hcTextField]

		textField.rightView = clearButton
		textField.rightViewMode = .never

		stackView.addArrangedSubviews([
			iconView, textField
		])

		updateTextField()
		updateAppearance()
		updateContentView()
	}

	public override func updateContentView() {
		textField.textColor = textColor
		var styledPlaceholder = AttributedString(placeholder ?? "")
		styledPlaceholder.foregroundColor = placeholderColor
		styledPlaceholder.font = UIFont.systemFont(ofSize: Constants.textFontSize)
		textField.attributedPlaceholder = NSAttributedString(styledPlaceholder)
	}

	public override func resignFirstResponder() -> Bool {
		defer { updateTextField() }
		super.resignFirstResponder()

		return textField.resignFirstResponder()
	}

	public override func applyThemeCollection(
		theme: Theme,
		collection: ThemeCollection,
		event: ThemeEvent
	) {
		placeholderColor = collection.css.getColor(.stroke, selectors: [.placeholder], for: self)
		textColor = collection.css.getColor(.stroke, selectors: [.text], for: self)
		clearButton.tintColor = textColor
		updateAppearance()

		super.applyThemeCollection(theme: theme, collection: collection, event: event)

		backgroundColor = .clear
	}

	public override func updateAppearance() {
		super.updateAppearance()

		if let leftIcon {
			iconView.image = leftIcon
			iconView.isHidden = false
		} else {
			iconView.isHidden = true
		}
		borderView.shouldDisplayTitle = !isEmpty
	}

	open func updateTextField() {
		let isEmpty = textField.text?.isEmpty ?? true
		let isFirstResponder = textField.isFirstResponder
		textField.rightViewMode = !isEmpty && isFirstResponder ? .always : .never
	}

	@objc private func clearTextField() {
		textField.text = ""

		NotificationCenter.default.post(name: UITextField.textDidChangeNotification, object: textField)

		updateTextField()
	}

	@objc private func editingChanged() {
		updateAppearance()
		updateTextField()
	}

	@objc private func editingDidBegin() {
		updateAppearance()
		updateTextField()
	}

	@objc private func editingDidEnd() {
		updateAppearance()
		updateTextField()
	}
}
