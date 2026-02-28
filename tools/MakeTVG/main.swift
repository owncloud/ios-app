//
//  main.swift
//  MakeTVG
//
//  Created by Felix Schwarz on 12.04.18.
//  Copyright © 2026 ownCloud GmbH. All rights reserved.
//

import Foundation

let DefaultFillAttribute = "_fill"
let DefaultStrokeAttribute = "_stroke"
let AlternativeFileName = "_altFileName"

func applyReplacementDict(svgString : String, replacementDict : NSDictionary, defaultValues: NSMutableDictionary, topLevelAttributes: NSMutableDictionary) -> String {
	var newString : String = svgString

	replacementDict.enumerateKeysAndObjects { (searchFor, replaceWith, _) in
		guard let searchString = searchFor as? String else { return }

		switch searchString {
			case DefaultFillAttribute:
				topLevelAttributes["fill"] = replaceWith
				return

			case DefaultStrokeAttribute:
				topLevelAttributes["stroke"] = replaceWith
				return

			default: break
		}

		if let replaceOpts = replaceWith as? NSDictionary {
			let replaceSubString : String? = replaceOpts["replace"] as? String
			let variableName : String? = replaceOpts["variable"] as? String
			let variableString : String = "{{" + (variableName ?? "") + "}}"
			let overwriteString : String? = replaceOpts["overwrite"] as? String
			var replaceString : String?
			var searchStringUpper : String?
			var defaultValue : String?
			var adaptedString : String?

			if let overwriteString {
				newString = newString.replacingOccurrences(of: searchString, with: overwriteString)
				return
			} else  if replaceSubString != nil {
				replaceString = searchString.replacingOccurrences(of: replaceSubString!, with: variableString)
				searchStringUpper = searchString.replacingOccurrences(of: replaceSubString!, with: replaceSubString!.uppercased())
				defaultValue = replaceSubString
			} else {
				replaceString = variableString
				defaultValue = searchString
			}

			adaptedString = newString.replacingOccurrences(of: searchString, with: replaceString!)

			if let searchStringUpper, let replaceString {
				adaptedString = adaptedString!.replacingOccurrences(of: searchStringUpper, with: replaceString)
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

					case "viewbox":
						let viewBoxComponents = value.replacingOccurrences(of: " ", with: "").split(separator: ",")
						if viewBoxComponents.count == 4 {
							if originX == nil	{ originX = Double(viewBoxComponents[0]) }
							if originY == nil	{ originY = Double(viewBoxComponents[1]) }
							if sizeWidth == nil	{ sizeWidth = Double(viewBoxComponents[2]) }
							if sizeHeight == nil	{ sizeHeight = Double(viewBoxComponents[3]) }
						}

		   			default: break
				}
			}
		}

		var viewBoxRect : CGRect?

		if sizeWidth != nil, sizeHeight != nil {
			viewBoxRect = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: sizeWidth!, height: sizeHeight!))

			if originX != nil, originY != nil {
				viewBoxRect?.origin = CGPoint(x: originX!, y: originY!)
			}

			return ["viewBox" : NSStringFromRect(viewBoxRect!)]
		}
	}

	return nil
}

class YAMLParser {
	private var lines: [String]
	private var offset: Int = 0

	var yamlTree: NSMutableDictionary = [:]

	init(yamlData: Data) {
		if let yamlString = String(bytes: yamlData, encoding: .utf8) {
			lines = yamlString.components(separatedBy: .newlines).map { $0.replacingOccurrences(of: "\r", with: "") }
		} else {
			lines = []
		}
	}

	func parse() {
		parseSlice(baseIndentLevel: 0, addTo: &yamlTree)
	}

	func parseSlice(baseIndentLevel: Int, addTo treeSlice: inout NSMutableDictionary) {
		var lastKey: String?

		while offset < lines.count {
			let line = lines[offset]
			let indentLevel = line.prefix(while: { $0 == " " }).count
			let unindentedLine = line.trimmingPrefix(while: { $0 == " " })

			if unindentedLine.hasPrefix("--") || unindentedLine.hasPrefix("#") {
				offset += 1
				continue
			}

			let splitComponents = unindentedLine.components(separatedBy: ":")
			let lineKey = splitComponents[0]
			let lineValue = splitComponents.count > 1 ? splitComponents[1].trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "\"'")) : nil

