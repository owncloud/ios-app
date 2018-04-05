//
//  ErrorsViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 16/03/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

class ErrorsViewController: IssuesViewController {

    private let okButton : UIButton = UIButton(type: .system)

    init(issues: [OCConnectionIssue]?, completionHandler: (() -> Void)?) {
        super.init(issues: issues, headerTitle: NSLocalizedString("Error", comment: ""), completionHandler: completionHandler)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        okButton.backgroundColor = UIColor(hex: 0xF2F2F2)
        okButton.translatesAutoresizingMaskIntoConstraints = false
        okButton.layer.cornerRadius = 10
        okButton.setAttributedTitle(NSAttributedString(string: "OK", attributes: [.font : UIFont.systemFont(ofSize: 20, weight: .semibold)]), for: .normal)
        okButton.addTarget(self, action: #selector(super.dismissView), for: .touchUpInside)
        self.addBottomContainerElements(elements: [okButton])

        okButton.bottomAnchor.constraint(equalTo: bottomContainer.bottomAnchor).isActive = true
        okButton.topAnchor.constraint(equalTo: bottomContainer.topAnchor).isActive = true
        okButton.leftAnchor.constraint(equalTo: bottomContainer.leftAnchor).isActive = true
        okButton.rightAnchor.constraint(equalTo: bottomContainer.rightAnchor).isActive = true
        okButton.heightAnchor.constraint(equalToConstant: 50).isActive = true

        bottomContainer.layoutSubviews()
    }
}
