//
//  DummyBackgroundTaskAction.swift
//  ownCloud
//
//  Created by Michael Neuwert on 13.06.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import Foundation
import ownCloudSDK

class DummyBackgroundTaskAction : ScheduledTaskAction {
	override class var identifier : OCExtensionIdentifier? { return OCExtensionIdentifier("com.owncloud.action.copy") }
	override class var locations : [OCExtensionLocationIdentifier]? { return [.appBackgroundFetch] }
	override class var features : [String : Any]? { return [ FeatureKeys.runOnWifi : true] }

	override func run(background:Bool) {

		self.completion = { (task) in
			print("*** DUMMY TASK COMPLETED with Result: \(task.result)")
		}

		super.run(background: background)

		print("*************************************************")
		print("******    DUMMY BACKGROUND TASK RUN      ********")
		print("*************************************************")

		self.result = .success("Blah blah")

		completed()
	}

}
