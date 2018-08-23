//
//  StaticTableViewRow.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.03.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2018, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit

typealias StaticTableViewRowAction = (_ staticRow : StaticTableViewRow, _ sender: Any?) -> Void
typealias StaticTableViewRowEventHandler = (_ staticRow : StaticTableViewRow, _ event : StaticTableViewEvent) -> Void

enum StaticTableViewRowButtonStyle {
	case plain
	case proceed
	case destructive
	case custom(textColor: UIColor?, selectedTextColor: UIColor?, backgroundColor: UIColor?, selectedBackgroundColor: UIColor?)
}

class StaticTableViewRow : NSObject, UITextFieldDelegate {

	public weak var section : StaticTableViewSection?

	public var identifier : String?
	public var groupIdentifier : String?

	public var value : Any? {
		didSet {
			if updateViewFromValue != nil {
				updateViewFromValue!(self)
			}
		}
	}

	private var updateViewFromValue : ((_ row: StaticTableViewRow) -> Void)?
	private var updateViewAppearance : ((_ row: StaticTableViewRow) -> Void)?

	public var cell : UITableViewCell?

	public var selectable : Bool = true

	public var enabled : Bool = true {
		didSet {
			if updateViewAppearance != nil {
				updateViewAppearance!(self)
			}
		}
	}

	public var action : StaticTableViewRowAction?
	public var eventHandler : StaticTableViewRowEventHandler?

	public var viewController: StaticTableViewController? {
		return section?.viewController
	}

	private var themeApplierToken : ThemeApplierToken?

	public var index : Int? {
		return section?.rows.index(of: self)
	}

	public var indexPath : IndexPath? {
		if let rowIndex = self.index, let sectionIndex = section?.index {
			return IndexPath(row: rowIndex, section: sectionIndex)
		}

		return nil
	}

	public var attached : Bool {
		return self.index != nil
	}

	override init() {
		super.init()
	}

	convenience init(rowWithAction: StaticTableViewRowAction?, title: String, accessoryType: UITableViewCellAccessoryType = UITableViewCellAccessoryType.none, identifier : String? = nil) {
		self.init()

		self.identifier = identifier

		self.cell = ThemeTableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
		self.cell?.textLabel?.text = title
		self.cell?.accessoryType = accessoryType

		self.cell?.accessibilityIdentifier = identifier

		self.action = rowWithAction
	}

	convenience init(subtitleRowWithAction: StaticTableViewRowAction?, title: String, subtitle: String? = nil, accessoryType: UITableViewCellAccessoryType = UITableViewCellAccessoryType.none, identifier : String? = nil) {
		self.init()

		self.identifier = identifier

		self.cell = ThemeTableViewCell(style: UITableViewCellStyle.subtitle, reuseIdentifier: nil)
		self.cell?.textLabel?.text = title
		self.cell?.detailTextLabel?.text = subtitle
		self.cell?.accessoryType = accessoryType

		self.cell?.accessibilityIdentifier = identifier

		self.action = subtitleRowWithAction
	}

	// MARK: - Radio Item
	convenience init(radioItemWithAction: StaticTableViewRowAction?, groupIdentifier: String, value: Any, title: String, selected: Bool, identifier : String? = nil) {
		self.init()

		self.identifier = identifier

		self.cell = ThemeTableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
		self.cell?.textLabel?.text = title

		if let accessibilityIdentifier : String = identifier {
			self.cell?.accessibilityIdentifier = groupIdentifier + "." + accessibilityIdentifier
		}

		self.groupIdentifier = groupIdentifier
		self.value = value

		if selected {
			self.cell?.accessoryType = UITableViewCellAccessoryType.checkmark
		}

		self.action = { (row, sender) in
			row.section?.setSelected(row.value!, groupIdentifier: row.groupIdentifier!)
			radioItemWithAction?(row, sender)
		}
	}

	// MARK: - Text Field
	public var textField : UITextField?

