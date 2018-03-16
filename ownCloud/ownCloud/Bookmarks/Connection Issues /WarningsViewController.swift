//
//  WarningsViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 16/03/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

class WarningsViewController: IssuesViewController {

    let cancelButton: UIButton = UIButton(type: .system)
    let approveButton: UIButton = UIButton(type: .system)

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        approveButton.translatesAutoresizingMaskIntoConstraints = false

        self.addBottomContainerElements(elements: [cancelButton, approveButton])

        cancelButton.bottomAnchor.constraint(equalTo: self.bottomContainer.bottomAnchor).isActive = true
        cancelButton.leftAnchor.constraint(equalTo: self.bottomContainer.leftAnchor).isActive = true
        cancelButton.rightAnchor.constraint(equalTo: self.approveButton.leftAnchor, constant: -20).isActive = true
        cancelButton.topAnchor.constraint(equalTo: self.bottomContainer.topAnchor).isActive = true
        cancelButton.addTarget(self, action: #selector(super.dismissView), for: .touchUpInside)
        cancelButton.layer.cornerRadius = 10

        cancelButton.setAttributedTitle(NSAttributedString(string: "Cancel", attributes: [.font : UIFont.systemFont(ofSize: 20, weight: .semibold)]), for: .normal)
        cancelButton.backgroundColor = UIColor.white

        approveButton.bottomAnchor.constraint(equalTo: self.bottomContainer.bottomAnchor).isActive = true
        approveButton.rightAnchor.constraint(equalTo: self.bottomContainer.rightAnchor).isActive = true
        approveButton.topAnchor.constraint(equalTo: self.bottomContainer.topAnchor).isActive = true
        approveButton.widthAnchor.constraint(equalTo: self.cancelButton.widthAnchor).isActive = true
        approveButton.layer.cornerRadius = 10

        approveButton.addTarget(self, action: #selector(super.dismissView), for: .touchUpInside)

        approveButton.setAttributedTitle(NSAttributedString(string: "Aprove", attributes: [.font : UIFont.systemFont(ofSize: 20, weight: .semibold), .foregroundColor : UIColor.white]), for: .normal)
        approveButton.backgroundColor = UIColor(hex:0x1AC763)

        bottomContainer.layoutSubviews()
    }
}
