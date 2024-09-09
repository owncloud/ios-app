//
//  Log.swift
//  ownCloud
//
//  Created by Felix Schwarz on 09.03.18.
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

import UIKit

import ownCloudSDK

public extension OCLogLevel {
	var label : String {
		switch self {
			case .verbose:
 				return OCLocalizedString("Verbose", nil)
			case .debug:
				return OCLocalizedString("Debug", nil)
			case .info:
				return OCLocalizedString("Info", nil)
			case .warning:
				return OCLocalizedString("Warning", nil)
			case .error:
				return OCLocalizedString("Error", nil)
			case .off:
				return OCLocalizedString("Off", nil)
			default:
				return OCLocalizedString("Unknown", nil)
		}
	}
}

public class Log {
	static public var logOptionStatus : String {
		return "level=\(OCLogger.logLevel.label), destinations=\(OCLogger.shared.writers.filter({ (writer) -> Bool in writer.enabled}).map({ (writer) -> String in writer.identifier.rawValue })), options=\(OCLogger.shared.toggles.filter({ (toggle) -> Bool in toggle.enabled}).map({ (toggle) -> String in toggle.identifier.rawValue })), maskPrivateData=\( OCLogger.maskPrivateData ? "true" : "false" )"
	}

	static public func debug(tagged : [String]? = nil, _ message: String, _ parameters: CVarArg..., file: String = #file, functionName: String = #function, line: UInt = #line ) {
		withVaList(parameters) { va_list in
 			var tags : [String] = ["APP"]

			if tagged != nil {
				tags.append(contentsOf: tagged!)
			}

			OCLogger.shared.appendLogLevel(OCLogLevel.debug, functionName: functionName, file: file, line: line, tags: tags, message: message, arguments: va_list)
		}
	}

	static public func log(tagged : [String]? = nil, _ message: String, _ parameters: CVarArg..., file: String = #file, functionName: String = #function, line: UInt = #line ) {
		withVaList(parameters) { va_list in
 			var tags : [String] = ["APP"]

			if tagged != nil {
				tags.append(contentsOf: tagged!)
			}

			OCLogger.shared.appendLogLevel(OCLogLevel.info, functionName: functionName, file: file, line: line, tags: tags, message: message, arguments: va_list)
		}
	}

	static public func warning(tagged : [String]? = nil, _ message: String, _ parameters: CVarArg..., file: String = #file, functionName: String = #function, line: UInt = #line ) {
		withVaList(parameters) { va_list in
 			var tags : [String] = ["APP"]

			if tagged != nil {
				tags.append(contentsOf: tagged!)
			}

			OCLogger.shared.appendLogLevel(OCLogLevel.warning, functionName: functionName, file: file, line: line, tags: tags, message: message, arguments: va_list)
		}
	}

	static public func error(tagged : [String]? = nil, _ message: String, _ parameters: CVarArg..., file: String = #file, functionName: String = #function, line: UInt = #line ) {
		withVaList(parameters) { va_list in
 			var tags : [String] = ["APP"]

			if tagged != nil {
				tags.append(contentsOf: tagged!)
			}

			OCLogger.shared.appendLogLevel(OCLogLevel.error, functionName: functionName, file: file, line: line, tags: tags, message: message, arguments: va_list)
		}
	}

	static public func mask(_ obj: Any?) -> Any {
		return OCLogger.applyPrivacyMask(obj) ?? "(null)"
	}
}

extension OCLogger : ownCloudSDK.OCLogIntroFormat {
	public func logIntroFormat() -> String {
		return "{{stdIntro}}; Log options: \(Log.logOptionStatus)"
	}

	public func logHostCommit() -> String? {
		return GitInfo.app.versionInfo
	}
}
