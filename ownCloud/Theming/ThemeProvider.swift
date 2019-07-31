//
//  ThemeProvider.swift
//  ownCloud
//
//  Created by Matthias Hühne on 31.07.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit

class ThemeProvider: NSObject {

	var genericColors : [String : String]?
	var themes : [[String : String]]?

	init(plist: String) {
		super.init()
		loadThemes(plist: plist)
	}

	func loadThemes(plist: String) {
		if let path = Bundle.main.path(forResource: plist, ofType: "plist") {
			if let themingValues = NSDictionary(contentsOfFile: path), let generic = themingValues["Generic"] as? [String : String], let themes = themingValues["Themes"] as? [[String : String]] {
				print("-->> \(themingValues)")
				self.genericColors = generic
				self.themes = themes
			}
		}
	}

}
