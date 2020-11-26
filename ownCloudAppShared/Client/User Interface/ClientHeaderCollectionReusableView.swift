//
//  ClientHeaderCollectionReusableView.swift
//  ownCloudAppShared
//
//  Created by Matthias Hühne on 25.11.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

import UIKit

class ClientHeaderCollectionReusableView: ThemeCollectionReusableView {

	override init(frame: CGRect) {
		super.init(frame: frame)
	}

	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)!
	}
}