	convenience init(textFieldWithAction action: StaticTableViewRowAction?, placeholder placeholderString: String = "", value textValue: String = "", secureTextEntry : Bool = false, keyboardType: UIKeyboardType = UIKeyboardType.default, autocorrectionType: UITextAutocorrectionType = UITextAutocorrectionType.default, autocapitalizationType: UITextAutocapitalizationType = UITextAutocapitalizationType.none, enablesReturnKeyAutomatically: Bool = true, returnKeyType : UIReturnKeyType = UIReturnKeyType.default, identifier : String? = nil) {

		self.init()

		self.identifier = identifier

		self.cell = ThemeTableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
		self.cell?.selectionStyle = UITableViewCellSelectionStyle.none

		self.action = action
		self.value = textValue

		let cellTextField : UITextField = UITextField()

		cellTextField.translatesAutoresizingMaskIntoConstraints = false

		cellTextField.delegate = self
		cellTextField.placeholder = placeholderString
		cellTextField.keyboardType = keyboardType
		cellTextField.autocorrectionType = autocorrectionType
		cellTextField.isSecureTextEntry = secureTextEntry
		cellTextField.autocapitalizationType = autocapitalizationType
		cellTextField.enablesReturnKeyAutomatically = enablesReturnKeyAutomatically
		cellTextField.returnKeyType = returnKeyType
		cellTextField.text = textValue
		cellTextField.accessibilityIdentifier = identifier

		cellTextField.addTarget(self, action: #selector(textFieldContentChanged(_:)), for: UIControlEvents.editingChanged)

		if cell != nil {
			cell?.contentView.addSubview(cellTextField)
			cellTextField.leftAnchor.constraint(equalTo: (cell?.contentView.leftAnchor)!, constant:18).isActive = true
			cellTextField.rightAnchor.constraint(equalTo: (cell?.contentView.rightAnchor)!, constant:-18).isActive = true
			cellTextField.topAnchor.constraint(equalTo: (cell?.contentView.topAnchor)!, constant:14).isActive = true
			cellTextField.bottomAnchor.constraint(equalTo: (cell?.contentView.bottomAnchor)!, constant:-14).isActive = true
		}

		self.updateViewFromValue = { [weak cellTextField] (row) in
			cellTextField?.text = row.value as? String
		}

		self.updateViewAppearance = { [weak cellTextField] (row) in
			cellTextField?.isEnabled = row.enabled
			cellTextField?.textColor = row.enabled ? Theme.shared.activeCollection.tableRowColors.labelColor : Theme.shared.activeCollection.tableRowColors.secondaryLabelColor
		}

		self.textField = cellTextField

		themeApplierToken = Theme.shared.add(applier: { [weak self] (_, themeCollection, _) in
			cellTextField.textColor = (self?.enabled == true) ? themeCollection.tableRowColors.labelColor : themeCollection.tableRowColors.secondaryLabelColor
			cellTextField.attributedPlaceholder = NSAttributedString(string: placeholderString, attributes: [.foregroundColor : themeCollection.tableRowColors.secondaryLabelColor])
		})
	}

	convenience init(secureTextFieldWithAction action: StaticTableViewRowAction?, placeholder placeholderString: String = "", value textValue: String = "", keyboardType: UIKeyboardType = UIKeyboardType.default, autocorrectionType: UITextAutocorrectionType = UITextAutocorrectionType.default, autocapitalizationType: UITextAutocapitalizationType = UITextAutocapitalizationType.none, enablesReturnKeyAutomatically: Bool = true, returnKeyType : UIReturnKeyType = UIReturnKeyType.default, identifier : String? = nil) {
		self.init(textFieldWithAction: action,
                  placeholder: placeholderString,
                  value: textValue, secureTextEntry: true,
                  keyboardType: keyboardType,
                  autocorrectionType: autocorrectionType,
                  autocapitalizationType: autocapitalizationType,
                  enablesReturnKeyAutomatically: enablesReturnKeyAutomatically,
                  returnKeyType: returnKeyType, identifier : identifier)
	}

	@objc func textFieldContentChanged(_ sender: UITextField) {
		self.value = sender.text

		self.action?(self, sender)
	}

	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()

		return true
	}

