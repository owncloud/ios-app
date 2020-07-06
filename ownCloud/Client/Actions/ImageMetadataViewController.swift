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
import CoreLocation
import MapKit
import Contacts

extension CLLocation {
	var dmsLatitude: String {
		let direction = self.coordinate.latitude >= 0 ? "N" : "S"
		return dms(from: self.coordinate.latitude) + "\"\(direction)"
	}

	var dmsLongitude: String {
		let direction = self.coordinate.longitude >= 0 ? "E" : "W"
		return dms(from: self.coordinate.longitude) + "\"\(direction)"
	}

	private func dms(from coordinate:CLLocationDegrees) -> String {
		var seconds = Int(coordinate * 3600)
		let degrees = seconds / 3600
		seconds = abs(seconds % 3600)
		let minutes = seconds / 60
		seconds %= 60

		return String(format:"%d° %d' %d ", abs(degrees), minutes, seconds)
	}
}

extension CLPlacemark {
	var formattedAddress : String? {
		if let address = self.postalAddress {
			return CNPostalAddressFormatter().string(from: address)
		}
		return nil
	}
}

class ImageMetadataParser {

	typealias MetadataValueTransformer = (Any) -> MetadataItem

	static let shared = ImageMetadataParser()

	private lazy var exifDateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
		return formatter
	}()

	private lazy var displayDateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .medium
		formatter.locale = Locale.current
		return formatter
	}()

	enum MetadataParseError : Error {
		case InvailidInput
		case MetadataMissing
	}

	enum MetadataSectionIdentifier : CaseIterable, CustomStringConvertible {

		case cameraDetails
		case captureParameters
		case timestamps
		case imageDetails
		case exifAuxSection

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
			case .exifAuxSection:
				return "EXIF aux info".localized
			}
		}

		var subdictionaryKey: String? {
			switch self {
			case .imageDetails:
				return nil
			case .exifAuxSection:
				return kCGImagePropertyExifAuxDictionary as String
			default:
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
		var key: CFString?
	}

	struct ParseResult {
		var sections = [MetadataSection]()
		var location: CLLocation?
		var size = CGSize.zero
		var profile: String?
		var info: String?
	}

	private lazy var itemMapping: [MetadataSectionIdentifier : [CFString]] = {
		var mapping = [MetadataSectionIdentifier : [CFString]]()

		mapping[.cameraDetails] = [
			kCGImagePropertyExifLensMake,
			kCGImagePropertyExifLensModel,
			kCGImagePropertyExifAuxLensInfo]

		mapping[.captureParameters] = [
			kCGImagePropertyExifFocalLength,
			kCGImagePropertyExifFocalLenIn35mmFilm,
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
			kCGImagePropertyDPIWidth,
			kCGImagePropertyColorModel,
			kCGImagePropertyDepth]

		mapping[.exifAuxSection] = [
			kCGImagePropertyExifAuxLensModel,
			kCGImagePropertyExifAuxLensID,
			kCGImagePropertyExifAuxLensSerialNumber,
			kCGImagePropertyExifAuxSerialNumber,
			kCGImagePropertyExifAuxFlashCompensation,
			kCGImagePropertyExifAuxOwnerName,
			kCGImagePropertyExifAuxFirmware]

		return mapping
	}()

	private lazy var valueTransformers: [CFString : MetadataValueTransformer] = {
		var transformers = [CFString : MetadataValueTransformer]()

		// Camera Details
		transformers[kCGImagePropertyExifLensMake] = {(value) in return MetadataItem(name: "Lens make".localized, value: value as? String ?? "") }

		transformers[kCGImagePropertyExifLensModel] = {(value) in return MetadataItem(name: "Lens model".localized, value: value as? String ?? "") }

		transformers[kCGImagePropertyExifAuxLensInfo] = {(value) in return MetadataItem(name: "Lens info".localized, value: value as? String ?? "") }

		// Capture parameters
		transformers[kCGImagePropertyExifFocalLength] = {(value) in
			return MetadataItem(name: "Focal length".localized, value: "\(value) mm")
		}

		transformers[kCGImagePropertyExifFocalLenIn35mmFilm] = {(value) in
			return MetadataItem(name: "Focal length @ 35 mm".localized, value: "\(value) mm")
		}

		transformers[kCGImagePropertyExifShutterSpeedValue] = {(value) in
			var Tv: Double = 0
			if let apexValue = value as? Double {
				Tv = round(pow(2.0, -apexValue) * 10000) / 10000
			}
			return MetadataItem(name: "Shutter speed".localized, value: "\(Tv) s")
		}

		transformers[kCGImagePropertyExifApertureValue] = {(value) in
			var aperture: Double = 0
			if let apexValue = value as? Double {
				aperture = round(pow(2.0, apexValue / 2.0) * 10) / 10
			}

			return MetadataItem(name: "Aperture".localized, value: "f/\(aperture)")
		}

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
		transformers[kCGImagePropertyExifDateTimeOriginal] = {(value) in
			var convertedTimestamp : String = ""
			if let exifTimestamp = value as? String {
				if let date = self.exifDateFormatter.date(from: exifTimestamp) {
					convertedTimestamp = self.displayDateFormatter.string(from: date)
				}
			}
			return MetadataItem(name: "Original date".localized, value: convertedTimestamp)
		}

		transformers[kCGImagePropertyExifDateTimeDigitized] = {(value) in
			var convertedTimestamp : String = ""
			if let exifTimestamp = value as? String {
				if let date = self.exifDateFormatter.date(from: exifTimestamp) {
					convertedTimestamp = self.displayDateFormatter.string(from: date)
				}
			}
			return MetadataItem(name: "Digitized date".localized, value: convertedTimestamp)
		}

		// Image details
		transformers[kCGImagePropertyProfileName] = {(value) in return MetadataItem(name: "Profile".localized, value: value as? String ?? "") }
		transformers[kCGImagePropertyPixelHeight] = {(value) in return MetadataItem(name: "Height".localized, value: "\(value) px") }
		transformers[kCGImagePropertyPixelWidth] = {(value) in return MetadataItem(name: "Width".localized, value: "\(value) px") }
		transformers[kCGImagePropertyDPIHeight] = {(value) in return MetadataItem(name: "DPI vertical".localized, value: "\(value)") }
		transformers[kCGImagePropertyDPIWidth] = {(value) in return MetadataItem(name: "DPI horizontal".localized, value: "\(value)") }
		transformers[kCGImagePropertyColorModel] = {(value) in return MetadataItem(name: "Color model".localized, value: "\(value)") }
		transformers[kCGImagePropertyDepth] = {(value) in return MetadataItem(name: "Depth".localized, value: "\(value) bits/channel") }

		// Exif Aux info
		transformers[kCGImagePropertyExifAuxLensModel] = {(value) in return MetadataItem(name: "Lens model".localized, value: "\(value)") }
		transformers[kCGImagePropertyExifAuxLensID] = {(value) in return MetadataItem(name: "Lens ID".localized, value: "\(value)") }
		transformers[kCGImagePropertyExifAuxLensSerialNumber] = {(value) in return MetadataItem(name: "Lens serial".localized, value: "\(value)") }
		transformers[kCGImagePropertyExifAuxSerialNumber] = {(value) in return MetadataItem(name: "Serial Nr.".localized, value: "\(value)") }
		transformers[kCGImagePropertyExifAuxFlashCompensation] = {(value) in return MetadataItem(name: "Flash compensation".localized, value: "\(value)") }
		transformers[kCGImagePropertyExifAuxOwnerName] = {(value) in return MetadataItem(name: "Owner".localized, value: "\(value)") }
		transformers[kCGImagePropertyExifAuxFirmware] = {(value) in return MetadataItem(name: "Firmware".localized, value: "\(value)") }

		// GPS Info
		transformers[kCGImagePropertyGPSLatitude] = {(value) in return MetadataItem(name: "Latitude".localized, value: "\(value)", key: kCGImagePropertyGPSLatitude) }
		transformers[kCGImagePropertyGPSLongitude] = {(value) in return MetadataItem(name: "Longitude".localized, value: "\(value)", key: kCGImagePropertyGPSLongitude) }
		transformers[kCGImagePropertyGPSAltitude] = {(value) in return MetadataItem(name: "Altitude".localized, value: "\(value)") }

		return transformers
	}()

	func parse(url:URL) throws -> ParseResult {
		guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { throw MetadataParseError.InvailidInput }

		guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String : Any] else { throw MetadataParseError.MetadataMissing }

		var result = ParseResult()

		for identifier in MetadataSectionIdentifier.allCases {
			var properties: [String : Any]?
			if let sectionKey = identifier.subdictionaryKey {
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

			result.sections.append(section)
		}

		if let gpsDictionary = imageProperties[kCGImagePropertyGPSDictionary as String] as? [String : Any] {
			if let latitude = gpsDictionary[kCGImagePropertyGPSLatitude as String] as? Double,
				let longitude = gpsDictionary[kCGImagePropertyGPSLongitude as String] as? Double,
				let latRef = gpsDictionary[kCGImagePropertyGPSLatitudeRef as String] as? String,
				let longRef = gpsDictionary[kCGImagePropertyGPSLongitudeRef as String] as? String {
				var coordinate = CLLocationCoordinate2D()
				// Latitude: North - positive, South - negative
				coordinate.latitude = latRef == "N" ? latitude : -latitude
				// Longitude: East - positive, West - negative
				coordinate.longitude = longRef == "E" ? longitude : -longitude

				var altitude: CLLocationDistance?

				if let gpsAltitude = gpsDictionary[kCGImagePropertyGPSAltitude as String] as? Double,
					let gpsAltitudeRef = gpsDictionary[kCGImagePropertyGPSAltitudeRef as String] as? Int {
					// Altitude: measured in meters
					// AltitudeRef: 0 - Sea level, 1 - Sea level reference (negative)
					altitude = gpsAltitudeRef == 0 ? gpsAltitude : -gpsAltitude
				}

				if altitude == nil {
					result.location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
				} else {
					result.location = CLLocation(coordinate: coordinate, altitude: altitude!, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: Date())
				}
			}
		}

		return result
	}

}

