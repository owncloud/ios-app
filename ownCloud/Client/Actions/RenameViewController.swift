//
//  RenameViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 02/08/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

class RenameViewController: UIViewController {

	weak var itemToRename: OCItem?
	weak var core: OCCore?
	var completion: (String) -> Void

	private var blurView: UIVisualEffectView

	private var stackView: UIStackView

	private var thumbnailContainer: UIView
	private var thumbnailImageView: UIImageView

	private var nameContainer: UIView
	private var nameTextField: UITextField

	private var textfieldTopAnchorConstraint: NSLayoutConstraint
	private var textfieldCenterYAnchorConstraint: NSLayoutConstraint
	private var thumbnailContainerWidthAnchorConstraint: NSLayoutConstraint
	private var thumbnailHeightAnchorConstraint: NSLayoutConstraint

	private var stackViewLeftAnchorConstraint: NSLayoutConstraint?
	private var stackviewRightAnchorConstraint: NSLayoutConstraint?

	private let thumbnailSize = CGSize(width: 150.0, height: 150.0)

	init(with item: OCItem? = nil, core: OCCore? = nil, completion: @escaping (String) -> Void) {
		self.itemToRename = item
		self.core = core
		self.completion = completion

		blurView = UIVisualEffectView.init(effect: UIBlurEffect(style: .regular))

		stackView = UIStackView(frame: .zero)

		thumbnailContainer = UIView(frame: .zero)
		thumbnailImageView = UIImageView(frame: .zero)

		nameContainer = UIView(frame: .zero)
		nameTextField = UITextField(frame: .zero)

		textfieldCenterYAnchorConstraint = nameTextField.centerYAnchor.constraint(equalTo: nameContainer.centerYAnchor)
		textfieldTopAnchorConstraint = nameTextField.topAnchor.constraint(equalTo: nameContainer.topAnchor, constant: 15)
		thumbnailContainerWidthAnchorConstraint = thumbnailContainer.widthAnchor.constraint(equalToConstant: 200)
		thumbnailContainerWidthAnchorConstraint.priority = .init(999)
		thumbnailHeightAnchorConstraint = thumbnailImageView.heightAnchor.constraint(equalToConstant: 150)

		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
        super.viewDidLoad()

		stackViewLeftAnchorConstraint = stackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0)
		stackviewRightAnchorConstraint = stackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0)

		if let item = itemToRename {
			nameTextField.text = item.name
			thumbnailImageView.image = item.icon(fitInSize: thumbnailSize)

			if item.thumbnailAvailability != .none {
				let displayThumbnail = { (thumbnail: OCItemThumbnail?) in
					_ = thumbnail?.requestImage(for: self.thumbnailSize, scale: 0, withCompletionHandler: { (thumbnail, error, _, image) in
						if error == nil,
							image != nil,
							item.itemVersionIdentifier == thumbnail?.itemVersionIdentifier {
							OnMainThread {
								self.thumbnailImageView.image = image
							}
						}
					})
				}

				_ = core!.retrieveThumbnail(for: item, maximumSize: self.thumbnailSize, scale: 0, retrieveHandler: { (error, _, _, thumbnail, _, progress) in
					displayThumbnail(thumbnail)
				})
			}

		} else {
			nameTextField.text = "Unknown folder".localized
			thumbnailImageView.image = Theme.shared.image(for: "folder", size: thumbnailSize)
		}

		// Navigation buttons
		let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
		navigationItem.leftBarButtonItem = cancelButton

		let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
		navigationItem.rightBarButtonItem = doneButton

		//Blur View
		blurView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(blurView)
		NSLayoutConstraint.activate([
			blurView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			blurView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
			blurView.leftAnchor.constraint(equalTo: view.leftAnchor),
			blurView.rightAnchor.constraint(equalTo: view.rightAnchor)
		])

		// Thumbnail image view
		thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
		thumbnailContainer.addSubview(thumbnailImageView)
		NSLayoutConstraint.activate([
			thumbnailHeightAnchorConstraint,
			thumbnailImageView.widthAnchor.constraint(equalTo: thumbnailImageView.heightAnchor),
			thumbnailImageView.centerXAnchor.constraint(equalTo: thumbnailContainer.centerXAnchor),
			thumbnailImageView.centerYAnchor.constraint(equalTo: thumbnailContainer.centerYAnchor)
		])

		// Thumbnail container View
		thumbnailContainer.translatesAutoresizingMaskIntoConstraints = false
		stackView.addArrangedSubview(thumbnailContainer)

		// Name textfield
		nameTextField.translatesAutoresizingMaskIntoConstraints = false
		nameContainer.addSubview(nameTextField)
		NSLayoutConstraint.activate([
			nameTextField.heightAnchor.constraint(equalToConstant: 40),
			nameTextField.leftAnchor.constraint(equalTo: nameContainer.leftAnchor, constant: 30),
			nameTextField.rightAnchor.constraint(equalTo: nameContainer.rightAnchor, constant: -20)
		])

		nameTextField.backgroundColor = .white
		nameTextField.delegate = self
		nameTextField.textAlignment = .center
		nameTextField.becomeFirstResponder()

		// Name container view
		nameContainer.translatesAutoresizingMaskIntoConstraints = false
		stackView.addArrangedSubview(nameContainer)

		// Stack View
		stackView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(stackView)
		NSLayoutConstraint.activate([
			stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
			stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
			stackViewLeftAnchorConstraint!,
			stackviewRightAnchorConstraint!
		])
		render(newTraitCollection: traitCollection)
		stackView.alignment = .fill
    }

	private func render(newTraitCollection: UITraitCollection) {

		switch (newTraitCollection.horizontalSizeClass, newTraitCollection.verticalSizeClass) {
		case (.compact, .regular):
			stackViewLeftAnchorConstraint?.constant = 0
			stackviewRightAnchorConstraint?.constant = 0

			NSLayoutConstraint.deactivate([
				textfieldCenterYAnchorConstraint,
				thumbnailContainerWidthAnchorConstraint
				])

			NSLayoutConstraint.activate([
				textfieldTopAnchorConstraint
				])

			stackView.axis = .vertical
			stackView.distribution = .fillEqually

		default:

			NSLayoutConstraint.deactivate([
				textfieldTopAnchorConstraint
				])

			NSLayoutConstraint.activate([
				textfieldCenterYAnchorConstraint,
				thumbnailContainerWidthAnchorConstraint
				])
			stackView.axis = .horizontal
			stackView.distribution = .fill
		}

		switch (newTraitCollection.horizontalSizeClass, newTraitCollection.verticalSizeClass) {
		case (.regular, .regular):
			stackViewLeftAnchorConstraint?.constant = 100
			stackviewRightAnchorConstraint?.constant = -100
			thumbnailHeightAnchorConstraint.constant = 150

		case (.compact, .compact):
			thumbnailHeightAnchorConstraint.constant = 100
			stackViewLeftAnchorConstraint?.constant = 0
			stackviewRightAnchorConstraint?.constant = 0

		default:
			stackViewLeftAnchorConstraint?.constant = 0
			stackviewRightAnchorConstraint?.constant = 0
			thumbnailHeightAnchorConstraint.constant = 150
		}

		// Non 3.0 scale displays
		if UIScreen.main.scale < 3.0 {
			thumbnailHeightAnchorConstraint.constant = 100
		}
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		render(newTraitCollection: traitCollection)
	}

	@objc private func cancelButtonPressed() {
		nameTextField.resignFirstResponder()
		self.dismiss(animated: true)
	}

	@objc private func doneButtonPressed() {
		self.dismiss(animated: true) {
			self.completion(self.nameTextField.text!)
		}
	}
}

extension RenameViewController: UITextFieldDelegate {

	func textFieldDidBeginEditing(_ textField: UITextField) {
		if let name = nameTextField.text,
			let fileExtension = name.fileExtension(),
			let range = name.range(of: fileExtension),
			let position: UITextPosition = nameTextField.position(from: nameTextField.beginningOfDocument, offset: range.lowerBound.encodedOffset - 1) {

				textField.selectedTextRange = nameTextField.textRange(from: nameTextField.beginningOfDocument, to:position)

		} else {
			textField.selectedTextRange = nameTextField.textRange(from: nameTextField.beginningOfDocument, to: nameTextField.endOfDocument)
		}

	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		doneButtonPressed()
		return true
	}
}
