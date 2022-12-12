//
//  ComposedMessageView.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 20.09.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

public class ComposedMessageElement: NSObject {
	public enum Kind {
		case title
		case subtitle
		case text
		case image(image: UIImage?, imageSize: CGSize?, adaptSizeToRatio: Bool)
		case divider
		case progressBar(progress: Progress? = nil, relativeWidth: CGFloat = 1.0)
		case progressCircle(progress: Progress? = nil)
		case activityIndicator(style: UIActivityIndicatorView.Style = .medium, size: CGSize)
		case spacing(size: CGFloat)
	}

	public enum Alignment {
		case leading
		case trailing
		case centered
	}

	public var kind: Kind
	public var alignment: Alignment

	public var text: String?
	public var font: UIFont?
	public var style: ThemeItemStyle?
	public var textView: UILabel?

	public var imageView: UIImageView?

	public var progress: Progress?
	public var progressBar: UIProgressView?

	public var activityIndicatorView: UIActivityIndicatorView?

	public var insets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)

	private var _view: UIView?
	public var view: UIView? {
		if _view == nil {
			switch kind {
				case .title, .subtitle, .text:
					textView = UILabel()
					textView?.translatesAutoresizingMaskIntoConstraints = false
					textView?.numberOfLines = 0

					switch alignment {
						case .leading:	textView?.textAlignment = .left
						case .trailing:	textView?.textAlignment = .right
						case .centered:	textView?.textAlignment = .center
					}

					textView?.text = text
					textView?.setContentCompressionResistancePriority(.required, for: .vertical)
					textView?.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
					textView?.setContentHuggingPriority(.required, for: .vertical)

					add(applier: { [weak self] theme, collection, event in
						if let self = self, let style = self.style, let label = self.textView {
							label.applyThemeCollection(collection, itemStyle: style, itemState: .normal)
						}
					})

					_view = textView

				case .image(let image, let imageSize, let adaptSizeToRatio):
					imageView = UIImageView(image: image)
					imageView?.contentMode = .scaleAspectFit
					imageView?.translatesAutoresizingMaskIntoConstraints = false

					let rootView = UIView()
					rootView.translatesAutoresizingMaskIntoConstraints = false
					rootView.addSubview(imageView!)

					var constraints: [NSLayoutConstraint] = [
						imageView!.topAnchor.constraint(equalTo: rootView.topAnchor),
						imageView!.bottomAnchor.constraint(equalTo: rootView.bottomAnchor)
					]

					var renderImageSize = imageSize

					if adaptSizeToRatio, let imageSize = imageSize, let image = image {
						let ratioSize = image.size

						if imageSize.width == 0 {
							renderImageSize?.width = ratioSize.height * ratioSize.width / imageSize.height

						} else if imageSize.height == 0 {
							renderImageSize?.width = ratioSize.width * ratioSize.height / imageSize.width
						}
					}

					if let imageSize = renderImageSize {
						if imageSize.width != 0 {
							constraints.append(imageView!.widthAnchor.constraint(equalToConstant: imageSize.width))
						}
						if imageSize.height != 0 {
							constraints.append(imageView!.heightAnchor.constraint(equalToConstant: imageSize.height))
						}
					}

					switch alignment {
						case .leading:
							constraints.append(contentsOf: [
								imageView!.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
								imageView!.trailingAnchor.constraint(lessThanOrEqualTo: rootView.trailingAnchor)
							])

						case .trailing:
							constraints.append(contentsOf: [
								imageView!.leadingAnchor.constraint(greaterThanOrEqualTo: rootView.leadingAnchor),
								imageView!.trailingAnchor.constraint(equalTo: rootView.trailingAnchor)
							])

						case .centered:
							constraints.append(contentsOf: [
								imageView!.leadingAnchor.constraint(greaterThanOrEqualTo: rootView.leadingAnchor),
								imageView!.centerXAnchor.constraint(equalTo: rootView.centerXAnchor),
								imageView!.trailingAnchor.constraint(lessThanOrEqualTo: rootView.trailingAnchor)
							])
					}

					NSLayoutConstraint.activate(constraints)

					_view = rootView

				case .divider:
					let dividerView = UIView()
					dividerView.translatesAutoresizingMaskIntoConstraints = false
					dividerView.heightAnchor.constraint(equalToConstant: 1).isActive = true
					dividerView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.2)
					_view = dividerView

				case .progressBar(let progress, let relativeWidth):
					let progressView = UIProgressView(progressViewStyle: .default)
					progressView.translatesAutoresizingMaskIntoConstraints = false
					progressView.observedProgress = progress

					let rootView = UIView()
					rootView.translatesAutoresizingMaskIntoConstraints = false
					rootView.addSubview(progressView)

					var constraints: [NSLayoutConstraint] = [
						progressView.topAnchor.constraint(equalTo: rootView.topAnchor),
						progressView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
						progressView.widthAnchor.constraint(equalTo: rootView.widthAnchor, multiplier: relativeWidth)
					]

					switch alignment {
						case .leading:
							constraints.append(contentsOf: [
								progressView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor)
							])

						case .trailing:
							constraints.append(contentsOf: [
								progressView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor)
							])

						case .centered:
							constraints.append(contentsOf: [
								progressView.centerXAnchor.constraint(equalTo: rootView.centerXAnchor)
							])
					}

					NSLayoutConstraint.activate(constraints)

					progressBar = progressView
					_view = rootView

				case .progressCircle(let progress):
					let progressView = ProgressView()
					progressView.translatesAutoresizingMaskIntoConstraints = false
					progressView.progress = progress

					let rootView = UIView()
					rootView.translatesAutoresizingMaskIntoConstraints = false
					rootView.addSubview(progressView)

					var constraints: [NSLayoutConstraint] = [
						progressView.topAnchor.constraint(equalTo: rootView.topAnchor),
						progressView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor)
					]

					switch alignment {
						case .leading:
							constraints.append(contentsOf: [
								progressView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor)
							])

						case .trailing:
							constraints.append(contentsOf: [
								progressView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor)
							])

						case .centered:
							constraints.append(contentsOf: [
								progressView.centerXAnchor.constraint(equalTo: rootView.centerXAnchor)
							])
					}

					NSLayoutConstraint.activate(constraints)

					_view = rootView

				case .activityIndicator(let style, let size):
					let activityIndicator = UIActivityIndicatorView(style: style)
					activityIndicator.translatesAutoresizingMaskIntoConstraints = false

					let rootView = UIView()
					rootView.translatesAutoresizingMaskIntoConstraints = false
					rootView.addSubview(activityIndicator)

					var constraints: [NSLayoutConstraint] = [
						activityIndicator.topAnchor.constraint(equalTo: rootView.topAnchor),
						activityIndicator.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),
						activityIndicator.widthAnchor.constraint(equalToConstant: size.width),
						activityIndicator.heightAnchor.constraint(equalToConstant: size.height)
					]

					switch alignment {
						case .leading:
							constraints.append(contentsOf: [
								activityIndicator.leadingAnchor.constraint(equalTo: rootView.leadingAnchor)
							])

						case .trailing:
							constraints.append(contentsOf: [
								activityIndicator.trailingAnchor.constraint(equalTo: rootView.trailingAnchor)
							])

						case .centered:
							constraints.append(contentsOf: [
								activityIndicator.centerXAnchor.constraint(equalTo: rootView.centerXAnchor)
							])
					}

					NSLayoutConstraint.activate(constraints)

					activityIndicatorView = activityIndicator
					_view = rootView

				case .spacing(let spacing):
					let spacingView = UIView()
					spacingView.translatesAutoresizingMaskIntoConstraints = false
					spacingView.heightAnchor.constraint(equalToConstant: spacing).isActive = true

					_view = spacingView
			}
		}

		return _view
	}

	public var elementInView: Bool = false {
		didSet {
			switch kind {
				case .activityIndicator(_, _):
					if elementInView {
						activityIndicatorView?.startAnimating()
					} else {
						activityIndicatorView?.stopAnimating()
					}

				default: break
			}
		}
	}

	private var themeAppliers : [ThemeApplier] = []
	private func add(applier: @escaping ThemeApplier) {
		themeAppliers.append(applier)
	}
	func apply(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		for applier in themeAppliers {
			applier(theme, collection, event)
		}
	}

	init(kind: Kind, alignment: Alignment, insets altInsets: NSDirectionalEdgeInsets? = nil) {
		self.kind = kind
		self.alignment = alignment
		super.init()

		if let altInsets = altInsets {
			insets = altInsets
		}
	}

	static public func title(_ title: String, alignment: Alignment = .leading, insets altInsets: NSDirectionalEdgeInsets? = nil) -> ComposedMessageElement {
		let element = ComposedMessageElement(kind: .title, alignment: alignment, insets: altInsets)
		element.text = title
		element.style = .system(textStyle: .title3, weight: .bold)

		return element
	}

	static public func subtitle(_ subtitle: String, alignment: Alignment = .leading, insets altInsets: NSDirectionalEdgeInsets? = nil) -> ComposedMessageElement {
		let element = ComposedMessageElement(kind: .subtitle, alignment: alignment, insets: altInsets)
		element.text = subtitle
		element.style = .systemSecondary(textStyle: .body, weight: nil)

		return element
	}

	static public func text(_ text: String, font: UIFont? = nil, style: ThemeItemStyle?, alignment: Alignment = .leading, insets altInsets: NSDirectionalEdgeInsets? = nil) -> ComposedMessageElement {
		let element = ComposedMessageElement(kind: .text, alignment: alignment, insets: altInsets)
		element.text = text
		element.font = font
		element.style = style

		return element
	}

	static public func image(_ image: UIImage, size: CGSize?, adaptSizeToRatio: Bool = false, alignment: Alignment = .centered, insets altInsets: NSDirectionalEdgeInsets? = nil) -> ComposedMessageElement {
		return ComposedMessageElement(kind: .image(image: image, imageSize: size, adaptSizeToRatio: adaptSizeToRatio), alignment: alignment, insets: altInsets)
	}

	static public func progressBar(with relativeWidth: CGFloat = 1.0, progress: Progress?, alignment: Alignment = .centered, insets altInsets: NSDirectionalEdgeInsets? = nil) -> ComposedMessageElement {
		let element = ComposedMessageElement(kind: .progressBar(progress: progress, relativeWidth: relativeWidth), alignment: alignment, insets: altInsets)
		element.progress = progress

		return element
	}

	static public func progressCircle(with progress: Progress, alignment: Alignment = .centered, insets altInsets: NSDirectionalEdgeInsets? = nil) -> ComposedMessageElement {
		let element = ComposedMessageElement(kind: .progressCircle(progress: progress), alignment: alignment, insets: altInsets)
		element.progress = progress

		return element
	}

	static public func activityIndicator(with alignment: Alignment = .centered, style: UIActivityIndicatorView.Style? = nil, size: CGSize = CGSize(width: 30, height: 30), insets altInsets: NSDirectionalEdgeInsets? = nil) -> ComposedMessageElement {
		let effectiveStyle = style ?? Theme.shared.activeCollection.activityIndicatorViewStyle
		return ComposedMessageElement(kind: .activityIndicator(style: effectiveStyle, size: size), alignment: alignment, insets: altInsets)
	}

	static public func spacing(_ spacing: CGFloat) -> ComposedMessageElement {
		let element = ComposedMessageElement(kind: .spacing(size: spacing), alignment: .centered)
		element.insets = .zero

		return element
	}

	public static var divider: ComposedMessageElement {
		return ComposedMessageElement(kind: .divider, alignment: .centered)
	}
}

