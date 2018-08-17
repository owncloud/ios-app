//
//  RenameViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 02/08/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

typealias StringValidatorResult = (Bool, String?)
typealias StringValidatorHandler = (String) -> StringValidatorResult

class NamingViewController: UIViewController {

	//TODO This view controller ideally should have Theme support.

	weak var item: OCItem?
	weak var core: OCCore?
	var completion: (String?, NamingViewController) -> Void
	var stringValidator: StringValidatorHandler?
	var defaultName: String?

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
	private var stackViewRightAnchorConstraint: NSLayoutConstraint?

	private var cancelButton: UIBarButtonItem?
	private var doneButton: UIBarButtonItem?

	private let thumbnailSize = CGSize(width: 150.0, height: 150.0)

	init(with item: OCItem, core: OCCore? = nil, stringValidator: StringValidatorHandler? = nil, completion: @escaping (String?, NamingViewController) -> Void) {
		self.item = item
		self.core = core
		self.completion = completion
		self.stringValidator = stringValidator
		self.defaultName = nil

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

	init(with core: OCCore? = nil, defaultName: String, stringValidator: StringValidatorHandler? = nil, completion: @escaping (String?, NamingViewController) -> Void) {
		self.item = nil
		self.core = core
		self.completion = completion
		self.stringValidator = stringValidator
		self.defaultName = defaultName

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

	deinit {
		NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
	}

	override func viewDidLoad() {
        super.viewDidLoad()

		stackViewLeftAnchorConstraint = stackView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 0)
		stackViewRightAnchorConstraint = stackView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: 0)

		if let item = item {
			nameTextField.text = item.name
			thumbnailImageView.image = item.icon(fitInSize: thumbnailSize)

			if item.thumbnailAvailability != .none {
				_ = core!.retrieveThumbnail(for: item, maximumSize: self.thumbnailSize, scale: 0, retrieveHandler: { (error, _, _, thumbnail, _, _) in
					_ = thumbnail?.requestImage(for: self.thumbnailSize, scale: 0, withCompletionHandler: { [weak self] (thumbnail, error, _, image) in
						if error == nil,
							image != nil,
							item.itemVersionIdentifier == thumbnail?.itemVersionIdentifier {
							OnMainThread {
								self?.thumbnailImageView.image = image
							}
						}
					})
				})
			}
		} else {
			nameTextField.text = defaultName
			thumbnailImageView.image = Theme.shared.image(for: "folder", size: thumbnailSize)
		}

		// Navigation buttons
		cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
		navigationItem.leftBarButtonItem = cancelButton

		doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
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
		nameTextField.addTarget(self, action: #selector(textfieldDidChange(_:)), for: .editingChanged)
		nameTextField.enablesReturnKeyAutomatically = true
		nameTextField.autocorrectionType = .no

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
			stackViewRightAnchorConstraint!
		])
		render(newTraitCollection: traitCollection)
		stackView.alignment = .fill
    }

	private func render(newTraitCollection: UITraitCollection) {

		switch (newTraitCollection.horizontalSizeClass, newTraitCollection.verticalSizeClass) {
		case (.compact, .regular):
			stackViewLeftAnchorConstraint?.constant = 0
			stackViewRightAnchorConstraint?.constant = 0

			NSLayoutConstraint.deactivate([
				textfieldCenterYAnchorConstraint,
				thumbnailContainerWidthAnchorConstraint
				])

			NSLayoutConstraint.activate([
				textfieldTopAnchorConstraint
				])

			stackView.axis = .vertical
			stackView.distribution = .fillEqually
			self.stackView.transform = CGAffineTransform.identity

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
			stackViewRightAnchorConstraint?.constant = -100
			thumbnailHeightAnchorConstraint.constant = 150

			// Tweak for small PPI devices
			if UIDevice.current.userInterfaceIdiom == .phone && UIScreen.main.nativeBounds.height == 1136 {
				thumbnailHeightAnchorConstraint.constant = 100
			}

		case (.compact, .compact):
			thumbnailHeightAnchorConstraint.constant = 100
			stackViewLeftAnchorConstraint?.constant = 0
			stackViewRightAnchorConstraint?.constant = 0

			// Tweak for small PPI devices
			if UIDevice.current.userInterfaceIdiom == .phone && UIScreen.main.nativeBounds.height == 1136 {
				thumbnailHeightAnchorConstraint.constant = 80
			}

		default:
			stackViewLeftAnchorConstraint?.constant = 0
			stackViewRightAnchorConstraint?.constant = 0
			thumbnailHeightAnchorConstraint.constant = 150

			// Tweak for small PPI devices
			if UIDevice.current.userInterfaceIdiom == .phone && UIScreen.main.nativeBounds.height == 1136 {
				thumbnailHeightAnchorConstraint.constant = 100
			}
		}
	}

	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		render(newTraitCollection: traitCollection)
	}

	@objc private func cancelButtonPressed() {
		nameTextField.resignFirstResponder()
		self.dismiss(animated: true) {
			self.completion(nil, self)
		}
	}

	@objc func textfieldDidChange(_ sender: UITextField) {
		if sender.text != "" {
			doneButton?.isEnabled = true
		} else {
			doneButton?.isEnabled = false
		}
	}

	@objc private func doneButtonPressed() {

		if let item = item, self.nameTextField.text == item.name {
			nameTextField.resignFirstResponder()
			self.dismiss(animated: true) {
				self.completion(nil, self)
			}
		} else {
			if let stringValidator = self.stringValidator {
				let (validationPassed, validationErrorMessage) = stringValidator(nameTextField.text!)

				if validationPassed {
					nameTextField.resignFirstResponder()
					self.dismiss(animated: true) {
						self.completion(self.nameTextField.text!, self)
					}
				} else {
					let controller = UIAlertController(title: "Forbidden Characters".localized, message: validationErrorMessage, preferredStyle: .alert)
					let okAction = UIAlertAction(title: "Ok", style: .default)
					controller.addAction(okAction)
					self.present(controller, animated: true)
				}
			} else {
				nameTextField.resignFirstResponder()
				self.dismiss(animated: true) {
					self.completion(self.nameTextField.text!, self)
				}
			}
		}
	}

	@objc func keyboardWillShow(notification: NSNotification) {
		if let keyboardSize = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
			if self.view.frame.origin.y == 0 {
				// TODO: Improve this for center the stackview with the keyboard not only when the keyboard partialy cover the thumbnailImage
				let thumbnailImageMaxY = self.view.convert(self.thumbnailImageView.frame, from:stackView).maxY
				let thumbnailTopSpace = self.view.convert(self.thumbnailImageView.frame, from:stackView).minY - self.navigationController!.navigationBar.frame.maxY
				let keyboardY = self.view.frame.height - keyboardSize.height
				let firstYTranslation = thumbnailImageMaxY  - (keyboardY)
				let finalYTranslation = firstYTranslation + ((thumbnailTopSpace - firstYTranslation) / 2)

				// if the keyboard is above the thumbnailView
				if thumbnailImageMaxY >= keyboardY {
					let animation = UIViewPropertyAnimator(duration: 0.7, dampingRatio: 1.0) {
						self.stackView.transform = CGAffineTransform.init(translationX: 0, y: -(finalYTranslation))
					}
					animation.startAnimation()
				}
			}
		}
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
	}

}

extension NamingViewController: UITextFieldDelegate {

	func textFieldDidBeginEditing(_ textField: UITextField) {

		if let name = nameTextField.text,
			let fileExtension = item?.fileSuffix(),
			let range = name.range(of: fileExtension),
			let position: UITextPosition = nameTextField.position(from: nameTextField.beginningOfDocument, offset: range.lowerBound.encodedOffset - 1) {

				textField.selectedTextRange = nameTextField.textRange(from: nameTextField.beginningOfDocument, to:position)

		} else {
			textField.selectedTextRange = nameTextField.textRange(from: nameTextField.beginningOfDocument, to: nameTextField.endOfDocument)
		}

	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textField.text == "" {
			return false
		}
		doneButtonPressed()
		return true
	}
}
