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

	/// When set, `leftIcon` is rendered as a template and tinted with this color.
	open var leftIconTintColor: UIColor? {
		didSet {
			updateAppearance()
		}
	}

	/// When `true`, the field uses `HCColor.Structure.cardBackground` inside the border’s rounded shape.
	open var showsCardBackground: Bool = false {
		didSet {
			borderView.showsBackground = showsCardBackground
			updateCardBackgroundColor()
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

		installBorderTapToFocus()
		updateTextField()
		updateAppearance()
		updateContentView()
	}

	/// Makes taps anywhere in the bordered field area focus the text field (including padding and icons).
	private func installBorderTapToFocus() {
		borderView.isUserInteractionEnabled = true

		let tap = UITapGestureRecognizer(target: self, action: #selector(borderedAreaTapped))
		tap.cancelsTouchesInView = false
		borderView.addGestureRecognizer(tap)

		for case let scrollView as UIScrollView in borderView.subviews {
			let scrollTap = UITapGestureRecognizer(target: self, action: #selector(borderedAreaTapped))
			scrollTap.cancelsTouchesInView = false
			scrollView.addGestureRecognizer(scrollTap)
		}
	}

	@objc private func borderedAreaTapped() {
		guard !textField.isFirstResponder else { return }
		_ = textField.becomeFirstResponder()
	}

	public override func becomeFirstResponder() -> Bool {
		textField.becomeFirstResponder()
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
		updateCardBackgroundColor(isDark: collection.isDark)
		updateAppearance()

		super.applyThemeCollection(theme: theme, collection: collection, event: event)

		backgroundColor = .clear
	}

	private func updateCardBackgroundColor(isDark: Bool? = nil) {
		guard showsCardBackground else {
			borderView.backgroundFillColor = nil
			return
		}
		let isDark = isDark ?? Theme.shared.activeCollection.isDark
		borderView.backgroundFillColor = HCColor.Structure.cardBackground(isDark)
		borderView.showsBackground = true
	}

	/// With card background, only show the border while focused or in an error state.
	private func applyCardBackgroundBorderStyle() {
		guard showsCardBackground else { return }
		let hasError = errorText != nil
		if hasError || isActive {
			return
		}
		borderView.borderWidth = 0
		borderView.borderColor = .clear
	}

	public override func updateAppearance() {
		super.updateAppearance()
		applyCardBackgroundBorderStyle()

		if let leftIcon {
			if let leftIconTintColor {
				iconView.image = leftIcon.withRenderingMode(.alwaysTemplate)
				iconView.tintColor = leftIconTintColor
			} else {
				iconView.image = leftIcon
				iconView.tintColor = nil
			}
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
		textField.sendActions(for: .editingChanged)
		NotificationCenter.default.post(name: UITextField.textDidChangeNotification, object: textField)
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
