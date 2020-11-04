//
//  PDFSearchResultsView.swift
//  ownCloud
//
//  Created by Michael Neuwert on 03.11.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
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
import PDFKit

typealias PDFSearchResultsViewCloseHandler = () -> Void
typealias PDFSearchResultsViewUpdateHandler = (PDFSelection) -> Void

class PDFSearchResultsView : UIStackView {

	private let closeButtton = UIButton()
	private let backButton = UIButton()
	private let forwardButton = UIButton()
	private let searchTermLabel = UILabel()

	private var currentIndex = -1

	var currentMatch: PDFSelection? {
		didSet {
			if let match = currentMatch, let matches = self.matches {
				if let index = matches.index(of: match) {
					currentIndex = index
					searchTermLabel.text = "Results \(index + 1) of \(matches.count)"
					backButton.isEnabled = currentIndex == 0 ? false : true
					forwardButton.isEnabled = currentIndex == matches.count - 1 ? false : true
				}
			}
		}
	}

	var matches: [PDFSelection]?
	var closeHandler: PDFSearchResultsViewCloseHandler?
	var updateHandler: PDFSearchResultsViewUpdateHandler?

	override init(frame: CGRect) {
		super.init(frame: .zero)
		self.axis = .horizontal

		self.backgroundColor = UIColor(white: 0.0, alpha: 0.2)

//		closeButtton.translatesAutoresizingMaskIntoConstraints = false
//		backButton.translatesAutoresizingMaskIntoConstraints = false
//		forwardButton.translatesAutoresizingMaskIntoConstraints = false
//		searchTermLabel.translatesAutoresizingMaskIntoConstraints = false

		addArrangedSubview(backButton)
		addArrangedSubview(searchTermLabel)
		addArrangedSubview(forwardButton)
		addArrangedSubview(closeButtton)

		closeButtton.addTarget(self, action: #selector(close), for: .touchUpInside)
		backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
		forwardButton.addTarget(self, action: #selector(forward), for: .touchUpInside)
	}

	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	@objc private func close() {
		closeHandler?()
	}

	@objc private func back() {
		guard currentIndex >= 0 else { return }
		if currentIndex > 0, let matches = self.matches {
			self.currentMatch = matches[currentIndex - 1]
			updateHandler?(self.currentMatch!)
		}
	}

	@objc private func forward() {
		guard currentIndex >= 0 else { return }
		if let matches = self.matches, currentIndex < (matches.count - 1) {
			self.currentMatch = matches[currentIndex - 1]
			updateHandler?(self.currentMatch!)
		}
	}
}
