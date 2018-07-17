//
//  AsyncSequentialQueue.swift
//  ownCloud
//
//  Created by Felix Schwarz on 18.06.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2018, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import Foundation

typealias AsyncSequentialQueueJob = (_ completionHandler: @escaping () -> Void) -> Void
typealias AsyncSequentialQueueExecutor = (_ job: @escaping AsyncSequentialQueueJob, _ completionHandler: @escaping () -> Void) -> Void

class AsyncSequentialQueue {
	var executor : AsyncSequentialQueueExecutor = { (job, completionHandler) in
		DispatchQueue.main.async {
			job(completionHandler)
		}
	}

	private var queuedBlocks : [AsyncSequentialQueueJob] = []
	private var busy : Bool = false

	func async(_ job: @escaping AsyncSequentialQueueJob) {
		var runNextJob : Bool = false

		OCSynchronized(self) {
			queuedBlocks.append(job)

			if !busy {
				runNextJob = true
				busy = true
			}
		}

		if runNextJob {
			self.runNextJob()
		}
	}

	func runNextJob() {
		var nextJob : AsyncSequentialQueueJob?

		OCSynchronized(self) {
			if queuedBlocks.count > 0 {
				nextJob = queuedBlocks.remove(at: 0)
			} else {
				busy = false
			}
		}

		if let runJob = nextJob {
			executor(runJob, { self.runNextJob() })
		}
	}
}
