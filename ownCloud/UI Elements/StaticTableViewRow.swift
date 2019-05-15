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
	case plainNonOpaque
	case proceed
	case destructive
	case custom(textColor: UIColor?, selectedTextColor: UIColor?, backgroundColor: UIColor?, selectedBackgroundColor: UIColor?)
}

enum StaticTableViewRowType {
	case row
	case subtitleRow
	case valueRow
	case radio
	case toggle
	case text
	case secureText
	case label
	case switchButton
	case button
	case datePicker
}

class StaticTableViewRow : NSObject, UITextFieldDelegate {

	public weak var section : StaticTableViewSection?

	public var identifier : String?
	public var groupIdentifier : String?
	public var type : StaticTableViewRowType

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

	public var additionalAccessoryView : UIView?

	override init() {
		type = .row
		super.init()
	}

	convenience init(rowWithAction: StaticTableViewRowAction?, title: String, subtitle: String? = nil, image: UIImage? = nil, alignment: NSTextAlignment = .left, accessoryType: UITableViewCell.AccessoryType = UITableViewCell.AccessoryType.none, identifier : String? = nil, accessoryView: UIView? = nil) {
		self.init()
		type = .row

		self.identifier = identifier
		var cellStyle = UITableViewCell.CellStyle.default
		if subtitle != nil {
			cellStyle = UITableViewCell.CellStyle.subtitle
		}

		self.cell = ThemeTableViewCell(style: cellStyle, reuseIdentifier: nil)
		if subtitle != nil {
			self.cell?.detailTextLabel?.text = subtitle
			self.cell?.detailTextLabel?.numberOfLines = 0
		}
		self.cell?.textLabel?.text = title
		self.cell?.textLabel?.textAlignment = alignment
		self.cell?.accessoryType = accessoryType
		self.cell?.imageView?.image = image
		if accessoryView != nil {
			self.cell?.accessoryView = accessoryView
		}

		themeApplierToken = Theme.shared.add(applier: { [weak self] (_, themeCollection, _) in
			self?.cell?.imageView?.tintColor = themeCollection.tableRowColors.labelColor
			self?.cell?.accessoryView?.tintColor = themeCollection.tableRowColors.labelColor
			})

		self.cell?.accessibilityIdentifier = identifier

		if rowWithAction != nil {
			self.action = rowWithAction
		} else {
			self.cell?.selectionStyle = .none
		}
	}

	convenience init(rowWithAction: StaticTableViewRowAction?, title: String, alignment: NSTextAlignment = .left, accessoryView: UIView? = nil, identifier : String? = nil) {
		self.init()
		type = .row

		self.identifier = identifier

		self.cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: nil)
		self.cell?.textLabel?.text = title
		self.cell?.textLabel?.textAlignment = alignment
		self.cell?.accessoryView = accessoryView
		self.cell?.accessibilityIdentifier = identifier

		themeApplierToken = Theme.shared.add(applier: { [weak self] (_, themeCollection, _) in
			var textColor, selectedTextColor, backgroundColor, selectedBackgroundColor : UIColor?

			textColor = themeCollection.tintColor
			backgroundColor = themeCollection.tableRowColors.backgroundColor

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

		if rowWithAction != nil {
			self.action = rowWithAction
		} else {
			self.cell?.selectionStyle = .none
		}
	}

	convenience init(rowWithAction: StaticTableViewRowAction?, title: String, alignment: NSTextAlignment = .left, image: UIImage? = nil, accessoryType: UITableViewCell.AccessoryType = UITableViewCell.AccessoryType.none, accessoryView: UIView, identifier: String? = nil) {
		self.init()
		type = .row

		self.identifier = identifier

		self.cell = ThemeTableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: nil)

		guard let cell = self.cell else { return }

		cell.textLabel?.text = title
		cell.textLabel?.textAlignment = alignment
		cell.accessoryType = accessoryType
		self.cell?.imageView?.image = image
		cell.accessibilityIdentifier = identifier
		if rowWithAction != nil {
			self.action = rowWithAction
		} else {
			self.cell?.selectionStyle = .none
		}

		additionalAccessoryView = accessoryView
		guard let additionalAccessoryView = additionalAccessoryView else { return }
		cell.contentView.addSubview(additionalAccessoryView)
		additionalAccessoryView.translatesAutoresizingMaskIntoConstraints = false

		NSLayoutConstraint.activate([
			additionalAccessoryView.trailingAnchor.constraint(equalTo: cell.accessoryView?.leadingAnchor ?? cell.contentView.trailingAnchor, constant: -5.0),
			additionalAccessoryView.widthAnchor.constraint(greaterThanOrEqualToConstant: 0),
			additionalAccessoryView.heightAnchor.constraint(equalToConstant: 24.0),
			additionalAccessoryView.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
			])

		themeApplierToken = Theme.shared.add(applier: { [weak self] (_, themeCollection, _) in
			self?.cell?.imageView?.tintColor = themeCollection.tableRowColors.labelColor
		})
	}

