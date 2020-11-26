//
//  ClientFooterCollectionReusableView.swift
//  ownCloudAppShared
//
//  Created by Matthias Hühne on 25.11.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

import UIKit

class ClientFooterCollectionReusableView: ThemeCollectionReusableView {

	var quotaLabel = UILabel()

	override init(frame: CGRect) {
		super.init(frame: frame)
		self.prepareViewAndConstraints()
	}

	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)!
		self.prepareViewAndConstraints()
	}

	private func prepareViewAndConstraints() {
		quotaLabel.textAlignment = .center
		quotaLabel.font = UIFont.systemFont(ofSize: UIFont.smallSystemFontSize)
		quotaLabel.numberOfLines = 0
		quotaLabel.translatesAutoresizingMaskIntoConstraints = false

		self.addSubview(quotaLabel)
		NSLayoutConstraint.activate([
			quotaLabel.leftAnchor.constraint(equalTo: self.leftAnchor),
			quotaLabel.rightAnchor.constraint(equalTo: self.rightAnchor),
			quotaLabel.topAnchor.constraint(equalTo: self.topAnchor),
			quotaLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor)
		])
	}

	public func updateFooter(text:String?) {
		let labelText = text ?? ""
		self.quotaLabel.text = labelText
	}

	// MARK: - Theme support
	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		super.applyThemeCollection(theme: theme, collection: collection, event: event)

		self.quotaLabel.textColor = collection.tableRowColors.secondaryLabelColor
	}
}

