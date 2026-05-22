//
//  HCTagSelectFieldView.swift
//  ownCloudAppShared
//
//  Copyright © 2025 ownCloud GmbH. All rights reserved.
//

import UIKit
import SnapKit

private enum Constants {
	static let maxDropdownHeight: CGFloat = 240
	static let dropdownInset: CGFloat = 8
}

/// Editable text field with an anchored dropdown card (similar placement to `HCDropdownTextFieldView`), hosting a `UITableView` owned by the parent.
public final class HCTagSelectFieldView: UIView {
	public let textFieldView = HCTextFieldView(frame: .zero)
	public let optionsTableView: UITableView = {
		let tv = UITableView(frame: .zero, style: .plain)
		tv.separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
		tv.keyboardDismissMode = .none
		tv.rowHeight = UITableView.automaticDimension
		tv.estimatedRowHeight = 48
		tv.backgroundColor = .clear
		return tv
	}()

	public weak var dropdownHostView: UIView?

	public var onSearchTextChanged: (() -> Void)?
	public var onEditingBegan: (() -> Void)?

	private let dropdownCard = HCCardView(frame: .zero)
	private var dropdownHeightConstraint: Constraint?
	private weak var installedHostView: UIView?
	private var outsideTapRecognizer: UITapGestureRecognizer?
	private var isExpanded = false
	private var keyboardFrameInHostView: CGRect = .zero

	public override init(frame: CGRect) {
		super.init(frame: frame)
		clipsToBounds = false

		textFieldView.textField.delegate = self
		textFieldView.textField.addTarget(self, action: #selector(textDidChange), for: UIControl.Event.editingChanged)
		installKeyboardObservers()

		dropdownCard.showsShadow = true
		dropdownCard.isHidden = true
		dropdownCard.alpha = 0
		dropdownCard.addSubview(optionsTableView)
		optionsTableView.snp.makeConstraints { make in
			make.edges.equalToSuperview().inset(Constants.dropdownInset)
		}

		addSubview(textFieldView)
		textFieldView.snp.makeConstraints {
			$0.edges.equalToSuperview()
		}
	}

	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
	}

	public func expandDropdownIfNeeded() {
		guard !isExpanded else { return }
		expandDropdown()
	}

	public func collapseDropdown() {
		if isExpanded {
			collapseDropdownInternal(dismissKeyboard: true)
		} else {
			textFieldView.textField.resignFirstResponder()
		}
	}

	public func reloadOptions() {
		optionsTableView.reloadData()
		updateDropdownHeight()
	}

	private func isAncestor(_ ancestor: UIView, of view: UIView) -> Bool {
		var v: UIView? = view
		while let current = v {
			if current === ancestor { return true }
			v = current.superview
		}
		return false
	}

	private func expandDropdown() {
		guard isExpanded == false else { return }
		guard let hostView = dropdownHostView else { return }
		guard isAncestor(hostView, of: textFieldView.borderView) else { return }

		isExpanded = true
		hostView.addSubview(dropdownCard)
		dropdownCard.snp.remakeConstraints { make in
			make.top.equalTo(textFieldView.borderView.snp.bottom).offset(4)
			make.leading.equalTo(textFieldView.borderView.snp.leading)
			make.trailing.equalTo(textFieldView.borderView.snp.trailing)
			dropdownHeightConstraint = make.height.equalTo(0).constraint
		}
		installedHostView = hostView
		updateDropdownHeight()
		dropdownCard.isHidden = false
		UIView.animate(withDuration: 0.2) {
			self.dropdownCard.alpha = 1
		}
		installOutsideTapRecognizer()
	}

	private func collapseDropdownInternal(dismissKeyboard: Bool = true) {
		guard isExpanded else { return }
		isExpanded = false
		if dismissKeyboard {
			textFieldView.textField.resignFirstResponder()
		}
		UIView.animate(withDuration: 0.2, animations: {
			self.dropdownCard.alpha = 0
		}) { _ in
			self.dropdownCard.isHidden = true
			self.dropdownCard.removeFromSuperview()
			self.installedHostView = nil
		}
		removeOutsideTapRecognizer()
	}