	convenience init(subtitleRowWithAction: StaticTableViewRowAction?, title: String, subtitle: String? = nil, style : UITableViewCell.CellStyle = .subtitle, accessoryType: UITableViewCell.AccessoryType = UITableViewCell.AccessoryType.none, identifier : String? = nil) {
		self.init()
		type = .subtitleRow

		self.identifier = identifier

		self.cell = ThemeTableViewCell(style: style, reuseIdentifier: nil)
		self.cell?.textLabel?.text = title
		self.cell?.detailTextLabel?.text = subtitle
		self.cell?.accessoryType = accessoryType

		self.cell?.accessibilityIdentifier = identifier

		self.action = subtitleRowWithAction

		self.updateViewFromValue = { (row) in
			if let value = row.value as? String {
				row.cell?.detailTextLabel?.text = value
			}
		}
	}

	convenience init(valueRowWithAction: StaticTableViewRowAction?, title: String, value: String, accessoryType: UITableViewCell.AccessoryType = UITableViewCell.AccessoryType.none, identifier : String? = nil) {
		self.init(subtitleRowWithAction: valueRowWithAction, title: title, subtitle: value, style: .value1, accessoryType: accessoryType, identifier: identifier)
		type = .valueRow
	}

	// MARK: - Radio Item
	convenience init(radioItemWithAction: StaticTableViewRowAction?, groupIdentifier: String, value: Any, title: String, subtitle: String? = nil, selected: Bool, identifier : String? = nil) {
		self.init()
		type = .radio

		var tableViewStyle = UITableViewCell.CellStyle.default
		self.identifier = identifier
		if subtitle != nil {
			tableViewStyle = UITableViewCell.CellStyle.subtitle
		}

		self.cell = ThemeTableViewCell(style: tableViewStyle, reuseIdentifier: nil)
		self.cell?.textLabel?.text = title
		if subtitle != nil {
			self.cell?.detailTextLabel?.text = subtitle
			self.cell?.detailTextLabel?.numberOfLines = 0
		}

		if let accessibilityIdentifier : String = identifier {
			self.cell?.accessibilityIdentifier = groupIdentifier + "." + accessibilityIdentifier
		}

		self.groupIdentifier = groupIdentifier
		self.value = value

		if selected {
			self.cell?.accessoryType = UITableViewCell.AccessoryType.checkmark
		}

		self.action = { (row, sender) in
			row.section?.setSelected(row.value!, groupIdentifier: row.groupIdentifier!)
			radioItemWithAction?(row, sender)
		}
	}

	// MARK: - Toggle Item
	convenience init(toggleItemWithAction: StaticTableViewRowAction?, title: String, subtitle: String? = nil, selected: Bool, identifier : String? = nil) {
		self.init()
		type = .toggle

		var tableViewStyle = UITableViewCell.CellStyle.default
		self.identifier = identifier
		if subtitle != nil {
			tableViewStyle = UITableViewCell.CellStyle.subtitle
		}

		self.cell = ThemeTableViewCell(style: tableViewStyle, reuseIdentifier: nil)
		self.cell?.textLabel?.text = title
		if subtitle != nil {
			self.cell?.detailTextLabel?.text = subtitle
			self.cell?.detailTextLabel?.numberOfLines = 0
		}

		if let accessibilityIdentifier : String = identifier {
			self.cell?.accessibilityIdentifier = accessibilityIdentifier
		}

		if selected {
			self.cell?.accessoryType = UITableViewCell.AccessoryType.checkmark
			self.value = true
		} else {
			self.value = false
		}

		self.action = { (row, sender) in

			guard let value = self.value as? Bool else { return }
			if value {
				row.cell?.accessoryType = UITableViewCell.AccessoryType.none
				self.value = false
			} else {
				row.cell?.accessoryType = UITableViewCell.AccessoryType.checkmark
				self.value = true
			}

			toggleItemWithAction?(row, sender)
		}
	}

	// MARK: - Text Field
	public var textField : UITextField?

	convenience init(textFieldWithAction action: StaticTableViewRowAction?, placeholder placeholderString: String = "", value textValue: String = "", secureTextEntry : Bool = false, keyboardType: UIKeyboardType = UIKeyboardType.default, autocorrectionType: UITextAutocorrectionType = UITextAutocorrectionType.default, autocapitalizationType: UITextAutocapitalizationType = UITextAutocapitalizationType.none, enablesReturnKeyAutomatically: Bool = true, returnKeyType : UIReturnKeyType = UIReturnKeyType.default, identifier : String? = nil, accessibilityLabel: String? = nil, actionEvent: UIControl.Event = UIControl.Event.editingChanged) {
		self.init()
		type = .text

		self.identifier = identifier

		self.cell = ThemeTableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: nil)
		self.cell?.selectionStyle = UITableViewCell.SelectionStyle.none

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

