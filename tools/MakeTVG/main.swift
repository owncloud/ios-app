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
			var searchStringUpper : String?
			var defaultValue : String?
			var adaptedString : String?

			if replaceSubString != nil {
				replaceString = searchString?.replacingOccurrences(of: replaceSubString!, with: variableString)
				searchStringUpper = searchString?.replacingOccurrences(of: replaceSubString!, with: replaceSubString!.uppercased())
				defaultValue = replaceSubString
			} else {
				replaceString = variableString
				defaultValue = searchString
			}

			adaptedString = newString.replacingOccurrences(of: searchString!, with: replaceString!)

			if searchStringUpper != nil {
				adaptedString = adaptedString!.replacingOccurrences(of: searchStringUpper!, with: replaceString!)
			}

			if adaptedString != newString {
				defaultValues[variableName!] = defaultValue

				newString = adaptedString!
			}
		}
	}

	return newString
}

func extractRootAttributes(from svgString: String) -> [String:String]? {
	var originX : Double?, originY: Double?, sizeWidth: Double?, sizeHeight: Double?

	if let svgStartRange = svgString.range(of: "<svg", options: .caseInsensitive),
	   let svgEndRange = svgString.range(of: ">", options: .caseInsensitive, range: Range<String.Index>(uncheckedBounds: (lower: svgStartRange.upperBound, upper: svgString.endIndex))) {
		let svgAttributesString = svgString[Range<String.Index>(uncheckedBounds: (lower: String.Index(encodedOffset: svgStartRange.upperBound.encodedOffset+1), upper: svgEndRange.lowerBound))]
		let attributePairs = svgAttributesString.components(separatedBy: "\" ")

		for attributePair in attributePairs {
			let keyValueArray = attributePair.split(separator: "=")

			if keyValueArray.count == 2 {
				var key : String = String(keyValueArray[0])
				var value = keyValueArray[1]
				var subRange = Range<String.Index>(uncheckedBounds: (lower: value.startIndex, upper: value.endIndex))

			   	if value.hasPrefix("\"") {
			   		subRange = Range<String.Index>(uncheckedBounds: (lower: String.Index(encodedOffset: subRange.lowerBound.encodedOffset+1), upper: subRange.upperBound))
				}

			   	if value.hasSuffix("\"") {
			   		subRange = Range<String.Index>(uncheckedBounds: (lower: subRange.lowerBound, upper: String.Index(encodedOffset: subRange.upperBound.encodedOffset-1)))
				}

		   		value = value[subRange]

		   		key = key.lowercased()

		   		switch key {
		   			case "x":
		   				originX = Double(value)

		   			case "y":
		   				originY = Double(value)

		   			case "width":
		   				sizeWidth = Double(value)

		   			case "height":
		   				sizeHeight = Double(value)

		   			default: break
				}
			}
		}

		var viewBoxRect : CGRect?

		if sizeWidth != nil, sizeHeight != nil {
			viewBoxRect = CGRect(origin: .zero, size: CGSize(width: sizeWidth!, height: sizeHeight!))

			if originX != nil, originY != nil {
				viewBoxRect?.origin = CGPoint(x: originX!, y: originY!)
			}

			return ["viewBox" : NSStringFromRect(viewBoxRect!)]
		}
	}

	return nil
}

if CommandLine.argc < 3 {
	print("MakeTVG [make.json] [input directory] [output directory]")
} else {
	let jsonFileURL = URL(fileURLWithPath: CommandLine.arguments[1])
	let sourceDirectoryURL = URL(fileURLWithPath: CommandLine.arguments[2])
	let targetDirectoryURL = URL(fileURLWithPath: CommandLine.arguments[3])

	if let makeDict = (try JSONSerialization.jsonObject(with: Data(contentsOf: jsonFileURL), options: JSONSerialization.ReadingOptions(rawValue: 0))) as? NSDictionary {
		let sourceURLs : [URL] = (try FileManager.default.contentsOfDirectory(at: sourceDirectoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles))
		let globalReplacements : NSDictionary? = makeDict["*"] as? NSDictionary

		for sourceURL in sourceURLs {
			if sourceURL.pathExtension == "svg" {
				let defaultValuesForVariables : NSMutableDictionary = NSMutableDictionary()

				let fileReplacements : NSDictionary? = makeDict[sourceURL.lastPathComponent] as? NSDictionary
				var svgString : String = try String(contentsOf: sourceURL, encoding: .utf8)

				// Apply replacements
				if fileReplacements != nil {
					svgString = applyReplacementDict(svgString: svgString, replacementDict: fileReplacements!, defaultValues: defaultValuesForVariables)
				}
				if globalReplacements != nil {
					svgString = applyReplacementDict(svgString: svgString, replacementDict: globalReplacements!, defaultValues: defaultValuesForVariables)
				}

				// Start TVG dict
				var tvgBaseDict : [String:Any] = [ "defaults" : defaultValuesForVariables, "image" : svgString]

				// Extract viewBox from <svg> root attributes
				if let rootAttributes = extractRootAttributes(from: svgString) {
					if let viewBoxString = rootAttributes["viewBox"] {
						tvgBaseDict["viewBox"] = viewBoxString
					}
				}

				// Convert and save
				let tvgDict = tvgBaseDict as NSDictionary
				let tvgData : Data = try JSONSerialization.data(withJSONObject: tvgDict, options: JSONSerialization.WritingOptions(rawValue: 0))
				let tvgFileName = (((sourceURL.lastPathComponent as NSString).deletingPathExtension) as NSString).appendingPathExtension("tvg")
				let targetURL = targetDirectoryURL.appendingPathComponent(tvgFileName!, isDirectory: false)

				print("Writing TVG with " + String(defaultValuesForVariables.count) + " changes, based on " + sourceURL.lastPathComponent + ", to " + targetURL.lastPathComponent)

				try tvgData.write(to: targetURL)

			}
		}
	}
}
