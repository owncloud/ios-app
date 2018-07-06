//
//  MockingAliases.swift
//  ownCloudTests
//
//  Created by Felix Schwarz on 06.07.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

#if OCMOCK

typealias OCCore = MOCCore
typealias OCQuery = MOCQuery
typealias OCItem = MOCItem

#endif /* OCMOCK */
