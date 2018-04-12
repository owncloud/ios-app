//
//  main.swift
//  MakeTVG
//
//  Created by Felix Schwarz on 12.04.18.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import Foundation

func applyReplacementDict(svgString : String, replacementDict : NSDictionary, defaultValues: NSMutableDictionary) -> String {
	var newString : String = svgString

	replacementDict.enumerateKeysAndObjects { (searchFor, replaceWith, _) in
		let searchString : String? = searchFor as? String
		let replaceOpts : NSDictionary? = replaceWith as? NSDictionary

		if (searchString != nil) && (replaceOpts != nil) {
			let replaceSubString : String? = replaceOpts!["replace"] as? String
			let variableName : String? = replaceOpts!["variable"] as? String
			let variableString : String = "{{" + variableName! + "}}"
			var replaceString : String?
			var defaultValue : String?
			var adaptedString : String?

			if replaceSubString != nil {
				replaceString = searchString?.replacingOccurrences(of: replaceSubString!, with: variableString)
				defaultValue = replaceSubString
			} else {
				replaceString = variableString
				defaultValue = searchString
			}

			adaptedString = newString.replacingOccurrences(of: searchString!, with: replaceString!)

			if adaptedString != newString {
				defaultValues[variableName!] = defaultValue

				newString = adaptedString!
			}
		}
	}

	return newString
}

if CommandLine.argc < 3 {
	print("MakeTVG [make.json] [input directory] [output directory]")
} else {
	let jsonFileURL = URL.init(fileURLWithPath: CommandLine.arguments[1])
	let sourceDirectoryURL = URL.init(fileURLWithPath: CommandLine.arguments[2])
	let targetDirectoryURL = URL.init(fileURLWithPath: CommandLine.arguments[3])

	if let makeDict = (try JSONSerialization.jsonObject(with: Data.init(contentsOf: jsonFileURL), options: JSONSerialization.ReadingOptions(rawValue: 0))) as? NSDictionary {
		let sourceURLs : [URL] = (try FileManager.default.contentsOfDirectory(at: sourceDirectoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles))
		let globalReplacements : NSDictionary? = makeDict["*"] as? NSDictionary

		for sourceURL in sourceURLs {
			if sourceURL.pathExtension == "svg" {
				let defaultValuesForVariables : NSMutableDictionary = NSMutableDictionary()

				let fileReplacements : NSDictionary? = makeDict[sourceURL.lastPathComponent] as? NSDictionary
				var svgString : String = try String(contentsOf: sourceURL, encoding: .utf8)

				if fileReplacements != nil {
					svgString = applyReplacementDict(svgString: svgString, replacementDict: fileReplacements!, defaultValues: defaultValuesForVariables)
				}
				if globalReplacements != nil {
					svgString = applyReplacementDict(svgString: svgString, replacementDict: globalReplacements!, defaultValues: defaultValuesForVariables)
				}

				let tvgDict = [ "defaults" : defaultValuesForVariables, "image" : svgString ] as NSDictionary
				let tvgData : Data = try JSONSerialization.data(withJSONObject: tvgDict, options: JSONSerialization.WritingOptions.init(rawValue: 0))
				let tvgFileName = (((sourceURL.lastPathComponent as NSString).deletingPathExtension) as NSString).appendingPathExtension("tvg")
				let targetURL = targetDirectoryURL.appendingPathComponent(tvgFileName!, isDirectory: false)

				print ("Writing TVG version with " + String(defaultValuesForVariables.count) + " of " + sourceURL.lastPathComponent + " as " + targetURL.lastPathComponent)

				try tvgData.write(to: targetURL)

			}
		}
	}
}
