//
//  ByteCountEditView.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 07.01.25.
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

open class ByteCountUnit: NSObject {
	final let byteCount: UInt64
	final let label: String

	// Sizes as per https://en.wikipedia.org/wiki/Byte#Multiple-byte_units
	static let unitBase: UInt64 = 1000
	static public let bytes: ByteCountUnit = ByteCountUnit(byteCount: 1, label: OCLocalizedString("Bytes", nil))
	static public let kiloBytes: ByteCountUnit  = ByteCountUnit(byteCount: unitBase, label: OCLocalizedString("KB", nil))
	static public let megaBytes: ByteCountUnit  = ByteCountUnit(byteCount: unitBase * unitBase, label: OCLocalizedString("MB", nil))
	static public let gigaBytes: ByteCountUnit  = ByteCountUnit(byteCount: unitBase * unitBase * unitBase, label: OCLocalizedString("GB", nil))
	static public let terraBytes: ByteCountUnit = ByteCountUnit(byteCount: unitBase * unitBase * unitBase * unitBase, label: OCLocalizedString("TB", nil))
	static public let petaBytes: ByteCountUnit  = ByteCountUnit(byteCount: unitBase * unitBase * unitBase * unitBase * unitBase, label: OCLocalizedString("PB", nil))

	static public let all: [ByteCountUnit] = [bytes, kiloBytes, megaBytes, gigaBytes, terraBytes, petaBytes]
	static public let largest: ByteCountUnit = petaBytes

	static func forByteCount(_ byteCount: UInt64) -> ByteCountUnit {
		var lastUnit: ByteCountUnit?

		if byteCount > largest.byteCount {
			return largest
		}

		for unit in all {
			if byteCount >= unit.byteCount {
				lastUnit = unit
			}
		}

		return lastUnit ?? .bytes
	}

	static var numberFormatter: NumberFormatter = {
		let formatter = NumberFormatter()
		formatter.formatterBehavior = .behavior10_4
		formatter.numberStyle = .decimal
		formatter.maximumFractionDigits = 1
		formatter.usesGroupingSeparator = true
		return formatter
	}()

	init(byteCount: UInt64, label: String) {
		self.byteCount = byteCount
		self.label = label
	}

	public func unitCountFor(numberOfBytes: UInt64) -> Double {
		return Double(numberOfBytes) / Double(byteCount)
	}

	public func stringFor(numberOfBytes: UInt64, includingUnit: Bool = false) -> String {
		return ByteCountUnit.numberFormatter.string(from: NSNumber(value: unitCountFor(numberOfBytes: numberOfBytes))) ?? "?" + (includingUnit ? " \(label)" : "")
	}

	public func numberOfBytesFor(string: String) -> UInt64? {
		if let number = ByteCountUnit.numberFormatter.number(from: string) {
			return UInt64(number.doubleValue * Double(byteCount))
		}
		return nil
	}

	open override var hash: Int {
		return byteCount.hashValue ^ label.hashValue
	}

	open override func isEqual(_ object: Any?) -> Bool {
		guard let otherByteCount = object as? ByteCountUnit else {
			return false
		}
		return otherByteCount.byteCount == byteCount && otherByteCount.label == label
	}
}

open class ByteCountEditView: UIView {
	var textField: ThemeCSSTextField
	var unitPopupButton: PopupButtonController

	open var byteCount: UInt64 = 0 {
		didSet {
			NSLog("New byteCount: \(byteCount)")
		}
	}
	private var byteCountString: String {
		return NumberFormatter.localizedString(from: NSNumber(value: byteCount), number: .decimal)
	}

	public init(withByteCount initialByteCount: UInt64?) {
		var choices: [PopupButtonChoice] = []

		for byteCountUnit in ByteCountUnit.all {
			choices.append(PopupButtonChoice(with: byteCountUnit.label, image: nil, representedObject: byteCountUnit))
		}

		textField = ThemeCSSTextField.formField(withPlaceholder: "")
		textField.textAlignment = .right
		textField.clearButtonMode = .never
		unitPopupButton = PopupButtonController(with: choices)

		super.init(frame: .zero)

		translatesAutoresizingMaskIntoConstraints = false

		textField.text = byteCountString
		textField.delegate = self

		unitPopupButton.choiceHandler = { [weak self] choice, wasSelected in
			if let byteCountUnit = choice.representedObject as? ByteCountUnit {
				self?.switchTo(unit: byteCountUnit)
			}
		}

		embedHorizontally(views: [textField, unitPopupButton.button], insets: NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0), limitHeight: true, spacingProvider: { leadingView, trailingView in
			return 5
		})

		if let initialByteCount {
			set(byteCount: initialByteCount)
		}
	}

	required public init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	var unit: ByteCountUnit?

	func set(byteCount: UInt64, updateTextField: Bool = true) {
		self.byteCount = byteCount

		if updateTextField {
			unit = ByteCountUnit.forByteCount(byteCount)
			if let choice = unitPopupButton.choices?.first(where: { $0.representedObject as? ByteCountUnit == unit }) {
				unitPopupButton.selectedChoice = choice
			}
			textField.text = unit?.stringFor(numberOfBytes: byteCount)
		}
	}

	func switchTo(unit: ByteCountUnit?) {
		self.unit = unit
		if !textField.isFirstResponder, let unit {
			// Textfield is not in use => convert byteCount
			textField.text = unit.stringFor(numberOfBytes: byteCount)
		} else if let unit, let text = textField.text, let newByteCount = unit.numberOfBytesFor(string: text) {
			// Textfield is in use => just change unit
			byteCount = newByteCount
		}
	}
}

extension ByteCountEditView: UITextFieldDelegate {
	public func textFieldDidEndEditing(_ textField: UITextField) {
		guard let unit else { return }
		set(byteCount: unit.numberOfBytesFor(string: textField.text ?? "0") ?? 0)
	}

	public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
		if let text = textField.text, let charRange = Range(range, in:text) {
			let textAfterChange = text.replacingCharacters(in: charRange, with: string)

			if textAfterChange.isFormattedNumeric || textAfterChange == "" {
				if let unit, let newByteCount = unit.numberOfBytesFor(string: textAfterChange) {
					self.byteCount = newByteCount
				}
				return true
			}

			return false
		}
		return true
	}

	public func textFieldShouldClear(_ textField: UITextField) -> Bool {
		return true
	}

	open func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textField.text == "" {
			return false
		}
		return true
	}
}
