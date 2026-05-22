import UIKit

public final class HCBorderView: UIView {
	private enum Constants {
		static let cornerRadius = 20.0
		static let floatingLabelLeftOffset = 16.0
		static let floatingLabelPadding = 4.0
		static let floatingLabelFontSize = 12.0
	}

	private lazy var floatingLabel = {
		let label = UILabel()
		label.font = .systemFont(ofSize: Constants.floatingLabelFontSize)
		return label
	}()

	private lazy var backgroundLayer: CAShapeLayer = {
		let layer = CAShapeLayer()
		layer.fillColor = UIColor.clear.cgColor
		layer.isHidden = true
		return layer
	}()

	private lazy var borderLayer = {
		let layer = CAShapeLayer()
		layer.fillColor = UIColor.clear.cgColor
		return layer
	}()

	private lazy var maskLayer = {
		let layer = CAShapeLayer()
		layer.fillRule = .evenOdd
		layer.fillColor = UIColor.black.cgColor
		return layer
	}()

	public var borderColor: UIColor? = .clear {
		didSet {
			updateView()
		}
	}

	public var borderWidth: CGFloat = 3 {
		didSet {
			updateView()
		}
	}

	public var title: String? {
		set {
			floatingLabel.text = newValue
			setNeedsLayout()
		}
		get {
			floatingLabel.text
		}
	}

	public var titleColor: UIColor? = .clear {
		didSet {
			updateView()
		}
	}

	public var shouldDisplayTitle: Bool = true {
		didSet {
			updateView()
		}
	}

	/// When `true`, fills the field area with `backgroundFillColor` using the same rounded shape as the border.
	public var showsBackground: Bool = false {
		didSet {
			updateView()
		}
	}

	public var backgroundFillColor: UIColor? {
		didSet {
			updateView()
		}
	}

	override init(frame: CGRect) {
		super.init(frame: frame)

		commonInit()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)

		commonInit()
	}

	private func commonInit() {
		backgroundColor = .clear
		borderLayer.mask = maskLayer
		layer.addSublayer(backgroundLayer)
		layer.addSublayer(borderLayer)

		addSubview(floatingLabel)

		updateView()
	}

	public override func layoutSubviews() {
		super.layoutSubviews()

		backgroundLayer.frame = bounds
		borderLayer.frame = bounds
		maskLayer.frame = bounds

		floatingLabel.sizeToFit()
		floatingLabel.frame.origin = CGPoint(
			x: Constants.floatingLabelLeftOffset,
			y: -floatingLabel.bounds.height / 2
		)
		updateView()
	}

	private func updateView() {
		floatingLabel.alpha = shouldDisplayTitle ? 1.0 : 0.0
		floatingLabel.textColor = titleColor

		let roundedPath = UIBezierPath.trueRoundedRect(
			rect: bounds,
			cornerRadius: Constants.cornerRadius
		)

		if showsBackground, let backgroundFillColor {
			backgroundLayer.isHidden = false
			backgroundLayer.path = roundedPath.cgPath
			backgroundLayer.fillColor = backgroundFillColor.cgColor
		} else {
			backgroundLayer.isHidden = true
			backgroundLayer.path = nil
		}

		borderLayer.path = roundedPath.cgPath
		borderLayer.strokeColor = (borderColor ?? .clear).cgColor
		borderLayer.lineWidth = borderWidth

		let path = UIBezierPath(
			rect: borderLayer.bounds.insetBy(
				dx: -2 * borderWidth,
				dy: -2 * borderWidth
			)
		)

		if shouldDisplayTitle {
			path.append(
				UIBezierPath(
					rect: floatingLabel.frame.insetBy(dx: -Constants.floatingLabelPadding, dy: 0)
				)
			)
		}

		maskLayer.path = path.cgPath
	}
}
