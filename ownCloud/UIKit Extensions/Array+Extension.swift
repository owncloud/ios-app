//
//  Array+Extension.swift
//  ownCloud
//
//  Created by Matthias Hühne on 15.05.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2019, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import Foundation

extension Array {
	func unique<T:Hashable>(map: ((Element) -> (T))) -> [Element] {
		var set = Set<T>()
		var arrayOrdered = [Element]()
		for value in self {
			if !set.contains(map(value)) {
				set.insert(map(value))
				arrayOrdered.append(value)
			}
		}

		return arrayOrdered
	}
}