public class ComposedMessageView: UIView, Themeable {
	open var elements: [ComposedMessageElement]?
	open var elementInsets: NSDirectionalEdgeInsets = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)

	open var backgroundInsets: NSDirectionalEdgeInsets = .zero {
		didSet {
			layoutBackgroundView()
		}
	}
	open var backgroundView: UIView? {
		willSet {
			backgroundView?.removeFromSuperview()
		}
		didSet {
			layoutBackgroundView()
		}
	}

	init(elements: [ComposedMessageElement]) {
		super.init(frame: .zero)
		self.translatesAutoresizingMaskIntoConstraints = false

		self.elements = elements
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	private var _didSetupContent: Bool = false
	public override func willMove(toSuperview newSuperview: UIView?) {
		if !_didSetupContent {
			_didSetupContent = true

			embedAndLayoutElements()

			Theme.shared.register(client: self, applyImmediately: true)
		}

		super.willMove(toSuperview: newSuperview)
	}

	public override func willMove(toWindow newWindow: UIWindow?) {
		super.willMove(toWindow: newWindow)

		guard let elements = elements else { return }

		for element in elements {
			element.elementInView = (newWindow != nil)
		}
	}

	func layoutBackgroundView() {
		if let view = backgroundView {
			view.removeFromSuperview() // Removes all constraints
			insertSubview(view, at: 0) // (Re)insert view below all other subviews

			NSLayoutConstraint.activate([
				view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: backgroundInsets.leading),
				view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -backgroundInsets.trailing),
				view.topAnchor.constraint(equalTo: topAnchor, constant: backgroundInsets.top),
				view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -backgroundInsets.bottom)
			])
		}
	}

	func embedAndLayoutElements() {
		if let elements = elements {
			var previousElement: ComposedMessageElement?
			var constraints: [NSLayoutConstraint] = []

			for element in elements {
				if let view = element.view {
					addSubview(view)

					constraints.append(contentsOf: [
						view.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: (element.insets.leading + elementInsets.leading)),
						view.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -(element.insets.trailing + elementInsets.trailing))
					])

					if let previousElement = previousElement, let previousView = previousElement.view {
						constraints.append(contentsOf: [
							view.topAnchor.constraint(equalTo: previousView.bottomAnchor, constant: element.insets.top + previousElement.insets.bottom)
						])
					} else {
						constraints.append(contentsOf: [
							view.topAnchor.constraint(equalTo: self.topAnchor, constant: (element.insets.top + elementInsets.top))
						])
					}

					previousElement = element
				}
			}

			if let previousElement = previousElement, let previousView = previousElement.view {
				constraints.append(contentsOf: [
					previousView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -(previousElement.insets.bottom + elementInsets.bottom))
				])
			}

			NSLayoutConstraint.activate(constraints)
		}
	}

	public func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		if let elements = elements {
			for element in elements {
				element.apply(theme: theme, collection: collection, event: event)
			}
		}
	}
}

public extension ComposedMessageView {
	static func infoBox(image: UIImage? = nil, title: String? = nil, subtitle: String? = nil, additionalElements: [ComposedMessageElement]? = nil) -> ComposedMessageView {
		var elements: [ComposedMessageElement] = []

		if let image = image {
			let imageElement: ComposedMessageElement = .image(image, size: CGSize(width: 48, height: 48), alignment: .centered)
			imageElement.insets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 10, trailing: 10)
			elements.append(imageElement)
		}

		if let title = title {
			elements.append(.title(title, alignment: .centered))
		}

		if let subtitle = subtitle {
			elements.append(.subtitle(subtitle, alignment: .centered))
		}

		let infoBoxView = ComposedMessageView(elements: elements)
		infoBoxView.elementInsets = NSDirectionalEdgeInsets(top: 30, leading: 20, bottom: 30, trailing: 20)
		infoBoxView.backgroundInsets = NSDirectionalEdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0)
		infoBoxView.backgroundView = RoundCornerBackgroundView(fillColorPicker: { theme, collection, event in
			return collection.tableGroupBackgroundColor
		})
		infoBoxView.translatesAutoresizingMaskIntoConstraints = false

		return infoBoxView
	}
}
