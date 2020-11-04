//
//  IssueViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 05/04/2018.
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
import ownCloudAppShared
import ownCloudSDK

enum IssueButtonStyle {
	case plain
	case approve
	case cancel
	case custom(backgroundColor: UIColor)
}

struct IssueButton {
	let title: String
	let type: IssueButtonStyle
	let action: () -> Void
	let accessibilityIdentifier: String
}

class IssuesTableViewCell : UITableViewCell, Themeable {
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

		Theme.shared.register(client: self, applyImmediately: true)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.backgroundColor = collection.tableBackgroundColor
		self.detailTextLabel?.textColor = collection.tableRowColors.labelColor
	}
}

let IssuesViewControllerCellIdentifier = "issue-cell"

class IssuesViewController: UIViewController {

	var tableView: UITableView?
	private var bottomContainer: UIStackView?
	var headerTitle: String?
	var issueLevel: OCIssueLevel?
	var buttons:[IssueButton]?
	private var tableHeighConstraint: NSLayoutConstraint?
	private var modalPresentationVC: UIViewControllerTransitioningDelegate?

	init(buttons: [IssueButton]? = nil, title: String?) {
		super.init(nibName: nil, bundle: nil)
		self.headerTitle = title
		self.buttons = buttons
		setupTransitions()
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
		setupTableView()
		setupBottomContainer()
		tableView?.delegate = self
		self.addButtons()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		setupConstraints()
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		self.tableHeighConstraint?.constant =  self.tableView!.contentSize.height
	}

	private func setupTableView() {
		tableView = UITableView()
		tableView?.layer.cornerRadius = 10
		tableView?.separatorInset = .zero
		tableView?.bounces = false
		tableView?.rowHeight = UITableView.automaticDimension
		tableView?.register(IssuesTableViewCell.self, forCellReuseIdentifier: IssuesViewControllerCellIdentifier)
	}

	private func setupBottomContainer() {
		bottomContainer = UIStackView()
		bottomContainer?.alignment = .fill
		bottomContainer?.axis = .horizontal
		bottomContainer?.distribution = .fillEqually
		bottomContainer?.spacing = 20
	}

	func addButtons() {
		if let buttonsToAdd = buttons {
			var tag = 0
			buttonsToAdd.forEach({
				let button = UIButton(type: .system)
				var color: UIColor = .blue
				var backgroundColor: UIColor = .white

				switch $0.type {
				case .approve:
					backgroundColor = Theme.shared.activeCollection.approvalColors.normal.background
					color = Theme.shared.activeCollection.approvalColors.normal.foreground
				case .custom(let backColor):
					backgroundColor = backColor
				default:
					backgroundColor = Theme.shared.activeCollection.tableRowColors.filledColorPairCollection.normal.background
					color = Theme.shared.activeCollection.tableRowColors.filledColorPairCollection.normal.foreground
				}

				button.backgroundColor = backgroundColor
				button.setAttributedTitle(NSAttributedString(string: $0.title, attributes: [
					.foregroundColor : color,
					.font : UIFont.systemFont(ofSize: 20, weight: .semibold)
					]), for: .normal)
				button.setTitle($0.title, for: UIControl.State.normal)
				button.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
				button.accessibilityIdentifier = $0.accessibilityIdentifier
				button.layer.cornerRadius = 10
				button.tag = tag
				tag += 1
				bottomContainer?.addArrangedSubview(button)
			})
		}
	}

	@objc func buttonPressed(_ button :UIButton) {
		if let buttonPressed: IssueButton = buttons?[button.tag] {
			buttonPressed.action()
		}
	}

	private func setupConstraints() {
		bottomContainer?.translatesAutoresizingMaskIntoConstraints = false
		self.view.addSubview(bottomContainer!)

		bottomContainer?.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
		bottomContainer?.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
		bottomContainer?.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
		bottomContainer?.heightAnchor.constraint(equalToConstant: 50).isActive = true
		bottomContainer?.contentHuggingPriority(for: .vertical)

		tableView?.translatesAutoresizingMaskIntoConstraints = false
		self.view.addSubview(tableView!)

		tableView?.bottomAnchor.constraint(equalTo: bottomContainer!.topAnchor, constant: -20).isActive = true
		tableView?.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor, constant: 20).isActive = true
		tableView?.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor, constant: -20).isActive = true
		tableView?.topAnchor.constraint(greaterThanOrEqualTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
		tableHeighConstraint = tableView?.heightAnchor.constraint(equalToConstant: 0)
		tableHeighConstraint?.priority = UILayoutPriority.defaultLow
		tableHeighConstraint?.isActive = true
	}

	private func setupTransitions() {
		self.modalPresentationStyle = .overCurrentContext
		let transitioningDLG = IssuesTransitioningDelegate()
		self.modalPresentationVC = transitioningDLG
		self.transitioningDelegate = transitioningDLG
	}
}

extension IssuesViewController: UITableViewDelegate {

	func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
		cell.textLabel?.text = headerTitle ?? ""
		cell.textLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
		var textColor = Theme.shared.activeCollection.tableRowColors.labelColor
		if issueLevel != nil {
			switch issueLevel {
			case .warning:
				textColor = Theme.shared.activeCollection.warningColor
			case .informal:
				textColor = Theme.shared.activeCollection.informativeColor
			case .error:
				textColor = Theme.shared.activeCollection.errorColor
			case .none, .some(_): break
			}
		}
		cell.textLabel?.textColor = textColor
		cell.backgroundColor = Theme.shared.activeCollection.tableBackgroundColor

		let separatorView: UIView = UIView()
		separatorView.translatesAutoresizingMaskIntoConstraints = false
		separatorView.backgroundColor = Theme.shared.activeCollection.tableSeparatorColor
		cell.addSubview(separatorView)
		separatorView.heightAnchor.constraint(equalToConstant: 1).isActive = true
		separatorView.leftAnchor.constraint(equalTo: cell.leftAnchor, constant: 0).isActive = true
		separatorView.rightAnchor.constraint(equalTo: cell.rightAnchor, constant: 0).isActive = true
		separatorView.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: 0).isActive = true
		return cell
	}

	func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 40
	}

}

internal class IssuesTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

	func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return IssuesPresentationAnimator()
	}

	func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
		return IssuesDismissalAnimator()
	}
}