	// MARK: - Labels
	convenience init(label: String, identifier: String? = nil) {
		self.init()

		self.identifier = identifier

		self.cell = ThemeTableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
		self.cell?.textLabel?.text = label
		self.cell?.isUserInteractionEnabled = false

		self.value = label
		self.selectable = false

		self.updateViewFromValue = { (row) in
			if let value = row.value as? String {
				row.cell?.textLabel?.text = value
			}
		}
	}

	// MARK: - Switches
	convenience init(switchWithAction action: StaticTableViewRowAction?, title: String, value switchValue: Bool = false, identifier: String? = nil) {
		self.init()

		self.identifier = identifier

		let switchView = UISwitch()

		self.cell = ThemeTableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
		self.cell?.selectionStyle = .none
		self.cell?.textLabel?.text = title
		self.cell?.accessoryView = switchView

		switchView.isOn = switchValue
		switchView.accessibilityIdentifier = identifier

		self.value = switchValue

		self.action = action

		switchView.addTarget(self, action: #selector(switchValueChanged(_:)), for: UIControlEvents.valueChanged)

		self.updateViewAppearance = { [weak switchView] (row) in
			switchView?.isEnabled = row.enabled
		}

		self.updateViewFromValue = { [weak switchView] (row) in
			if let value = row.value as? Bool {
				switchView?.setOn(value, animated: true)
			}
		}
	}

	@objc func switchValueChanged(_ sender: UISwitch) {
		self.value = sender.isOn

		self.action?(self, sender)
	}

	// MARK: - Buttons
	convenience init(buttonWithAction action: StaticTableViewRowAction?, title: String, style: StaticTableViewRowButtonStyle = StaticTableViewRowButtonStyle.proceed, identifier : String? = nil) {
		self.init()

		self.identifier = identifier

		self.cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: nil)
		self.cell?.textLabel?.text = title
		self.cell?.textLabel?.textAlignment = NSTextAlignment.center

		self.cell?.accessibilityIdentifier = identifier

		themeApplierToken = Theme.shared.add(applier: { [weak self] (_, themeCollection, _) in
			var textColor, selectedTextColor, backgroundColor, selectedBackgroundColor : UIColor?

			switch style {
				case .plain:
					textColor = themeCollection.tintColor
					backgroundColor = themeCollection.tableRowColors.backgroundColor

				case .proceed:
					textColor = themeCollection.neutralColors.normal.foreground
					backgroundColor = themeCollection.neutralColors.normal.background
					selectedBackgroundColor = themeCollection.neutralColors.highlighted.background

				case .destructive:
					textColor = UIColor.red
					backgroundColor = themeCollection.tableRowColors.backgroundColor

				case let .custom(customTextColor, customSelectedTextColor, customBackgroundColor, customSelectedBackgroundColor):
					textColor = customTextColor
					selectedTextColor = customSelectedTextColor
					backgroundColor = customBackgroundColor
					selectedBackgroundColor = customSelectedBackgroundColor

			}

			self?.cell?.textLabel?.textColor = textColor

			if selectedTextColor != nil {

				self?.cell?.textLabel?.highlightedTextColor = selectedTextColor
			}

			if backgroundColor != nil {

				self?.cell?.backgroundColor = backgroundColor
			}

			if selectedBackgroundColor != nil {
				let selectedBackgroundView = UIView()

				selectedBackgroundView.backgroundColor = selectedBackgroundColor

				self?.cell?.selectedBackgroundView? = selectedBackgroundView
			}
		}, applyImmediately: true)

		self.action = action
	}

	// MARK: - Deinit
	deinit {
		if themeApplierToken != nil {
			Theme.shared.remove(applierForToken: themeApplierToken)
		}
	}
}
