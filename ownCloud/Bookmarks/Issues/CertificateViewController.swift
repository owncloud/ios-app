//
//  CertificatesViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 05/04/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

class CertificateViewController: IssuesViewController {

    private var localizedDescription: NSAttributedString?

    init(localizedDescription: NSAttributedString, buttons: [IssueButton]? = nil) {
        self.localizedDescription = localizedDescription

        if buttons != nil {
            super.init(buttons: buttons, title: "Certificate Details".localized)
        } else {
            super.init(buttons: nil, title: "Certificate Details".localized)
            self.buttons = [IssueButton(title: "OK".localized, type: .plain, action: {
                self.dismiss(animated: true)
            })]
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView?.dataSource = self
    }
}

extension CertificateViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.attributedText = localizedDescription
        cell.textLabel?.numberOfLines = 0
        return cell
    }
}
