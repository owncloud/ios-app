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

class PDFSearchResultsView : UIView {

	let roundedCornerRadius: CGFloat = 8.0
	let stackViewSpacing: CGFloat = 8.0
	let overlayAlpha: CGFloat = 0.8

	private let closeButtton = UIButton()
	private let backButton = UIButton()
	private let forwardButton = UIButton()
	private let searchTermButton = UIButton()

	private let stackView = UIStackView()

	private var currentIndex = -1

	var currentMatch: PDFSelection? {
		didSet {
			if let match = currentMatch, let matches = self.matches {
				if let index = matches.index(of: match), let matchString = match.string {
					currentIndex = index
					let searchResultsText = "\(matchString) (" + String(format: "%@ of %@".localized, "\(index + 1)", "\(matches.count)") + ")"
					searchTermButton.setTitle(searchResultsText, for: .normal)
					backButton.isEnabled = currentIndex == 0 ? false : true
					forwardButton.isEnabled = currentIndex == matches.count - 1 ? false : true

					updateHandler?(match)
				}
			}
		}
	}

	var matches: [PDFSelection]?
	var closeHandler: PDFSearchResultsViewCloseHandler?
	var updateHandler: PDFSearchResultsViewUpdateHandler?

	override init(frame: CGRect) {
		super.init(frame: .zero)

		self.backgroundColor = UIColor.init(white: 0, alpha: overlayAlpha)
		self.layer.cornerRadius = roundedCornerRadius

		stackView.axis = .horizontal
		stackView.spacing = stackViewSpacing
		stackView.distribution = .equalSpacing
		stackView.translatesAutoresizingMaskIntoConstraints = false

		self.addSubview(stackView)

		let viewDictionary = ["stackView": stackView]
		var constraints: [NSLayoutConstraint] = []

		let vertical = NSLayoutConstraint.constraints(withVisualFormat: "V:|-[stackView]-|", metrics: nil, views: viewDictionary)
		let horizontal = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[stackView]-|", metrics: nil, views: viewDictionary)
		constraints += vertical
		constraints += horizontal
		NSLayoutConstraint.activate(constraints)

		stackView.addArrangedSubview(backButton)
		stackView.addArrangedSubview(searchTermButton)
		stackView.addArrangedSubview(forwardButton)
		stackView.addArrangedSubview(closeButtton)

		closeButtton.addTarget(self, action: #selector(close), for: .touchUpInside)
		backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
		forwardButton.addTarget(self, action: #selector(forward), for: .touchUpInside)

		if #available(iOS 13, *) {
			closeButtton.setImage(UIImage(systemName: "xmark")?.tinted(with: .white), for: .normal)
			backButton.setImage(UIImage(systemName: "chevron.left")?.tinted(with: .white), for: .normal)
			forwardButton.setImage(UIImage(systemName: "chevron.right")?.tinted(with: .white), for: .normal)
		} else {
			closeButtton.setImage(UIImage(named: "xmark")?.tinted(with: .white), for: .normal)
			backButton.setImage(UIImage(named: "chevron.left")?.tinted(with: .white), for: .normal)
			forwardButton.setImage(UIImage(named: "chevron.right")?.tinted(with: .white), for: .normal)
		}

		searchTermButton.titleLabel?.textColor = .white
		searchTermButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
		searchTermButton.titleLabel?.adjustsFontForContentSizeCategory = true
		searchTermButton.addTarget(self, action: #selector(resultsTextTapped), for: .touchUpInside)
		searchTermButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

		self.translatesAutoresizingMaskIntoConstraints = false
	}

	required init(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Button actions

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
			self.currentMatch = matches[currentIndex + 1]
			updateHandler?(self.currentMatch!)
		}
	}

	@objc private func resultsTextTapped() {
		if let match = self.currentMatch {
			updateHandler?(match)
		}
	}
}
