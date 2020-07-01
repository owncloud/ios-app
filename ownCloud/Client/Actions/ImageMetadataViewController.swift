//
//  ImageMetadataViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 29.06.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2020, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit

class ImageMetadataParser {

	typealias MetadataValueTransformer = (Any) -> MetadataItem

	static let shared = ImageMetadataParser()

	enum MetadataParseError : Error {
		case InvailidInput
		case MetadataMissing
	}

	enum MetadataSectionIdentifier : CaseIterable, CustomStringConvertible {

		case cameraDetails
		case captureParameters
		case timestamps
		case imageDetails

		var description: String {
			switch self {
			case .cameraDetails:
				return "Camera details".localized
			case .captureParameters:
				return "Capture settings".localized
			case .timestamps:
				return "Time".localized
			case .imageDetails:
				return "Image details".localized
			}
		}

		var sectionKey: String? {
			if self == .imageDetails {
				return nil
			} else {
				return kCGImagePropertyExifDictionary as String
			}
		}
	}

	struct MetadataSection {
		var identifier: MetadataSectionIdentifier
		var items: [MetadataItem]
	}

	struct MetadataItem {
		var name: String
		var value: String
	}

	private lazy var itemMapping: [MetadataSectionIdentifier : [CFString]] = {
		var mapping = [MetadataSectionIdentifier : [CFString]]()

		mapping[.cameraDetails] = [
			kCGImagePropertyExifLensMake,
			kCGImagePropertyExifLensModel,
			kCGImagePropertyExifAuxLensInfo]
		mapping[.captureParameters] = [
			kCGImagePropertyExifFocalLength,
			kCGImagePropertyExifShutterSpeedValue,
			kCGImagePropertyExifApertureValue,
			kCGImagePropertyExifISOSpeed,
			kCGImagePropertyExifExposureProgram,
			kCGImagePropertyExifMeteringMode,
			kCGImagePropertyExifExposureBiasValue,
			kCGImagePropertyExifFlash,
			kCGImagePropertyExifWhiteBalance,
			kCGImagePropertyExifColorSpace
			]
		mapping[.timestamps] = [
			kCGImagePropertyExifDateTimeOriginal,
			kCGImagePropertyExifDateTimeDigitized
		]
		mapping[.imageDetails] = [
			kCGImagePropertyProfileName,
			kCGImagePropertyPixelHeight,
			kCGImagePropertyPixelWidth,
			kCGImagePropertyDPIHeight,
			kCGImagePropertyDPIWidth]

		return mapping
	}()