			if baseIndentLevel == indentLevel {
				if let lineValue {
					treeSlice[lineKey] = lineValue
				}
				offset += 1
			} else if baseIndentLevel > indentLevel {
				// Segment ended, return
				return
			} else if indentLevel > baseIndentLevel, let lastKey {
				// New subsegment began
				var sliceDict: NSMutableDictionary = NSMutableDictionary()
				parseSlice(baseIndentLevel: indentLevel, addTo: &sliceDict)
				treeSlice[lastKey] = sliceDict
				continue
			}

			lastKey = lineKey
		}
	}
}

if CommandLine.argc < 3 {
	print("MakeTVG --makefile [make.json] [--icon-ts icon.ts] [--web-theme theme.json] [--file-filter only-matches] [--icon-map icon-map.json] [--legacy-input [old/app-specific icons folder]] --input [input folder] --output [output folder]")
} else {
	var iconMapURL, targetDirectoryURL: URL?
	var sourceURLs : [URL] = []
	var ocisIconTSFileURL, webThemeFileURL, colorYAMLFileURL: URL?
	var fileFilter: String?
	var makeDict: NSMutableDictionary?

	var optName: String?

	for cmdArg in CommandLine.arguments {
		if optName != nil {
			switch optName! {
				case "makefile":
					let jsonFileURL = URL(fileURLWithPath: cmdArg)
					makeDict = (try JSONSerialization.jsonObject(with: Data(contentsOf: jsonFileURL), options: [ .json5Allowed, .mutableContainers ])) as? NSMutableDictionary

				case "icon-ts":
					ocisIconTSFileURL = URL(fileURLWithPath: cmdArg)

				case "web-theme":
					webThemeFileURL = URL(fileURLWithPath: cmdArg)

				case "color-yaml":
					colorYAMLFileURL = URL(fileURLWithPath: cmdArg)

				case "file-filter":
					fileFilter = cmdArg

				case "icon-map":
					iconMapURL = URL(fileURLWithPath: cmdArg)

				case "input", "legacy-input":
					let sourceDirectoryURL = URL(fileURLWithPath: cmdArg)
					if let fileURLs = try? FileManager.default.contentsOfDirectory(at: sourceDirectoryURL, includingPropertiesForKeys: nil, options: .skipsHiddenFiles) {
						sourceURLs.append(contentsOf: fileURLs.filter({ url in sourceURLs.first(where: { $0.lastPathComponent == url.lastPathComponent }) == nil }))
						if optName == "legacy-input" {
							for fileURL in fileURLs {
								if makeDict?[fileURL.lastPathComponent] == nil {
									makeDict?[fileURL.lastPathComponent] = NSMutableDictionary()
								}
							}
						}
					}

				case "output":
					targetDirectoryURL = URL(fileURLWithPath: cmdArg)

				default:
					print("Ignoring unknown parameter/value pair: \(optName!)=\(cmdArg)")
			}

			optName = nil
		} else {
			if cmdArg.starts(with: "--") {
				optName = String(cmdArg.dropFirst(2))
			}
		}
	}

	guard let makeDict, sourceURLs.count > 0, let targetDirectoryURL else {
		print("Parameters missing")
		exit(1)
	}

	let globalReplacements : NSMutableDictionary? = (makeDict["*"] as? NSMutableDictionary) ?? NSMutableDictionary()
	var colorVariables: [String:[String:String]] = [:]
	var suffixIconMap: [String:String] = [:]
	var fileTypeIconMap: [String:String] = [:]

	let iconTableAdditions = makeDict[".icon-defs"] as? [AnyHashable : Any]
	makeDict.removeObject(forKey: ".icon-defs")

	let remapIcons = makeDict[".remap-icons"] as? [AnyHashable : Any]
	makeDict.removeObject(forKey: ".remap-icons")

	let typeIconMap = makeDict[".type-icon-map"] as? [String : String]
	if let typeIconMap {
		// Add manual type-icon map
		fileTypeIconMap = typeIconMap
	}
	makeDict.removeObject(forKey: ".type-icon-map")

	if let webThemeFileURL, let webThemeData = try? Data(NSData(contentsOf: webThemeFileURL)) {
		// Extract colors from theme.json
		if let webTheme = try? JSONSerialization.jsonObject(with: webThemeData, options: [.json5Allowed]) as? NSDictionary {
			if let themes = webTheme.value(forKeyPath: "clients.web.themes") as? [NSDictionary] {
				for theme in themes {
					let isDark = theme["isDark"] as? Bool ?? false
					let styleName = isDark ? "dark" : "light"
					if let colorPalette = theme.value(forKeyPath: "designTokens.colorPalette") as? [String:String] {
						for colorVar in colorPalette.keys {
							if let colorValue = colorPalette[colorVar] {
								if colorVariables[colorVar] == nil {
									colorVariables[colorVar] = [:]
								}
								colorVariables[colorVar]?[styleName] = colorValue
								print("Adding color for \(colorVar)/\(styleName) as '\(colorValue)' based on '\(webThemeFileURL.lastPathComponent)'")
							}
						}
					}
				}
			}
		}
	}

	if let colorYAMLFileURL, let colorYAMLData = try? Data(NSData(contentsOf: colorYAMLFileURL)) {
		// Add colors missing from theme.json from the design system's color.yaml
		let parser = YAMLParser(yamlData: colorYAMLData)
		parser.parse()
		if let colors = parser.yamlTree["color"] as? [String:Any],
		   let icons = colors["icon"] as? [String:Any] {
			for iconColorName in icons.keys {
				if let iconColorValue = (icons[iconColorName] as? [String:Any])?["value"] as? String,
				   colorVariables["icon-" + iconColorName] == nil {
				   	var effectiveColorValue = iconColorValue
				   	var resolveCount = 0

					while effectiveColorValue.hasPrefix("{"), effectiveColorValue.hasSuffix("}"), resolveCount < 100 {
						if let resolvedColor = parser.yamlTree.value(forKeyPath: effectiveColorValue.trimmingCharacters(in: CharacterSet(charactersIn: "{}")) + ".value") as? String {
							effectiveColorValue = resolvedColor
							resolveCount += 1
						}
					}

				   	colorVariables["icon-" + iconColorName] = [
				   		"dark": effectiveColorValue,
				   		"light": effectiveColorValue
					]

					print("Adding color for icon-\(iconColorName) as '\(effectiveColorValue)' for dark/light mode based on '\(colorYAMLFileURL.lastPathComponent)'")
				}
			}
		}
	}

	if let ocisIconTSFileURL {
		// Read icon.ts
		let iconTSContents = try? NSString(contentsOf: ocisIconTSFileURL, encoding: NSUTF8StringEncoding) as String
		var fileIconTable: Any?
		if let iconTSContents {
			let fileIconMatch = #/const fileIcon =\s*({[\s\S]+?})\s+export/#
			let fileIconJSON = iconTSContents.firstMatch(of: fileIconMatch)?.1

			if let fileIconJSONData = fileIconJSON?.data(using: .utf8) {
				fileIconTable = try? JSONSerialization.jsonObject(with: fileIconJSONData, options: [.json5Allowed, .mutableContainers])
			}
		}

		if let fileIconTable = fileIconTable as? NSMutableDictionary {
			if let iconTableAdditions {
				fileIconTable.addEntries(from: iconTableAdditions)
			}

			for fileType in fileIconTable.allKeys {
				if let fileType = fileType as? String,
				   let typeInfo = fileIconTable[fileType] as? NSDictionary,
				   let iconAttributes = typeInfo["icon"] as? NSDictionary,
				   let iconName = iconAttributes["name"] as? String,
				   let iconColor = iconAttributes["color"] as? String {
					let iconColorVarName = iconColor.replacingOccurrences(of: "var(--oc-color-", with: "").replacingOccurrences(of: ")", with: "")

					if let defaultColors = colorVariables[iconColorVarName] {
						let svgFileName = iconName + "-fill.svg"
						let tvgFileName = ((remapIcons?[fileType] as? String) ?? fileType) + ".tvg"
						var defaultFill = defaultColors

						defaultFill["variable"] = "\(iconColorVarName)"

						if let extensions = typeInfo["extensions"] as? NSArray {
							for suffix in extensions {
								if let suffix = suffix as? String {
									suffixIconMap[suffix] = tvgFileName
								}
							}
						}

						if let fileTypes = typeInfo["fileTypes"] as? NSArray {
							for fileType in fileTypes {
								if let fileType = fileType as? String {
									fileTypeIconMap[fileType] = tvgFileName
								}
							}
						}

						if sourceURLs.first(where: { url in url.lastPathComponent == svgFileName }) == nil {
							print("⚠️ Referenced source file \(svgFileName) not found")
						}

						makeDict[svgFileName] = [
							DefaultFillAttribute: defaultFill,
							AlternativeFileName: tvgFileName
						]
					}
				}
			}
		} else {
			print("MakeTVG: Could not extract fileIcon from \(ocisIconTSFileURL.path)")
			exit(1)
		}
	}

	for sourceURL in sourceURLs {
		if let fileFilter {
			if fileFilter == "only-matches" {
				if makeDict[sourceURL.lastPathComponent] == nil {
					continue
				}
			}
		}

		if sourceURL.pathExtension == "svg" {
			let defaultValuesForVariables: NSMutableDictionary = NSMutableDictionary()
			let topLevelAttributes: NSMutableDictionary = NSMutableDictionary()

			let fileReplacements : NSDictionary? = makeDict[sourceURL.lastPathComponent] as? NSDictionary
			var svgString : String = try String(contentsOf: sourceURL, encoding: .utf8)

			// Apply replacements
			if fileReplacements != nil {
				svgString = applyReplacementDict(svgString: svgString, replacementDict: fileReplacements!, defaultValues: defaultValuesForVariables, topLevelAttributes: topLevelAttributes)
			}
			if globalReplacements != nil {
				svgString = applyReplacementDict(svgString: svgString, replacementDict: globalReplacements!, defaultValues: defaultValuesForVariables, topLevelAttributes: topLevelAttributes)
			}

			// Start TVG dict
			var tvgBaseDict : [String:Any] = [ "defaults" : defaultValuesForVariables, "image" : svgString]

			// Merge in top level attributes
			if topLevelAttributes.count > 0 {
				tvgBaseDict["attributes"] = topLevelAttributes
			}

			// Extract viewBox from <svg> root attributes
			if let rootAttributes = extractRootAttributes(from: svgString) {
				if let viewBoxString = rootAttributes["viewBox"] {
					tvgBaseDict["viewBox"] = viewBoxString
				}
			}

			// Convert and save
			let tvgDict = tvgBaseDict as NSDictionary
			let tvgData : Data = try JSONSerialization.data(withJSONObject: tvgDict, options: [.sortedKeys])
			let tvgFileName = fileReplacements?[AlternativeFileName] as? String ?? (((sourceURL.lastPathComponent as NSString).deletingPathExtension) as NSString).appendingPathExtension("tvg")
			let targetURL = targetDirectoryURL.appendingPathComponent(tvgFileName!, isDirectory: false)

			print("Writing TVG with " + String(defaultValuesForVariables.count) + " changes, based on " + sourceURL.path + ", to " + targetURL.lastPathComponent)

			try tvgData.write(to: targetURL)
		}
	}

	// Write icon map
	if let iconMapURL {
		// Sanitize maps
		fileTypeIconMap = fileTypeIconMap.filter( { (fileType, iconFileName) in
			let fileURL = targetDirectoryURL.appendingPathComponent(iconFileName, isDirectory: false)
			if FileManager.default.fileExists(atPath: fileURL.path) { return true }

			print("Removing \(fileType):\(iconFileName) from type:icon map as the corresponding file does not exist at \(fileURL.path).")

			return false
		})

		suffixIconMap = suffixIconMap.filter( { (suffix, iconFileName) in
			let fileURL = targetDirectoryURL.appendingPathComponent(iconFileName, isDirectory: false)
			if FileManager.default.fileExists(atPath: fileURL.path) { return true }

			print("Removing \(suffix):\(iconFileName) from file:icon map as the corresponding file does not exist at \(fileURL.path)")

			return false
		})

		// Write
		try? (try? JSONSerialization.data(withJSONObject: [
			"by-type": fileTypeIconMap,
			"by-suffix": suffixIconMap
		], options: [.sortedKeys]))?.write(to: iconMapURL)
	}
}
