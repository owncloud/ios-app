//
//  Log.swift
//  ownCloud
//
//  Created by Felix Schwarz on 09.03.18.
//  Copyright © 2018 ownCloud. All rights reserved.
//

import UIKit

import ownCloudSDK

class Log : NSObject {
	static func debug(_ message: String, _ parameters: CVarArg..., file: String = #file, functionName: String = #function, line: UInt = #line ) {
		withVaList(parameters) { va_list in
			OCLogger.shared().appendLogLevel(OCLogLevel.debug, functionName: functionName, file: file, line: line, message: message, arguments: va_list)
		}
	}

	static func log(_ message: String, _ parameters: CVarArg..., file: String = #file, functionName: String = #function, line: UInt = #line ) {
		withVaList(parameters) { va_list in
			OCLogger.shared().appendLogLevel(OCLogLevel.default, functionName: functionName, file: file, line: line, message: message, arguments: va_list)
		}
	}

	static func warning(_ message: String, _ parameters: CVarArg..., file: String = #file, functionName: String = #function, line: UInt = #line ) {
		withVaList(parameters) { va_list in
			OCLogger.shared().appendLogLevel(OCLogLevel.warning, functionName: functionName, file: file, line: line, message: message, arguments: va_list)
		}
	}

	static func error(_ message: String, _ parameters: CVarArg..., file: String = #file, functionName: String = #function, line: UInt = #line ) {
		withVaList(parameters) { va_list in
			OCLogger.shared().appendLogLevel(OCLogLevel.error, functionName: functionName, file: file, line: line, message: message, arguments: va_list)
		}
	}

	static func mask(_ obj: Any?) -> Any {
		return (OCLogger.shared().applyPrivacyMask(obj))
	}
}