	private lazy var valueTransformers: [CFString : MetadataValueTransformer] = {
		var transformers = [CFString : MetadataValueTransformer]()

		// Camera Details
		transformers[kCGImagePropertyExifLensMake] = {(value) in return MetadataItem(name: "Camera make".localized, value: value as? String ?? "") }

		transformers[kCGImagePropertyExifLensModel] = {(value) in return MetadataItem(name: "Camera model".localized, value: value as? String ?? "") }

		transformers[kCGImagePropertyExifAuxLensInfo] = {(value) in return MetadataItem(name: "Camera aux".localized, value: value as? String ?? "") }

		// Capture parameters
		transformers[kCGImagePropertyExifFocalLength] = {(value)
			in return MetadataItem(name: "Focal length".localized, value: "\(value)") }

		transformers[kCGImagePropertyExifShutterSpeedValue] = {(value)
			in return MetadataItem(name: "Shutter speed".localized, value: "\(value)") }

		transformers[kCGImagePropertyExifApertureValue] = {(value)
			in return MetadataItem(name: "Aperture".localized, value: "\(value)") }

		transformers[kCGImagePropertyExifISOSpeed] = {(value)
			in return MetadataItem(name: "ISO".localized, value: "\(value)") }

		transformers[kCGImagePropertyExifExposureProgram] = {(value) in

			var program = ""

			if let programType = value as? Int {
				switch programType {
				case 0: program = "Not defined"
				case 1: program = "Manual"
				case 2: program = "Normal"
				case 3: program = "Aperture priority"
				case 4: program = "Shutter priority"
				case 5: program = "Creative"
				case 6: program = "Action"
				case 7: program = "Portrait"
				case 8: program = "Landscape"

				default: break
				}
			}

			return MetadataItem(name: "Program".localized, value: program)
		}

		transformers[kCGImagePropertyExifMeteringMode] = {(value)
				in
			var item = MetadataItem(name: "Metering".localized, value: "")

			guard let mode = value as? Int else { return item }

			var modeString = "unknown".localized
			switch mode {
			case 1: modeString = "Average"
			case 2: modeString = "CenterWeightedAverage"
			case 3: modeString = "Spot"
			case 4: modeString = "MultiSpot"
			case 5: modeString = "Pattern"
			case 6: modeString = "Partial"
			case 255: modeString = "CenterWeightedAverage"
			default: break
			}

			return MetadataItem(name: "Metering".localized, value: modeString)
		}

		transformers[kCGImagePropertyExifExposureBiasValue] = {(value)
				in return MetadataItem(name: "Exposure bias".localized, value: "\(value)") }

		transformers[kCGImagePropertyExifFlash] = {(value)
			in
			var flashInfo = [String]()
			if let flashBitMask = value as? UInt16 {
				let flashPresent = flashBitMask & 0b100000 != 0
				if flashPresent {
					// Did flash fire?
					if flashBitMask & 0b01 != 0 {
						flashInfo.append("Fired")
					} else {
						flashInfo.append("Didn't fire")
					}

					switch (flashBitMask >> 1) & 0b11 {
					case 0b00: flashInfo.append("No strobe return detection")
					case 0b10: flashInfo.append("Strobe return light not detected")
					case 0b11: flashInfo.append("Strobe return light detected")
					default: break
					}

					switch (flashBitMask >> 3) & 0b11 {
					case 0b01: flashInfo.append("Compulsory flash firing")
					case 0b10: flashInfo.append("Compulsory flash supression")
					case 0b11: flashInfo.append("Auto mode")
					default: break
					}

					if flashBitMask  & 0b1000000 != 0 {
						flashInfo.append("Red eye detection supported")
					}

				} else {
					flashInfo.append("not present")
				}

			}

			return MetadataItem(name: "Flash".localized, value: flashInfo.joined(separator: ", "))
		}

		transformers[kCGImagePropertyExifWhiteBalance] = {(value)
			in
			// 0 - Auto, 1 - Manual
			var wbMode = ""
			if let wb = value as? Int {
				switch wb {
				case 0: wbMode = "Auto"
				case 1: wbMode = "Manual"
				default: break
				}
			}
			return MetadataItem(name: "White balance".localized, value: wbMode)
		}

		transformers[kCGImagePropertyExifColorSpace] = {(value) in

			var space = "Uncalibrated"
			if let value = value as? Int, value == 1 {
				space = "sRGB"
			}
			return MetadataItem(name: "Exposure bias".localized, value: space)
		}

		// Time
		transformers[kCGImagePropertyExifDateTimeOriginal] = {(value) in return MetadataItem(name: "Original date".localized, value: value as? String ?? "") }

		transformers[kCGImagePropertyExifDateTimeDigitized] = {(value) in return MetadataItem(name: "Digitized date".localized, value: value as? String ?? "") }

		// Image details
		transformers[kCGImagePropertyProfileName] = {(value) in return MetadataItem(name: "Profile".localized, value: value as? String ?? "") }

		transformers[kCGImagePropertyPixelHeight] = {(value) in return MetadataItem(name: "Height".localized, value: "\(value)") }

		transformers[kCGImagePropertyPixelWidth] = {(value) in return MetadataItem(name: "Width".localized, value: "\(value)") }

		return transformers
	}()

	func parse(url:URL) throws -> [MetadataSection] {
		guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { throw MetadataParseError.InvailidInput }

		guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String : Any] else { throw MetadataParseError.MetadataMissing }

		var sections = [MetadataSection]()

		for identifier in MetadataSectionIdentifier.allCases {
			var properties: [String : Any]?
			if let sectionKey = identifier.sectionKey {
				properties = imageProperties[sectionKey] as? [String : Any]
			} else {
				properties = imageProperties
			}
			var items = [MetadataItem]()
			var section = MetadataSection(identifier: identifier, items: items)
			if let metadataItems = itemMapping[identifier] {
				for metadataItem in metadataItems {
					if let value = properties?[metadataItem as String] {
						if let transformer = self.valueTransformers[metadataItem] {
							items.append(transformer(value))
						}
					}
				}
			}
			section.items = items

			sections.append(section)
		}

		return sections
	}

}

class ImageMetadataViewController: StaticTableViewController {
	var imageURL: URL? {
		didSet {
			self.title = imageURL?.lastPathComponent
		}
	}
	private var imageProperties: [String : Any]?

	override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView.allowsSelection = false

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissAnimated))

		guard let url = self.imageURL else { return }

		if let sections = try? ImageMetadataParser.shared.parse(url: url) {
			for section in sections {
				let tableSection = StaticTableViewSection(headerTitle: "\(section.identifier)")

				for item in section.items {
					let row = StaticTableViewRow(subtitleRowWithAction: nil, title: item.name, subtitle: item.value, style: .value2, accessoryType: .none, identifier: "\(section.identifier)-\(item.name)")
					tableSection.add(row: row)
				}

				self.addSection(tableSection)
			}
		}
	}
}
