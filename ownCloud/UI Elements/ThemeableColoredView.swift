//
//  ThemeableColoredView.swift
//  ownCloud
//
//  Created by Matthias Hühne on 18.02.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit

class ThemeableColoredView: UIView, Themeable {

	// MARK: - Instance variables.
	
	var messageThemeApplierToken : ThemeApplierToken?
	
	
	override init(frame: CGRect) {
		
		super.init(frame: frame)
		
		Theme.shared.register(client: self, applyImmediately: true)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	
	deinit {
		Theme.shared.unregister(client: self)
		
		if messageThemeApplierToken != nil {
			Theme.shared.remove(applierForToken: messageThemeApplierToken)
			messageThemeApplierToken = nil
		}
	}
	
	// MARK: - Theme support
	
	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		
		self.backgroundColor = collection.navigationBarColors.backgroundColor
	}
	
}
