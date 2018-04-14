//
//  OCBookmark+Extension.swift
//  ownCloud
//
//  Created by Felix Schwarz on 14.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

extension OCBookmark {
	func shortName() -> String {
		if self.name != nil {
			return self.name
		} else if self.originURL?.host != nil {
			return self.originURL.host!
		} else if self.url?.host != nil {
			return self.url.host!
		}

		return "bookmark"
	}
}
