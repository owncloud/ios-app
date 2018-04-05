//
//  OCURL.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 20/03/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import Foundation
import ownCloudSDK

class OCURL {

    static func generateURL(user: inout NSString?, password: inout NSString?, url: inout String, procotolAppended: inout ObjCBool) -> NSURL {
        return NSURL(username: &user, password: &password, afterNormalizingURLString: url, protocolWasPrepended: &procotolAppended)
    }
}
