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
import ownCloudSDK

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
			return CNPostalAddressFormatter().string(from: address).split(separator: "\n").joined(separator: ", ")
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
		case exifAuxSection
		case timestamps
		case iptcSection
		case tiffSection

		var description: String {
			switch self {
			case .cameraDetails:
				return "Camera details".localized
			case .captureParameters:
				return "Capture settings".localized
			case .timestamps:
				return "Time".localized
			case .exifAuxSection:
				return "EXIF aux info".localized
			case .iptcSection:
				return "Authoring".localized
			case .tiffSection:
				return "TIFF".localized
			}
		}

		var subdictionaryKey: String? {
			switch self {
			case .exifAuxSection:
				return kCGImagePropertyExifAuxDictionary as String
			case .iptcSection:
				return kCGImagePropertyIPTCDictionary as String
			case .tiffSection:
				return kCGImagePropertyTIFFDictionary as String
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
		var dpi: Int?
		var colorModel: String?
		var depth: Int?
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
			kCGImagePropertyExifISOSpeedRatings,
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

		mapping[.exifAuxSection] = [
			kCGImagePropertyExifAuxLensModel,
			kCGImagePropertyExifAuxLensID,
			kCGImagePropertyExifAuxLensSerialNumber,
			kCGImagePropertyExifAuxSerialNumber,
			kCGImagePropertyExifAuxFlashCompensation,
			kCGImagePropertyExifAuxOwnerName,
			kCGImagePropertyExifAuxFirmware]

		mapping[.iptcSection] = [
			kCGImagePropertyIPTCKeywords,
			kCGImagePropertyIPTCCopyrightNotice,
			kCGImagePropertyIPTCCreatorContactInfo
		]

		mapping[.tiffSection] = [
			kCGImagePropertyTIFFCompression,
			kCGImagePropertyTIFFPhotometricInterpretation,
			kCGImagePropertyTIFFDocumentName,
			kCGImagePropertyTIFFImageDescription,
			kCGImagePropertyTIFFMake,
			kCGImagePropertyTIFFModel,
			kCGImagePropertyTIFFSoftware,
			kCGImagePropertyTIFFArtist,
			kCGImagePropertyTIFFCopyright,
			kCGImagePropertyTIFFWhitePoint
		]

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

		transformers[kCGImagePropertyExifISOSpeedRatings] = {(value) in
			var isoValue = ""
			if let isoSpeedRatings = value as? [Int], isoSpeedRatings.count > 0 {
				isoValue = "\(isoSpeedRatings[0])"
			}
			return MetadataItem(name: "ISO".localized, value: "\(isoValue)")
		}

		transformers[kCGImagePropertyExifExposureProgram] = {(value) in

			var program = ""

			if let programType = value as? Int {
				switch programType {
				case 0: program = "Not defined".localized
				case 1: program = "Manual".localized
				case 2: program = "Normal".localized
				case 3: program = "Aperture priority".localized
				case 4: program = "Shutter priority".localized
				case 5: program = "Creative".localized
				case 6: program = "Action".localized
				case 7: program = "Portrait".localized
				case 8: program = "Landscape".localized

				default: break
				}
			}

			return MetadataItem(name: "Program".localized, value: program)
		}

		transformers[kCGImagePropertyExifMeteringMode] = {(value)
				in
			guard let mode = value as? Int else {
				return MetadataItem(name: "Metering".localized, value: "")
			}

			var modeString = "unknown".localized
			switch mode {
			case 1: modeString = "Average".localized
			case 2: modeString = "CenterWeightedAverage".localized
			case 3: modeString = "Spot".localized
			case 4: modeString = "MultiSpot".localized
			case 5: modeString = "Pattern".localized
			case 6: modeString = "Partial".localized
			case 255: modeString = "CenterWeightedAverage".localized
			default: break
			}

			return MetadataItem(name: "Metering".localized, value: modeString)
		}

		transformers[kCGImagePropertyExifExposureBiasValue] = {(value) in
			var bias = ""
			if let expBias = value as? Double {
				if expBias >= 0.0 {
					bias = String(format: "+%.2f EV", expBias)
				} else {
					bias = String(format: "%.2f EV", expBias)
				}
			}
			return MetadataItem(name: "Exposure bias".localized, value: "\(bias)")
		}

		transformers[kCGImagePropertyExifFlash] = {(value)
			in
			var flashInfo = [String]()
			if let flashBitMask = value as? UInt16 {
				let flashPresent = flashBitMask & 0b100000 != 0
				if flashPresent {
					// Did flash fire?
					if flashBitMask & 0b01 != 0 {
						flashInfo.append("Fired".localized)
					} else {
						flashInfo.append("Didn't fire".localized)
					}

					switch (flashBitMask >> 1) & 0b11 {
					case 0b00: flashInfo.append("No strobe return detection".localized)
					case 0b10: flashInfo.append("Strobe return light not detected".localized)
					case 0b11: flashInfo.append("Strobe return light detected".localized)
					default: break
					}

					switch (flashBitMask >> 3) & 0b11 {
					case 0b01: flashInfo.append("Compulsory flash firing".localized)
					case 0b10: flashInfo.append("Compulsory flash supression".localized)
					case 0b11: flashInfo.append("Auto mode".localized)
					default: break
					}

					if flashBitMask  & 0b1000000 != 0 {
						flashInfo.append("Red eye detection supported".localized)
					}

				} else {
					flashInfo.append("not present".localized)
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
				case 0: wbMode = "Auto".localized
				case 1: wbMode = "Manual".localized
				default: break
				}
			}
			return MetadataItem(name: "White balance".localized, value: wbMode)
		}

		transformers[kCGImagePropertyExifColorSpace] = {(value) in

			var space = "Uncalibrated".localized
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

		// Exif Aux info
		transformers[kCGImagePropertyExifAuxLensModel] = {(value) in return MetadataItem(name: "Lens model".localized, value: "\(value)") }
		transformers[kCGImagePropertyExifAuxLensID] = {(value) in return MetadataItem(name: "Lens ID".localized, value: "\(value)") }
		transformers[kCGImagePropertyExifAuxLensSerialNumber] = {(value) in return MetadataItem(name: "Lens serial".localized, value: "\(value)") }
		transformers[kCGImagePropertyExifAuxSerialNumber] = {(value) in return MetadataItem(name: "Serial number".localized, value: "\(value)") }
		transformers[kCGImagePropertyExifAuxFlashCompensation] = {(value) in return MetadataItem(name: "Flash compensation".localized, value: "\(value)") }
		transformers[kCGImagePropertyExifAuxOwnerName] = {(value) in return MetadataItem(name: "Owner".localized, value: "\(value)") }
		transformers[kCGImagePropertyExifAuxFirmware] = {(value) in return MetadataItem(name: "Firmware".localized, value: "\(value)") }

		// IPTC / XMP meta-data
		transformers[kCGImagePropertyIPTCKeywords] = {(value) in
			var keywords = ""
			if let keywordArray = value as? [String] {
				keywords = keywordArray.joined(separator: ", ")
			}
			return MetadataItem(name: "Keywords".localized, value: "\(keywords)")
		}
		transformers[kCGImagePropertyIPTCCopyrightNotice] = {(value) in return MetadataItem(name: "Copyright".localized, value: "\(value)") }
		transformers[kCGImagePropertyIPTCCreatorContactInfo] = {(value) in
			var contactDetails = [String]()
			if let contactDict = value as? [String : String] {

				if let email = contactDict[kCGImagePropertyIPTCContactInfoEmails as String] {
					contactDetails.append(email)
				}

				if let web = contactDict[kCGImagePropertyIPTCContactInfoWebURLs as String] {
					contactDetails.append(web)
				}

				if let phone = contactDict[kCGImagePropertyIPTCContactInfoPhones as String] {
					contactDetails.append(phone)
				}

			}
			return MetadataItem(name: "Contact info".localized, value: "\(contactDetails.joined(separator: ", "))")
		}
		transformers[kCGImagePropertyIPTCRightsUsageTerms] = {(value) in return MetadataItem(name: "Usage terms".localized, value: "\(value)") }
		transformers[kCGImagePropertyIPTCScene] = {(value) in return MetadataItem(name: "Scene".localized, value: "\(value)") }

		// TIFF
		transformers[kCGImagePropertyTIFFPhotometricInterpretation] = {(value) in
			var textValue = "none".localized
			if let piValue = value as? Int {
				switch piValue {
				case 2:
					textValue = "RGB".localized
				case 6:
					textValue = "YCbCr".localized
				default:
					break
				}
			}
			return MetadataItem(name: "Photometric interpretation".localized, value: textValue)
		}

		transformers[kCGImagePropertyTIFFImageDescription ] = {(value) in return MetadataItem(name: "Description".localized, value: "\(value)") }

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
							let item = transformer(value)
							if item.value.isEmpty == false {
								items.append(item)
							}
						} else {
							let transformer: MetadataValueTransformer = {(value) in return MetadataItem(name: metadataItem as String, value: "\(value)") }
							items.append(transformer(value))
						}
					}
				}
			}
			section.items = items

			result.sections.append(section)
		}

		// Image details
		if let profile = imageProperties[kCGImagePropertyProfileName as String] as? String {
			result.profile = profile
		}

		result.size = CGSize.zero
		if let exifDict = imageProperties[kCGImagePropertyExifDictionary as String]  as? [String : Any] {
			if let height = exifDict[kCGImagePropertyExifPixelYDimension as String] as? CGFloat,
				let width = exifDict[kCGImagePropertyExifPixelXDimension as String] as? CGFloat {
				result.size = CGSize(width: width, height: height)
			}
		}

		if result.size == CGSize.zero {
			if let height = imageProperties[kCGImagePropertyPixelHeight as String] as? CGFloat,
				let width = imageProperties[kCGImagePropertyPixelWidth as String] as? CGFloat {
				result.size = CGSize(width: width, height: height)
			}
		}

		if let dpi = imageProperties[kCGImagePropertyDPIHeight as String] as? Int {
			result.dpi = dpi
		}

		if let colorModel = imageProperties[kCGImagePropertyColorModel as String] as? String,
			let depth = imageProperties[kCGImagePropertyDepth as String] as? Int {
			result.colorModel = colorModel
			result.depth = depth
		}

		// GPS Data
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

	private static let mapHeight: CGFloat = 180.0
	private static let mapSpan = 0.1

	weak var core : OCCore?
	var item : OCItem
	var imageURL: URL

	private var imageProperties: [String : Any]?

	private let gpsSection = StaticTableViewSection(headerTitle: "GPS Location".localized)
	private let activityIndicatorView = UIActivityIndicatorView(style: Theme.shared.activeCollection.activityIndicatorViewStyle)

	public init(core inCore: OCCore, item inItem: OCItem, url:URL) {
		core = inCore
		item = inItem
		imageURL = url

		super.init(style: .grouped)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	class func createMetadataRow(with title:String, subtitle:String, identifier:String) -> StaticTableViewRow {
		let row = StaticTableViewRow(subtitleRowWithAction: nil, title: title, subtitle: subtitle, style: .value2, accessoryType: .none, identifier: identifier)
		row.cell?.textLabel?.numberOfLines = 0
		row.cell?.textLabel?.lineBreakMode = .byWordWrapping
		row.cell?.detailTextLabel?.numberOfLines = 0
		row.cell?.detailTextLabel?.lineBreakMode = .byWordWrapping

		return row
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView.allowsSelection = false
		self.tableView.separatorStyle = .none
		self.navigationItem.title = "Image metadata".localized

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissAnimated))

		guard let core = self.core else { return }

		let headerView = MoreViewHeader(for: item, with: core, favorite: false)
		self.tableView.tableHeaderView = headerView
		self.tableView.layoutTableHeaderView()

		activityIndicatorView.hidesWhenStopped = true
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: activityIndicatorView)

		activityIndicatorView.startAnimating()

		OnBackgroundQueue {
			if let result = try? ImageMetadataParser.shared.parse(url: self.imageURL) {

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
						let span = MKCoordinateSpan(latitudeDelta: ImageMetadataViewController.mapSpan, longitudeDelta: ImageMetadataViewController.mapSpan)
						let region = MKCoordinateRegion(center: location.coordinate, span: span)
						mapView.setRegion(region, animated: false)

						let annotation = MKPointAnnotation()
						annotation.coordinate = location.coordinate
						mapView.addAnnotation(annotation)

						let mapRow = StaticTableViewRow(customView: mapView, fixedHeight: ImageMetadataViewController.mapHeight)
						self.gpsSection.add(row: mapRow)
						self.addSection(self.gpsSection)
					}

					self.lookup(location: location) { (placemark) in
						if let address = placemark?.formattedAddress {
							OnMainThread {
								let placeRow = ImageMetadataViewController.createMetadataRow(with: "Place".localized, subtitle: "\(address)", identifier: "location-place")
								self.gpsSection.add(row: placeRow)
							}
						}
					}
				}

				OnMainThread {
					let imageDetailsSection = StaticTableViewSection(headerTitle: "Image details".localized)

					if let profile = result.profile {
						let profileRow = ImageMetadataViewController.createMetadataRow(with: "Profile".localized, subtitle: profile, identifier: "image-profile")
						imageDetailsSection.add(row: profileRow)
					}

					let mp = round((result.size.width * result.size.height) / 1000_000.0 * 10.0) / 10.0
					let size = "\(Int(result.size.width)) x \(Int(result.size.height)) px (\(mp) MP)"
					let sizeRow = ImageMetadataViewController.createMetadataRow(with: "Size".localized, subtitle: size, identifier: "image-size")
					imageDetailsSection.add(row: sizeRow)

					if let dpi = result.dpi {
						let dpiString = "\(dpi) DPI"
						let dpiRow = ImageMetadataViewController.createMetadataRow(with: "Density".localized, subtitle: dpiString, identifier: "image-dpi")
						imageDetailsSection.add(row: dpiRow)
					}

					if let colorModel = result.colorModel, let depth = result.depth {
						let colorInfo = String(format: "%@ (%d bits/channel)".localized, colorModel, depth)
						let colorInfoRow = ImageMetadataViewController.createMetadataRow(with: "Color model".localized, subtitle: colorInfo, identifier: "image-color-info")
						imageDetailsSection.add(row: colorInfoRow)
					}

					self.addSection(imageDetailsSection)

					for section in result.sections {
						let tableSection = StaticTableViewSection(headerTitle: "\(section.identifier)")

						for item in section.items {
							let row = ImageMetadataViewController.createMetadataRow(with: item.name, subtitle: item.value, identifier: "\(section.identifier)-\(item.name)")
							tableSection.add(row: row)
						}

						if tableSection.rows.count > 0 {
							self.addSection(tableSection)
						}
					}

					self.activityIndicatorView.stopAnimating()
				}

				if let histogram = self.histogramImage(for: self.imageURL) {
					OnMainThread {
						let section = StaticTableViewSection(headerTitle: "Histogram".localized)
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