		cellTextField.addTarget(self, action: #selector(textFieldContentChanged(_:)), for: actionEvent)

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

		cellTextField.accessibilityLabel = accessibilityLabel
	}

	convenience init(secureTextFieldWithAction action: StaticTableViewRowAction?, placeholder placeholderString: String = "", value textValue: String = "", keyboardType: UIKeyboardType = UIKeyboardType.default, autocorrectionType: UITextAutocorrectionType = UITextAutocorrectionType.default, autocapitalizationType: UITextAutocapitalizationType = UITextAutocapitalizationType.none, enablesReturnKeyAutomatically: Bool = true, returnKeyType : UIReturnKeyType = UIReturnKeyType.default, identifier : String? = nil, accessibilityLabel: String? = nil, actionEvent: UIControl.Event = UIControl.Event.editingChanged) {
		self.init(	textFieldWithAction: action,
				placeholder: placeholderString,
				value: textValue, secureTextEntry: true,
				keyboardType: keyboardType,
				autocorrectionType: autocorrectionType,
				autocapitalizationType: autocapitalizationType,
				enablesReturnKeyAutomatically: enablesReturnKeyAutomatically,
				returnKeyType: returnKeyType,
				identifier : identifier,
				accessibilityLabel: accessibilityLabel,
				actionEvent: actionEvent)
		type = .secureText
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
		type = .label

		self.identifier = identifier

		self.cell = ThemeTableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: nil)
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
		type = .switchButton

		self.identifier = identifier

		let switchView = UISwitch()

		self.cell = ThemeTableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: nil)
		self.cell?.selectionStyle = .none
		self.cell?.textLabel?.text = title
		self.cell?.accessoryView = switchView

		switchView.isOn = switchValue
		switchView.accessibilityIdentifier = identifier

		self.value = switchValue

		self.action = action

		switchView.addTarget(self, action: #selector(switchValueChanged(_:)), for: UIControl.Event.valueChanged)

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

	convenience init(buttonWithAction action: StaticTableViewRowAction?, title: String, style: StaticTableViewRowButtonStyle = StaticTableViewRowButtonStyle.proceed, image: UIImage? = nil, alignment: NSTextAlignment = NSTextAlignment.center, identifier : String? = nil, accessoryView: UIView? = nil) {
		self.init()
		type = .button

		self.identifier = identifier

		self.cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: nil)
		self.cell?.textLabel?.text = title
		self.cell?.textLabel?.textAlignment = alignment
		self.cell?.imageView?.image = image
		if accessoryView != nil {
			self.cell?.accessoryView = accessoryView
		}

		self.cell?.accessibilityIdentifier = identifier

		themeApplierToken = Theme.shared.add(applier: { [weak self] (_, themeCollection, _) in
			var textColor, selectedTextColor, backgroundColor, selectedBackgroundColor : UIColor?

			switch style {
			case .plain:
				textColor = themeCollection.tintColor
				backgroundColor = themeCollection.tableRowColors.backgroundColor

			case .plainNonOpaque:
				textColor = themeCollection.tableRowColors.tintColor
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
			self?.cell?.imageView?.tintColor = textColor
			self?.cell?.accessoryView?.tintColor = textColor

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

	// MARK: - Date Picker

	convenience init(datePickerWithAction action: StaticTableViewRowAction?, date dateValue: Date, identifier: String? = nil) {
		self.init()
		type = .datePicker

		self.identifier = identifier

		let datePickerView = UIDatePicker()
		datePickerView.date = dateValue
		datePickerView.datePickerMode = .date
		datePickerView.minimumDate = Date()
		datePickerView.accessibilityIdentifier = identifier
		datePickerView.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: UIControl.Event.valueChanged)
		datePickerView.translatesAutoresizingMaskIntoConstraints = false
		datePickerView.setValue(Theme.shared.activeCollection.tableRowColors.labelColor, forKey: "textColor")

		self.cell = ThemeTableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: nil)
		self.cell?.selectionStyle = .none
		self.cell?.addSubview(datePickerView)

		self.value = dateValue
		self.action = action

		if let cell = self.cell {
			NSLayoutConstraint.activate([
				datePickerView.leftAnchor.constraint(equalTo: cell.safeAreaLayoutGuide.leftAnchor),
				datePickerView.rightAnchor.constraint(equalTo: cell.safeAreaLayoutGuide.rightAnchor),
				datePickerView.topAnchor.constraint(equalTo: cell.topAnchor),
				datePickerView.heightAnchor.constraint(equalToConstant: 216.0)
				])
		}
	}

	@objc func datePickerValueChanged(_ sender: UIDatePicker) {
		self.action?(self, sender)
	}

	// MARK: - Deinit

	deinit {
		if themeApplierToken != nil {
			Theme.shared.remove(applierForToken: themeApplierToken)
		}
	}
}
