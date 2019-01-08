//
//  IssueViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 04/04/2018.
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
import ownCloudSDK
import ownCloudUI

enum ConnectionResponse {
	case cancel
	case approve
	case dismiss
}

class ConnectionIssueViewController: IssuesViewController {

	private var displayIssues : DisplayIssues?
	private var dismissedHandler : (() -> Void)?

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

	init(displayIssues issues: DisplayIssues?, buttons: [IssueButton]? = nil, title: String? = nil) {
		super.init(buttons: buttons, title: title)

		displayIssues = issues
	}

	convenience init(displayIssues issues: DisplayIssues?, title: String? = nil, completion:@escaping (ConnectionResponse) -> Void, dismissedHandler dismissedHandlerBlock: (() -> Void)? = nil) {
		var useButtons : [IssueButton]?
		var useTitle = title

		self.init(displayIssues: issues, buttons: nil, title: useTitle)

		self.dismissedHandler = dismissedHandlerBlock

		if let displayLevel = issues?.displayLevel {
			switch displayLevel {
			case .informal:
				if title == nil {
					useTitle = "Review Connection".localized
				}

				useButtons = [
					IssueButton(title: "OK".localized, type: .approve, action: { [weak self] in
						completion(.approve)
						self?.dismiss(animated: true)}, accessibilityIdentifier: "ok-button")
				]

			case .warning:
				if title == nil {
					useTitle = "Review Connection".localized
				}

				useButtons = [
					IssueButton(title: "Cancel".localized, type: .cancel, action: { [weak self] in
						completion(.cancel)
						self?.dismiss(animated: true)}, accessibilityIdentifier: "cancel-button"),

					IssueButton(title: "Approve".localized, type: .approve, action: { [weak self] in
						completion(.approve)
						self?.dismiss(animated: true)}, accessibilityIdentifier: "approve-button")
				]

			case .error:
				if title == nil {
					useTitle = "Error".localized
				}

				useButtons = [
					IssueButton(title: "OK".localized, type: .approve, action: { [weak self] in
						completion(.dismiss)
						self?.dismiss(animated: true)}, accessibilityIdentifier: "ok-button")
				]
			}

			self.headerTitle = useTitle
			self.buttons = useButtons
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView?.dataSource = self
	}

	override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
		super.dismiss(animated: flag) {
			completion?()
			self.dismissedHandler?()
		}
	}
}

extension ConnectionIssueViewController {
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if let issue = displayIssues?.displayIssues[indexPath.row], issue.type == OCIssueType.certificate {
			OCCertificateDetailsViewNode.certificateDetailsViewNodes(for: issue.certificate, withValidationCompletionHandler: { (certificateNodes) in
				let certDetails: NSAttributedString = OCCertificateDetailsViewNode .attributedString(withCertificateDetails: certificateNodes)
				DispatchQueue.main.async {
					let issuesVC = CertificateViewController(localizedDescription: certDetails)
					issuesVC.modalPresentationStyle = .overCurrentContext
					self.present(issuesVC, animated: true, completion: nil)
				}
			})
		}
	}
}

extension ConnectionIssueViewController: UITableViewDataSource {

	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return displayIssues?.displayIssues.count ?? 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: IssuesViewControllerCellIdentifier, for: indexPath)
		let issue = (displayIssues?.displayIssues[indexPath.row])!
		cell.detailTextLabel?.text = issue.localizedDescription
		cell.textLabel?.text = issue.localizedTitle
		cell.textLabel?.numberOfLines = 0

		var color: UIColor = .black
		cell.selectionStyle = .none

		if issue.type == OCIssueType.certificate {
			cell.accessoryType = .disclosureIndicator
			cell.accessoryView?.backgroundColor = .blue
		} else {
			cell.accessoryType = .none
		}

		switch issue.level {
		case .warning:
			color = Theme.shared.activeCollection.warningColor
		case .informal:
			color = Theme.shared.activeCollection.informativeColor
		case .error:
			color = Theme.shared.activeCollection.errorColor
		}

		cell.textLabel?.attributedText = NSAttributedString(string: issue.localizedTitle, attributes: [
			.foregroundColor : color,
			.font : UIFont.systemFont(ofSize: 18, weight: .semibold)
			])

		cell.detailTextLabel?.attributedText = NSAttributedString(string: issue.localizedDescription, attributes: [
			.foregroundColor : UIColor(hex: 0x4F4F4F),
			.font : UIFont.systemFont(ofSize: 15, weight: .regular)
			])
		cell.detailTextLabel?.numberOfLines = 0
		return cell
	}
}
