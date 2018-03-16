//
//  CertificateViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 16/03/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK
import ownCloudUI

class CertificateViewController: IssuesViewController {

    private let certificateDescription: NSAttributedString?
    private let backButton: UIButton = UIButton(type: .system)

    init(certificateDescription: NSAttributedString, nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.certificateDescription = certificateDescription
        super.init(issues: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        self.certificateDescription = nil
        super.init(coder: aDecoder)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        backButton.backgroundColor = UIColor(hex: 0xF2F2F2)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.layer.cornerRadius = 10
        backButton.setAttributedTitle(NSAttributedString(string: "Back", attributes: [.font : UIFont.systemFont(ofSize: 20, weight: .semibold)]), for: .normal)
        backButton.addTarget(self, action: #selector(super.dismissView), for: .touchUpInside)
        self.addBottomContainerElements(elements: [backButton])

        backButton.bottomAnchor.constraint(equalTo: bottomContainer.bottomAnchor).isActive = true
        backButton.topAnchor.constraint(equalTo: bottomContainer.topAnchor).isActive = true
        backButton.leftAnchor.constraint(equalTo: bottomContainer.leftAnchor).isActive = true
        backButton.rightAnchor.constraint(equalTo: bottomContainer.rightAnchor).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        bottomContainer.layoutSubviews()

    }

}

// MARK: Table View DataSouce
extension CertificateViewController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
        cell.textLabel?.attributedText = self.certificateDescription
        cell.textLabel?.numberOfLines = 0
        return cell
    }

}
