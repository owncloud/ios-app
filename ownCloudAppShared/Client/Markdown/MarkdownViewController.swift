//
//  MarkdownViewController.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 25.02.25.
//  Copyright © 2025 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2025, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK
import Down

open class MarkdownViewController: UIViewController {
	public typealias CompletionHandler = (_ canceled: Bool, _ markdownText: String?) -> Void

	let editorView: UITextView = ThemeableTextView()
	let previewView: UITextView = ThemeableTextView()
	let topBar: ThemeCSSView = ThemeCSSView()

	let editorFont = UIFont.monospacedSystemFont(ofSize: UIFont.systemFontSize * 1.2, weight: .regular)
	let displayFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)

	var markdownText: String {
		didSet {
			updatePreview()
		}
	}
	var allowEditing: Bool
	var completionHandler: CompletionHandler?

	public init(markdownText: String? = nil, title: String? = nil, allowEditing: Bool = true, completionHandler: CompletionHandler? = nil) {
		self.markdownText = markdownText ?? ""
		self.allowEditing = allowEditing

		super.init(nibName: nil, bundle: nil)

		self.completionHandler = completionHandler
		self.title = title ?? "Markdown"
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override open func loadView() {
		let rootView = ThemeCSSView(withSelectors: [.modal, .secondary])
		let containerView = ThemeCSSView()
		let markdownLabel = ThemeCSSLabel()
		let previewLabel = ThemeCSSLabel()

		topBar.translatesAutoresizingMaskIntoConstraints = false
		markdownLabel.translatesAutoresizingMaskIntoConstraints = false
		previewLabel.translatesAutoresizingMaskIntoConstraints = false
		previewView.translatesAutoresizingMaskIntoConstraints = false
		editorView.translatesAutoresizingMaskIntoConstraints = false
		containerView.translatesAutoresizingMaskIntoConstraints = false

		topBar.addSubview(markdownLabel)
		topBar.addSubview(previewLabel)

		if allowEditing {
			containerView.addSubview(topBar)
			containerView.addSubview(editorView)
		}
		containerView.addSubview(previewView)

		editorView.font = editorFont
		editorView.text = markdownText
		editorView.isEditable = true
		editorView.allowsEditingTextAttributes = false
		editorView.delegate = self

		editorView.cssSelectors = [ .primary ]
		previewView.cssSelectors = [ .primary ]

		previewView.font = displayFont
		previewView.isEditable = false
		updatePreview()

		markdownLabel.font = .systemFont(ofSize: UIFont.smallSystemFontSize)
		previewLabel.font = markdownLabel.font

		markdownLabel.text = OCLocalizedString("Markdown", nil)
		previewLabel.text = OCLocalizedString("Preview", nil)

		if allowEditing {
			NSLayoutConstraint.activate([
				topBar.topAnchor.constraint(equalTo: containerView.topAnchor),
				topBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
				topBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

				markdownLabel.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 8),
				markdownLabel.topAnchor.constraint(equalTo: topBar.topAnchor, constant: 5),
				markdownLabel.bottomAnchor.constraint(equalTo: topBar.bottomAnchor, constant: -5),

				previewLabel.leadingAnchor.constraint(equalTo: topBar.centerXAnchor, constant: 8),
				previewLabel.topAnchor.constraint(equalTo: topBar.topAnchor, constant: 5),
				previewLabel.bottomAnchor.constraint(equalTo: topBar.bottomAnchor, constant: -5),

				previewView.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 0),
				previewView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
				previewView.leadingAnchor.constraint(equalTo: containerView.centerXAnchor, constant: 1),
				previewView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

				editorView.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 0),
				editorView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
				editorView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
				editorView.trailingAnchor.constraint(equalTo: containerView.centerXAnchor, constant: -1)
			])
		} else {
			containerView.embed(toFillWith: previewView)
		}

		rootView.embed(toFillWith: containerView, enclosingAnchors: rootView.safeAreaWithKeyboardAnchorSet)
		view = rootView
	}

	open override func viewDidLoad() {
		super.viewDidLoad()
		navigationItem.title = self.title

		let closeButtonItem = UIBarButtonItem(systemItem: allowEditing ? .cancel : .close, primaryAction: UIAction(handler: { [weak self] _ in
			self?.close(withSaving: false)
		}))

		if allowEditing {
			navigationItem.leftBarButtonItem = closeButtonItem
			navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .save, primaryAction: UIAction(handler: { [weak self] _ in
				self?.close(withSaving: true)
			}))
		} else {
			navigationItem.rightBarButtonItem = closeButtonItem
			editorView.removeFromSuperview()
		}
	}

	func updatePreview() {
		renderNewMarkdown(markdownText)
	}

	func renderNewMarkdown(_ markdown: String) {
		let down = Down(markdownString: markdown)
		let stylerConfiguration = DownStylerConfiguration(colors: StaticColorCollection.dynamicColors)
		let styler = DownStyler(configuration: stylerConfiguration)

		if let attributedString = try? down.toAttributedString(.default, styler: styler) {
			previewView.attributedText = attributedString
		}
	}

	func close(withSaving: Bool) {
		let markdownText = self.markdownText
		let completionHandler = self.completionHandler
		self.completionHandler = nil

		dismiss(animated: true, completion: {
			if withSaving {
				completionHandler?(false, markdownText)
			} else {
				completionHandler?(true, nil)
			}
		})
	}
}

// MARK: - UITextViewDelegate
extension MarkdownViewController: UITextViewDelegate {
	public func textViewDidChange(_ textView: UITextView) {
		if textView == editorView {
			markdownText = editorView.text
		}
	}

	@available(iOSApplicationExtension 17.0, *)
	public func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
		switch textItem.content {
			case .link(url: _):
				// Handle opening links
				return nil

			default: break
		}

		return defaultAction
	}
}

// MARK: - Markdown color collection
extension StaticColorCollection {
	public static let dynamicColors: StaticColorCollection = {
		return StaticColorCollection(
			heading1: .label,
			heading2: .label,
			heading3: .label,
			heading4: .label,
			heading5: .label,
			heading6: .label,
			body: .label,
			code: .label,
			link: .blue,
			quote: .secondaryLabel,
			quoteStripe: .secondaryLabel,
			thematicBreak: .quaternaryLabel,
			listItemPrefix:.tertiaryLabel,
			codeBlockBackground: .secondarySystemGroupedBackground)
	}()
}
