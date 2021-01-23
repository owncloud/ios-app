//
//  IssuesCardViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 22.01.21.
//  Copyright © 2021 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK
import ownCloudAppShared

class CardCellBackgroundView : UIView {
	init(backgroundColor: UIColor, insets: NSDirectionalEdgeInsets, cornerRadius: CGFloat) {
		super.init(frame: .zero)

		let backgroundView = UIView(frame: .zero)
		backgroundView.translatesAutoresizingMaskIntoConstraints = false

		backgroundView.layer.backgroundColor = backgroundColor.cgColor
		backgroundView.layer.cornerRadius = cornerRadius

		addSubview(backgroundView)

		NSLayoutConstraint.activate([
			backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.leading),
			backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.trailing),
			backgroundView.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
			backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

class CardHeaderView : UIView, Themeable {
	var label : UILabel

	init(title: String) {
		label = UILabel()
		label.translatesAutoresizingMaskIntoConstraints = false

		label.text = title
		label.setContentHuggingPriority(.required, for: .vertical)
		label.setContentHuggingPriority(.defaultLow, for: .horizontal)
		label.setContentCompressionResistancePriority(.required, for: .vertical)
		label.setContentCompressionResistancePriority(.required, for: .horizontal)

		super.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))

		translatesAutoresizingMaskIntoConstraints = false
		addSubview(label)

		NSLayoutConstraint.activate([
			label.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 15),
			label.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -15),
			label.topAnchor.constraint(equalTo: self.topAnchor, constant: 10),
			label.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -10)
		])
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	override func didMoveToSuperview() {
		super.didMoveToSuperview()

		if self.superview != nil {
			Theme.shared.register(client: self)
		}
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		label.font = UIFont.systemFont(ofSize: UIFont.systemFontSize * 1.4, weight: .bold)
		label.textColor = collection.tableRowColors.labelColor

		self.backgroundColor = collection.tableBackgroundColor
	}
}

enum IssueUserResponse {
	case cancel
	case approve
	case dismiss
}

class IssuesCardViewController: StaticTableViewController {
	typealias CompletionHandler = (IssueUserResponse) -> Void
	typealias DismissHandler = () -> Void

	var issues : DisplayIssues
	var headerTitle : String?
	var options : [AlertOption]
	weak var alertView : AlertView?

	private var completionHandler : CompletionHandler?
	private var dismissHandler : DismissHandler?

	required init(with issue: OCIssue, displayIssues: DisplayIssues? = nil, bookmark: OCBookmark? = nil, completion:@escaping CompletionHandler, dismissed: DismissHandler? = nil) {
		issues = (displayIssues != nil) ? displayIssues! : issue.prepareForDisplay()
		options = []
		completionHandler = completion
		dismissHandler = dismissed

		super.init(style: .plain)

		headerTitle = "Review Connection".localized

		switch issues.displayLevel {
			case .informal:
				options = [
					AlertOption(label: "OK".localized, type: .default, accessibilityIdentifier: "ok-button", handler: { [weak self] (_, _) in
						self?.complete(with: .approve)
					})
				]

			case .warning:
				options = [
					AlertOption(label: "Cancel".localized, type: .cancel, accessibilityIdentifier: "cancel-button", handler: { [weak self] (_, _) in
						self?.complete(with: .cancel)
					}),

					AlertOption(label: "Approve".localized, type: .regular, accessibilityIdentifier: "approve-button", handler: { [weak self] (_, _) in
						self?.complete(with: .approve)
					})
				]

			case .error:
				headerTitle = "Issues".localized

				options = [
					AlertOption(label: "OK".localized, type: .cancel, accessibilityIdentifier: "ok-button", handler: { [weak self] (_, _) in
						self?.complete(with: .dismiss)
					})
				]
		}

		let section = StaticTableViewSection()

		let cellStyler : ThemeTableViewCell.CellStyler = { (cell, style) in
			cell.textLabel?.textColor = style.textColor
			cell.textLabel?.font = UIFont.systemFont(ofSize: UIFont.systemFontSize * 1.1, weight: .semibold)

			cell.detailTextLabel?.textColor = style.textColor
			cell.detailTextLabel?.font = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .regular)

			if let backgroundColor = style.backgroundColor {
				let edgeInsets = NSDirectionalEdgeInsets(top: 2, leading: 15, bottom: 2, trailing: 15)

				cell.backgroundView = CardCellBackgroundView(backgroundColor: backgroundColor, insets: edgeInsets, cornerRadius: 5)
				cell.selectedBackgroundView = CardCellBackgroundView(backgroundColor: backgroundColor.darker(0.07), insets: edgeInsets, cornerRadius: 5)
			}

			return true
		}

		for issue in issues.displayIssues {
			if let issueTitle = issue.localizedTitle {
				var messageStyle : StaticTableViewRowMessageStyle?

				switch issue.level {

					case .informal:
						messageStyle = .plain

					case .warning:
						messageStyle = .warning

					case .error:
						messageStyle = .alert
				}

				let row = StaticTableViewRow(rowWithAction: { [weak self] (_, _) in
					if issue.type == .certificate, let certificate = issue.certificate {
						let certificateViewController = ThemeCertificateViewController(certificate: certificate, compare: bookmark?.certificate)

						if bookmark?.certificate != nil {
							certificateViewController.showDifferences = true
						}

						self?.present(ThemeNavigationController(rootViewController: certificateViewController), animated: true, completion: nil)
					}
				}, title: issueTitle, subtitle: issue.localizedDescription, messageStyle: messageStyle, accessoryType: (issue.type == .certificate) ? .disclosureIndicator : .none )

				(row.cell as? ThemeTableViewCell)?.cellStyler = cellStyler

				section.add(row: row)
			}
		}

		self.addSection(section)

		self.tableView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 2, leading: 25, bottom: 2, trailing: 25)
		self.tableView.preservesSuperviewLayoutMargins = true
		self.tableView.separatorStyle = .none
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	static func present(on hostViewController: UIViewController, issue: OCIssue, displayIssues: DisplayIssues? = nil, bookmark: OCBookmark? = nil, completion:@escaping CompletionHandler, dismissed: DismissHandler? = nil) {
		let issuesViewController = self.init(with: issue, displayIssues: displayIssues, bookmark: bookmark, completion: completion, dismissed: dismissed)

		let headerView = CardHeaderView(title: issuesViewController.headerTitle ?? "")
		let alertView = AlertView(localizedTitle: "", localizedDescription: "", contentPadding: 15, options: issuesViewController.options)

		let frameViewController = FrameViewController(header: headerView, footer: alertView, viewController: issuesViewController)

		alertView.backgroundColor = Theme.shared.activeCollection.tableBackgroundColor
		issuesViewController.alertView = alertView

		hostViewController.present(asCard: frameViewController, animated: true, withHandle: false, dismissable: false) {
			_ = frameViewController.view
		}
	}

	func complete(with result: IssueUserResponse) {
		completionHandler?(result)
		completionHandler = nil

		self.presentingViewController?.dismiss(animated: true)
	}

	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)

		tableView.backgroundColor = collection.tableBackgroundColor
		alertView?.backgroundColor = collection.tableBackgroundColor
	}
}