class ImageMetadataViewController: StaticTableViewController {
	var imageURL: URL? {
		didSet {
			self.title = imageURL?.lastPathComponent
		}
	}
	private var imageProperties: [String : Any]?

	let gpsSection = StaticTableViewSection(headerTitle: "GPS Location".localized)

	override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView.allowsSelection = false
		self.tableView.separatorStyle = .none

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissAnimated))

		guard let url = self.imageURL else { return }

		OnBackgroundQueue {
			if let result = try? ImageMetadataParser.shared.parse(url: url) {
				OnMainThread {
					for section in result.sections {
						let tableSection = StaticTableViewSection(headerTitle: "\(section.identifier)")

						for item in section.items {
							let row = StaticTableViewRow(subtitleRowWithAction: nil, title: item.name, subtitle: item.value, style: .value2, accessoryType: .none, identifier: "\(section.identifier)-\(item.name)")
							row.cell?.textLabel?.numberOfLines = 0
							row.cell?.textLabel?.lineBreakMode = .byWordWrapping
							row.cell?.detailTextLabel?.numberOfLines = 0
							row.cell?.detailTextLabel?.lineBreakMode = .byWordWrapping

							tableSection.add(row: row)
						}

						if tableSection.rows.count > 0 {
							self.addSection(tableSection)
						}
					}
				}

				if let location = result.location {

					OnMainThread {
						let latLongRow = StaticTableViewRow(subtitleRowWithAction: nil, title: "Coordinates".localized, subtitle: "\(location.dmsLatitude), \(location.dmsLongitude)", style: .value2, accessoryType: .none, identifier: "location-gps-lat-long")
						self.gpsSection.add(row: latLongRow)

						if location.altitude != 0 {
							let altitudeRow = StaticTableViewRow(subtitleRowWithAction: nil, title: "Altitude".localized, subtitle: "\(location.altitude) m", style: .value2, accessoryType: .none, identifier: "location-gps-alt")
							self.gpsSection.add(row: altitudeRow)
						}

						let mapView = MKMapView(frame: CGRect.zero)
						mapView.isUserInteractionEnabled = false
						let span = MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
						let region = MKCoordinateRegion(center: location.coordinate, span: span)
						mapView.setRegion(region, animated: false)

						let annotation = MKPointAnnotation()
						annotation.coordinate = location.coordinate
						mapView.addAnnotation(annotation)

						let mapRow = StaticTableViewRow(customView: mapView, fixedHeight: 120.0)
						self.gpsSection.add(row: mapRow)
						self.addSection(self.gpsSection)
					}

					self.lookup(location: location) { (placemark) in
						if let address = placemark?.formattedAddress {
							OnMainThread {
								let placeRow = StaticTableViewRow(subtitleRowWithAction: nil, title: "Place".localized, subtitle: address, style: .value2, accessoryType: .none, identifier: "location-place")
								self.gpsSection.add(row: placeRow)
							}
						}
					}
				}

				if let histogram = self.histogramImage(for: url) {
					OnMainThread {
						let section = StaticTableViewSection(headerTitle: "Histogram")
						let imageView = UIImageView(image: histogram)
						let row = StaticTableViewRow(customView: imageView)

						section.add(row: row)
						self.addSection(section)
					}
				}
			}
		}
	}

	private func histogramImage(for url:URL) -> UIImage? {
		let ciImage = CIImage(contentsOf: url)
		let histImage = ciImage?.applyingFilter("CIAreaHistogram", parameters: ["inputCount" : 256, "inputScale" : 10.0])
		guard let outputImage = histImage?.applyingFilter("CIHistogramDisplayFilter") else {
			return nil
		}
		return UIImage(ciImage: outputImage)
	}

	private func lookup(location:CLLocation, completionHandler: @escaping (CLPlacemark?)
	-> Void) {
        let geocoder = CLGeocoder()

        // Look up the location and pass it to the completion handler
        geocoder.reverseGeocodeLocation(location,
                    completionHandler: { (placemarks, error) in
            if error == nil {
                let firstLocation = placemarks?[0]
                completionHandler(firstLocation)
            } else {
	         // An error occurred during geocoding.
                completionHandler(nil)
            }
        })
	}
}
