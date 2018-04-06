//
//  Synchronized.swift
//  ownCloud
//
//  Created by Felix Schwarz on 06.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import Foundation

func OCSynchronized(_ obj: Any, block: () -> Void) {
	objc_sync_enter(obj)
	block()
	objc_sync_exit(obj)
}
