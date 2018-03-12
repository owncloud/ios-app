//
//  BookmarkViewController.swift
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
import ownCloudSDK

enum BookmarkViewControllerMode {
	case add
	case edit
}

class BookmarkViewController: StaticTableViewController {

	public var mode : BookmarkViewControllerMode = .add
    private var bookmarkToAdd : OCBookmark?

	override func viewDidLoad() {
		super.viewDidLoad()
        self.navigationController?.title = "Add Server"

        switch mode {
        case .add:
            addServerUrl()
        case .edit:
            // TODO: Make this go directly to the edit view with all the things.
            print("edit")
        }

	}

    private func addServerUrl() {
        let serverURLSection = StaticTableViewSection(headerTitle: "Server Url", footerTitle: nil)

        serverURLSection.add(rows: [
            StaticTableViewRow(textFieldWithAction: { (row, sender) in
            }, placeholder: "https://example.com",
               value: "",
               keyboardType: .default,
               autocorrectionType: .no,
               autocapitalizationType: .none,
               enablesReturnKeyAutomatically: false,
               returnKeyType: .continue,
               identifier: "server-url-textfield")
            ])
        self.addSection(serverURLSection, animated: true)

        let continueButtonSection = StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: "continue-button-section", rows: [
                StaticTableViewRow(buttonWithAction: { (row, sender) in

                    if let textfield = row.section? as? UITextField {
                        self.bookmarkToAdd = OCBookmark(for: URL(string: textfield.text!))

                        if let bookmark = self.bookmarkToAdd {
                            let connection = OCConnection(bookmark: bookmark)
                            connection?.generateAuthenticationData(withMethod: OCAuthenticationMethodOAuth2Identifier,
                                                                   options: [:],
                                                                   completionHandler: { (error, authenticationMethodIdentifier, authenticationData) in

                                                                    if error != nil {
                                                                        print("error != nil")
                                                                    } else {
                                                                        bookmark.authenticationData = authenticationData!
                                                                        bookmark.authenticationMethodIdentifier = authenticationMethodIdentifier
                                                                    }

                            })
                        }
                    }
                }, title: "Continue", style: .proceed, identifier: "continue-button-row")
            ])
        self.addSection(continueButtonSection, animated: true)

    }
}