	private func installKeyboardObservers() {
		let center = NotificationCenter.default
		center.addObserver(
			self,
			selector: #selector(keyboardFrameDidChange(_:)),
			name: UIResponder.keyboardWillShowNotification,
			object: nil
		)
		center.addObserver(
			self,
			selector: #selector(keyboardFrameDidChange(_:)),
			name: UIResponder.keyboardWillChangeFrameNotification,
			object: nil
		)
		center.addObserver(
			self,
			selector: #selector(keyboardWillHide(_:)),
			name: UIResponder.keyboardWillHideNotification,
			object: nil
		)
	}

	@objc private func keyboardFrameDidChange(_ notification: Notification) {
		updateKeyboardFrame(from: notification)
		if isExpanded {
			updateDropdownHeight()
		}
	}

	@objc private func keyboardWillHide(_ notification: Notification) {
		keyboardFrameInHostView = .zero
		if isExpanded {
			updateDropdownHeight()
		}
	}

	private func updateKeyboardFrame(from notification: Notification) {
		guard let hostView = installedHostView ?? dropdownHostView,
		      let frameValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
			return
		}
		let screenFrame = frameValue.cgRectValue
		if let window = hostView.window {
			keyboardFrameInHostView = hostView.convert(screenFrame, from: window)
		} else {
			keyboardFrameInHostView = hostView.convert(screenFrame, from: UIScreen.main.coordinateSpace)
		}
	}

	private func availableDropdownMaxHeight(in hostView: UIView) -> CGFloat {
		let anchorRect = textFieldView.borderView.convert(textFieldView.borderView.bounds, to: hostView)
		let dropdownTop = anchorRect.maxY + 4
		var availableBottom = hostView.bounds.maxY - hostView.safeAreaInsets.bottom

		if keyboardFrameInHostView.height > 0 {
			let keyboardTop = keyboardFrameInHostView.minY
			if keyboardTop > dropdownTop {
				availableBottom = min(availableBottom, keyboardTop - 8)
			}
		}

		return max(availableBottom - dropdownTop, 48)
	}

	private func updateDropdownHeight() {
		guard isExpanded, let hostView = installedHostView else { return }

		optionsTableView.layoutIfNeeded()
		let contentHeight = optionsTableView.contentSize.height + Constants.dropdownInset * 2
		let maxAvailable = min(Constants.maxDropdownHeight, availableDropdownMaxHeight(in: hostView))
		let height = min(max(contentHeight, 1), maxAvailable)
		optionsTableView.isScrollEnabled = contentHeight > height + 0.5
		dropdownHeightConstraint?.update(offset: height)
		installedHostView?.layoutIfNeeded()
	}

	private func installOutsideTapRecognizer() {
		guard outsideTapRecognizer == nil else { return }
		let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleOutsideTap(_:)))
		recognizer.cancelsTouchesInView = false
		outsideTapRecognizer = recognizer
		installedHostView?.addGestureRecognizer(recognizer)
	}

	private func removeOutsideTapRecognizer() {
		if let recognizer = outsideTapRecognizer {
			installedHostView?.removeGestureRecognizer(recognizer)
			outsideTapRecognizer = nil
		}
	}

	@objc private func handleOutsideTap(_ recognizer: UITapGestureRecognizer) {
		guard recognizer.state == .ended else { return }
		guard let hostView = installedHostView else { return }
		let location = recognizer.location(in: hostView)
		let inDropdown = dropdownCard.frame.contains(location)
		let anchorRect = textFieldView.borderView.convert(textFieldView.borderView.bounds, to: hostView)
		let inAnchor = anchorRect.contains(location)
		if inDropdown || inAnchor {
			return
		}
		if isExpanded {
			collapseDropdownInternal(dismissKeyboard: true)
		} else if textFieldView.textField.isFirstResponder {
			textFieldView.textField.resignFirstResponder()
		}
	}

	@objc private func textDidChange() {
		onSearchTextChanged?()
	}
}

extension HCTagSelectFieldView: UITextFieldDelegate {
	public func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		onEditingBegan?()
		expandDropdown()
		return true
	}

	public func textFieldDidBeginEditing(_ textField: UITextField) {
		if !isExpanded {
			expandDropdown()
		} else {
			updateDropdownHeight()
		}
	}

	public func textFieldDidEndEditing(_ textField: UITextField) {
		collapseDropdownInternal(dismissKeyboard: false)
	}
}
