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
	print("MakeTVG --makefile [make.json] [--icon-ts icon.ts] [--web-theme theme.json] [--web-theme-filter-names [names]] [--file-filter only-matches] [--icon-map icon-map.json] [--legacy-input [old/app-specific icons folder]] --input [input folder] --output [output folder]")
} else {
	var iconMapURL, targetDirectoryURL: URL?
	var sourceURLs : [URL] = []
	var ocisIconTSFileURL, webThemeFileURL, colorYAMLFileURL: URL?
	var webThemeFilterNames: [String]?
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

				case "web-theme-filter-names":
					webThemeFilterNames = cmdArg.split(separator: ",").map({ subString in String.init(subString) })

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
				var processedThemes : Set<String> = []
				for theme in themes {
					// Filter theme names for white list
					let name = theme["name"] as? String
					if let webThemeFilterNames, let name {
						if !webThemeFilterNames.contains(name) {
							print ("Skipping theme \(name) (not in web-theme-filter-names)")
							continue
						}
					}

					// Exclude special modes (i.e. vault mode)
					let mode = theme["mode"] as? String
					if let mode, let name, mode != "" {
						print ("Skipping theme \(name) for mode \(mode)")
						continue
					}

					let isDark = theme["isDark"] as? Bool ?? false
					let styleName = isDark ? "dark" : "light"

					// Ensure only one (the first) theme for each style is used
					// - background: modern versions of the theme file contain multiple dark and light themes for different modes (f.ex. vault mode) and
					if processedThemes.contains(styleName) {
						print ("Skipping theme \(name ?? "unnamed") for color scheme \(styleName) as it is not the first for this color scheme")
						continue
					} else {
						processedThemes.insert(styleName)
					}

					if let colorPalette = theme.value(forKeyPath: "designTokens.colorPalette") as? [String:String] {
						for colorVar in colorPalette.keys {
							if let colorValue = colorPalette[colorVar] {
								var effectiveColorValue = colorValue
								if colorVariables[colorVar] == nil {
									colorVariables[colorVar] = [:]
								}

								if colorValue.hasPrefix("oklch") {
									if let convertedColorValue = oklchToRGB(colorValue) {
										print("Converted oklch-color from \(colorValue) to \(convertedColorValue)")
										effectiveColorValue = convertedColorValue
									}
								}

								colorVariables[colorVar]?[styleName] = effectiveColorValue
								print("Adding color for \(colorVar)/\(styleName) as '\(effectiveColorValue)' based on '\(webThemeFileURL.lastPathComponent)'")
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

					if effectiveColorValue.hasPrefix("oklch") {
						if let convertedColorValue = oklchToRGB(effectiveColorValue) {
							print("Converted oklch-color from \(effectiveColorValue) to \(convertedColorValue)")
							effectiveColorValue = convertedColorValue
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

// Helper function to convert oklch()-formatted colors to rgb()/rgba() equivalents
// Generated using Gemini 3.7 Flash on 2026-08-31 by Felix Schwarz

/// Converts a CSS `oklch(...)` string into standard `rgb(...)` or `rgba(...)` notation.
/// - Parameter oklchString: e.g. "oklch(13% 0.028 261.692)" or "oklch(0.6 0.15 180 / 0.8)"
/// - Returns: Formatted `rgb(...)` / `rgba(...)` string, or `nil` if parsing fails.
func oklchToRGB(_ oklchString: String) -> String? {
	let pattern = #"^oklch\(\s*([0-9.]+%?)\s+([0-9.]+%?)\s+([0-9.]+(?:deg|grad|rad|turn)?|none)(?:\s*\/\s*([0-9.]+%?))?\s*\)$"#
	guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
	      let match = regex.firstMatch(in: oklchString, range: NSRange(oklchString.startIndex..., in: oklchString)) else {
		return nil
	}

	func extractSubstring(at index: Int) -> String? {
		guard index < match.numberOfRanges else { return nil }
		let range = match.range(at: index)
		guard range.location != NSNotFound, let swiftRange = Range(range, in: oklchString) else { return nil }
		return String(oklchString[swiftRange])
	}

	// 1. Parse Lightness (0.0 ... 1.0 or 0% ... 100%)
	guard let lStr = extractSubstring(at: 1) else { return nil }
	let lightness: Double
	if lStr.hasSuffix("%") {
		lightness = (Double(lStr.dropLast()) ?? 0.0) / 100.0
	} else {
		lightness = Double(lStr) ?? 0.0
	}

	// 2. Parse Chroma (number or percentage where 100% = 0.4 in CSS Color 4)
	guard let cStr = extractSubstring(at: 2) else { return nil }
	let chroma: Double
	if cStr.hasSuffix("%") {
		chroma = ((Double(cStr.dropLast()) ?? 0.0) / 100.0) * 0.4
	} else {
		chroma = Double(cStr) ?? 0.0
	}

	// 3. Parse Hue (deg, rad, grad, turn, or unitless degrees)
	guard let hStr = extractSubstring(at: 3) else { return nil }
	let hueDegrees: Double
	if hStr.lowercased() == "none" {
		hueDegrees = 0.0
	} else if hStr.hasSuffix("deg") {
		hueDegrees = Double(hStr.dropLast(3)) ?? 0.0
	} else if hStr.hasSuffix("grad") {
		hueDegrees = (Double(hStr.dropLast(4)) ?? 0.0) * 0.9
	} else if hStr.hasSuffix("rad") {
		hueDegrees = (Double(hStr.dropLast(3)) ?? 0.0) * (180.0 / .pi)
	} else if hStr.hasSuffix("turn") {
		hueDegrees = (Double(hStr.dropLast(4)) ?? 0.0) * 360.0
	} else {
		hueDegrees = Double(hStr) ?? 0.0
	}

	// 4. Parse Alpha (optional, defaults to 1.0)
	let alpha: Double
	if let aStr = extractSubstring(at: 4) {
		if aStr.hasSuffix("%") {
			alpha = (Double(aStr.dropLast()) ?? 100.0) / 100.0
		} else {
			alpha = Double(aStr) ?? 1.0
		}
	} else {
		alpha = 1.0
	}

	// 5. Convert OKLCH to Oklab
	let hueRadians = hueDegrees * (.pi / 180.0)
	let a = chroma * cos(hueRadians)
	let b = chroma * sin(hueRadians)

	// 6. Convert Oklab to LMS
	let l_ = lightness + 0.3963377774 * a + 0.2158037573 * b
	let m_ = lightness - 0.1055613458 * a - 0.0638541728 * b
	let s_ = lightness - 0.0894841775 * a - 1.2914855480 * b

	let l = l_ * l_ * l_
	let m = m_ * m_ * m_
	let s = s_ * s_ * s_

	// 7. Convert LMS to Linear sRGB
	let rLinear = +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
	let gLinear = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
	let bLinear = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s

	// 8. sRGB Gamma Transfer function and Gamut Clamping
	func gammaEncode(_ value: Double) -> Int {
		let clampedLinear = max(0.0, min(1.0, value))
		let srgb: Double
		if clampedLinear <= 0.0031308 {
			srgb = 12.92 * clampedLinear
		} else {
			srgb = 1.055 * pow(clampedLinear, 1.0 / 2.4) - 0.055
		}
		let clampedSrgb = max(0.0, min(1.0, srgb))
		return Int(round(clampedSrgb * 255.0))
	}

	let r = gammaEncode(rLinear)
	let g = gammaEncode(gLinear)
	let bVal = gammaEncode(bLinear)

	// 9. Format output
	if alpha < 1.0 {
		let formattedAlpha = String(format: "%.3g", alpha)
		return "rgba(\(r), \(g), \(bVal), \(formattedAlpha))"
	} else {
		return "rgb(\(r), \(g), \(bVal))"
	}
}
