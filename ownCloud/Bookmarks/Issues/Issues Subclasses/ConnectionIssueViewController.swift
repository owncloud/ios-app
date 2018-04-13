//
//  IssueViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 04/04/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK
import ownCloudUI

enum ConnectionResponse {
    case cancel
    case approve
    case error
}

typealias FilteredIssues = (issues: [OCConnectionIssue]?, level: OCConnectionIssueLevel?)

class ConnectionIssueViewController: IssuesViewController {

    private var connectionIssues: [OCConnectionIssue]?

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    init(issue: OCConnectionIssue, title: String? = nil, completion:@escaping (ConnectionResponse) -> Void) {
        super.init(buttons: nil, title: "")
        let filteredIssues = filter(issue: issue)
        connectionIssues = filteredIssues.issues

        if filteredIssues.level == OCConnectionIssueLevel.error {
            self.headerTitle = "Error".localized
            self.buttons = [IssueButton(title: "OK".localized, type: .plain, action: {
                completion(.error)
                self.dismiss(animated: true)})]
        } else {
            self.headerTitle = "Review Connection".localized
            self.buttons = [
                IssueButton(title: "Cancel".localized, type: .cancel, action: {
                    completion(.cancel)
                    self.dismiss(animated: true)}),
                IssueButton(title: "Approve".localized, type: .approve, action: {
                    completion(.approve)
                    self.dismiss(animated: true)})
            ]
        }
    }

    func filter(issue: OCConnectionIssue) -> FilteredIssues {

        let errorIssues = issue.issuesWithLevelGreaterThanOrEqual(to: .error)
        if errorIssues != nil, errorIssues!.count > 0 {
            return (errorIssues, OCConnectionIssueLevel.error)
        }

        let warningIssues = issue.issuesWithLevelGreaterThanOrEqual(to: .warning)
        if warningIssues != nil, warningIssues!.count > 0 {
            return (issue.issues, OCConnectionIssueLevel.warning)
        }

        return (nil, nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.dataSource = self
    }
}

extension ConnectionIssueViewController {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let issue = connectionIssues?[indexPath.row], issue.type == OCConnectionIssueType.certificate {
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
        return connectionIssues?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let issue = connectionIssues![indexPath.row]
        cell.detailTextLabel?.text = issue.localizedDescription
        cell.textLabel?.text = issue.localizedTitle
        cell.textLabel?.numberOfLines = 0

        var color: UIColor = .black
        cell.selectionStyle = .none

        if issue.type == OCConnectionIssueType.certificate {
            cell.accessoryType = .disclosureIndicator
            cell.accessoryView?.backgroundColor = .blue
        }

        switch issue.level {
        case .warning:
            color = UIColor(hex: 0xF2994A)
        case .informal:
            color = UIColor(hex: 0x27AE60)
        case .error:
            color = UIColor(hex: 0xEB5757)
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
