//
//  PHAsset+Upload.swift
//  ownCloud
//
//  Created by Michael Neuwert on 17.07.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
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

import Photos
import ownCloudSDK
import ownCloudAppShared
import CoreServices

extension URL {
	var audioVideoAssetType : AVFileType? {
		let ext = self.pathExtension.lowercased()
		switch ext {
		case "mov":
			return AVFileType.mov
		case "mp4":
			return AVFileType.mp4
		case "m4v":
			return AVFileType.m4v
		case "3gp", "3gpp", "sdv":
			return AVFileType.mobile3GPP
		default:
			return nil
		}
	}
}

extension String {
	// If we have a name like IMG_00123.jpg, then only 00123 shall be returned
	// If the name doesn't start with IMG or img, return nil
	var imageFileNameSuffix: String? {
		guard self.lowercased().hasPrefix("img") else { return nil }
		return self.trimmingCharacters(in: CharacterSet.decimalDigits.inverted)
	}
}

extension PHAssetResource {

	var isPhoto: Bool {
		switch self.type {
		case .photo, .fullSizePhoto, .alternatePhoto, .adjustmentBasePhoto:
			return true
		default:
			return false
		}
	}

	var isVideo: Bool {
		switch self.type {
		case .video, .fullSizeVideo, .pairedVideo, .adjustmentBasePairedVideo:
			return true
		default:
			return false
		}
	}

	var fileExtension: String {
		return PHAssetResource.fileExtension(from: self.uniformTypeIdentifier)
	}

	static func fileExtension(from uti:String) -> String {
		var ext = ""
		// Append correct file extension to export URL
		switch uti {
		case AVFileType.jpg.rawValue:
			ext = "jpg"
		case String(kUTTypePNG):
			ext = "png"
		case String(kUTTypeGIF):
			ext = "gif"
		case AVFileType.heic.rawValue:
			ext = "heic"
		case AVFileType.heif.rawValue:
			ext = "heif"
		case AVFileType.mov.rawValue:
			ext = "mov"
		case AVFileType.mp4.rawValue:
			ext = "mp4"
		case AVFileType.m4v.rawValue:
			ext = "m4v"
		case String(kUTTypeTIFF):
			ext = "tiff"
		case String(kUTTypeRawImage), AVFileType.dng.rawValue:
			ext = "dng"
		default:
			break
		}

		return ext.uppercased()
	}
}

extension PHAsset {

	// MARK: - Asset naming

	/**
	Date formatter matching legacy app date formatting used to compose a name for uploaded media asset
	*/
	static private let dateFormatter: DateFormatter = {
		let dateFormatter: DateFormatter =  DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
		dateFormatter.locale = Locale(identifier:"en_US_POSIX")
		return dateFormatter
	}()

	/**
	Property returning asset creation date formatted as string
	*/
	private var creationDateAsString: String {
		guard let creationDate = self.creationDate else { return "" }
		return PHAsset.dateFormatter.string(from: creationDate)
	}

	/**
	Returns a primary resource for an asset. E.g. live photos usually contain 2x asset ressources: still image in JPG or HEIC format plus video clip.
	Same applies for RAW photos shot with 3rd party apps which consist of compressed and uncompressed asset ressources. Edited photos may include adjust data as separate PHAssetResource

	Below property returns a PHAssetRessouce corresponding to original still image (unedited)
	*/
	private var primaryResource: PHAssetResource? {
		let resources = PHAssetResource.assetResources(for: self)
		var types: Set<PHAssetResourceType> = []

		switch mediaType {
		case .video:
			types = [.video]
		case .image:
			types = [.photo]
		default:
			break
		}

		return resources.first { types.contains($0.type)} ?? resources.first
	}

	private var isEdited: Bool {
		let resources = PHAssetResource.assetResources(for: self)
		return resources.contains(where: {$0.type == .fullSizePhoto})
	}

	/**
	This property tries to find an original fileName usually starting with IMG_ prefix. Unfortunatelly Photos framework messes up names and in some cases,
	PHAssetResource.originalFilename will return a name based on local identifier of asset (sort of UUID) although at the same time it stores a URL starting
	with IMG_ in it's private properties (see PHAssetResource.description output). Here kind of a hack is used accessing non-documented PHAsset property
	'filename' and PHAssetResource.originalFilename is only used as fallback.
	*/
	private var assetFileName: String? {

		var names = [String]()

		if let originalName = self.primaryResource?.originalFilename {
			names.append(originalName)
		}

		if let phAssetName = self.value(forKey: "filename") as? String {
			names.append(phAssetName)
		}

		if let imgName = names.filter({$0.lowercased().hasPrefix("img")}).first {
			return imgName
		} else {
			return names.first
		}
	}

	/**
	OCCellurSwitch identifier which shall be used to control if the asset shall be uploaded using cellular data
	*/
	private var cellSwitchIdentifier: OCCellularSwitchIdentifier? {
		var identifier: OCCellularSwitchIdentifier?
		if self.mediaType == .image {
			identifier = .photoUploadCellularSwitchIdentifier
		} else if self.mediaType == .video {
			identifier = .videoUploadCellularSwitchIdentifier
		}
		return identifier
	}

	/**
	File name for media upload created in the same way legacy oC app did it (without extension)
	- Image names: IMG_0123.jpg will become Photo-yyyy-MM-dd-HH-mm-ss_0123.jpg for example
	- Video names are going to be similar but prefixed with Video- instead of Photo-
	*/
	private func ocStyleUploadFileName(with suffix:String?) -> String {
		var fileName = ""

		// Add textual media description
		switch self.mediaType {
		case .image:
			fileName += "Photo"
		case .video:
			fileName += "Video"
		default:
			break
		}

		// Add time stamp
		fileName += "-\(self.creationDateAsString)"

		// Add suffix (e.g. for original filename IMG_0123 it would be 0123)
		if let suffix = suffix {
			fileName += "_\(suffix)"
		}

		return fileName
	}

	/**
	Method for exporting phot assets using PHImageManager
	- parameter resources: array of PHAssetResource objects belonging to PHAsset
	- parameter fileName: name for the exported asset including file extension
	- parameter utisToConvert: list of file UTIs for image formats which shall be converted to JPEG format
	- parameter preferredResourceTypes: list of resource types which shall be preferrably exported
	- parameter completionHandler: called when the file is written to disk or if an error occurs
	*/
	func exportPhoto(resources:[PHAssetResource],
					 fileName:String,
					 utisToConvert:[String] = [],
					 preferredResourceTypes:[PHAssetResourceType] = [],
					 completionHandler: @escaping (_ url:URL?, _ error:Error?) -> Void) {

		var resourceToExport:PHAssetResource?
		var outError: Error?

		// Is there a preferred export type
		if preferredResourceTypes.count > 0 {
			resourceToExport = resources.filter({preferredResourceTypes.contains($0.type)}).first
		}

		if resourceToExport == nil {
			// For edited photo pick the edited version
			resourceToExport = resources.filter({$0.type == .fullSizePhoto}).first
		}

		// If edited photo is not avaialable, pick the original
		if resourceToExport == nil {
			resourceToExport = resources.filter({$0.type == .photo}).first
		}

		// No resource found?
		guard let resource = resourceToExport else {
			completionHandler(nil, NSError(ocError: .internal))
			return
		}

		// Allow to request resource underlying data from network (iCloud in this case)
		let requestOptions = PHAssetResourceRequestOptions()
		requestOptions.isNetworkAccessAllowed = true

		// Prepare export URL and remove path extension which will depend on output format
		var exportURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(fileName).deletingPathExtension()

		// Check if conversion is required? Don't convert RAW though
		if utisToConvert.contains(resource.uniformTypeIdentifier) && resource.type != .alternatePhoto {

			// Since conversion to JPEG is desired, we have first to get the actual data
			var assetData = Data()
			PHAssetResourceManager.default().requestData(for: resource, options:requestOptions, dataReceivedHandler: { (chunk) in
				assetData.append(chunk)
			}, completionHandler: { (error) in
				outError = error
				if error == nil, let ciImage = CIImage(data: assetData) {
					exportURL = exportURL.appendingPathExtension("jpg")
					outError = ciImage.convert(targetURL: exportURL, outputFormat: .JPEG)
				}
				completionHandler(exportURL, outError)
			})
		} else {
			// Append correct file extension to export URL
			exportURL = exportURL.appendingPathExtension(resource.fileExtension)

			// Write the file to disc
			PHAssetResourceManager.default().writeData(for: resource, toFile: exportURL, options: requestOptions) { (error) in
				outError = error
				completionHandler(exportURL, outError)
			}
		}
	}

	/**
	Method for exporting phot assets using PHImageManager
	- parameter fileName: name for the exported asset including file extension
	- parameter utisToConvert: list of file UTIs for image formats which shall be converted to JPEG format
	- parameter completionHandler: called when the file is written to disk or if an error occurs
	*/
	func exportPhoto(fileName:String, utisToConvert:[String] = [], completionHandler: @escaping (_ url:URL?, _ error:Error?) -> Void) {

		var outError: Error?
		var exportURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(fileName).deletingPathExtension()

		let requestOptions = PHImageRequestOptions()
		requestOptions.isNetworkAccessAllowed = true
		requestOptions.deliveryMode = .highQualityFormat
		requestOptions.version = .current
		requestOptions.resizeMode = .none

		PHImageManager.default().requestImageData(for: self, options: requestOptions) { (imageData, utiIdentifier, _, info) in
			outError = info?[PHImageErrorKey] as? Error
			if let data = imageData, let uti = utiIdentifier {
				if utisToConvert.contains(uti) {
					if let ciImage = CIImage(data: data) {
						exportURL = exportURL.appendingPathExtension("jpg")
						outError = ciImage.convert(targetURL: exportURL, outputFormat: .JPEG)
					}
				} else {
					exportURL = exportURL.appendingPathExtension(PHAssetResource.fileExtension(from: uti))
					do {
						try data.write(to: exportURL)
					} catch {
						outError = error
					}
				}
			}
			completionHandler(exportURL, outError)
		}
	}

	/**
	Method for exporting video assets
	- parameter resources: array of PHAssetResource objects belonging to PHAsset
	- parameter fileName: name for the exported asset including file extension
	- parameter utisToConvert: list of file UTIs for media formats which shall be converted to MP4 format
	- parameter completionHandler: called when the file is written to disk or if an error occurs
	*/
	func exportVideo(resources:[PHAssetResource], fileName:String, utisToConvert:[String] = [], completionHandler: @escaping (_ url:URL?, _ error:Error?) -> Void) {

		var resourceToExport:PHAssetResource?

		// For edited video pick the edited version
		resourceToExport = resources.filter({$0.type == .fullSizeVideo}).first

		// If edited video is not avaialable, pick the original
		if resourceToExport == nil {
			resourceToExport = resources.filter({$0.type == .video}).first
		}

		// No resource found?
		guard let resource = resourceToExport else {
			completionHandler(nil, NSError(ocError: .internal))
			return
		}

		// Allow to request resource underlying data from network (iCloud in this case)
		let requestOptions = PHAssetResourceRequestOptions()
		requestOptions.isNetworkAccessAllowed = true

		// Prepare export URL and remove path extension which will depend on output format

		// Check if conversion is required?
		if utisToConvert.contains(resource.uniformTypeIdentifier) {
			exportVideo(fileName: fileName, utisToConvert: utisToConvert) { (url, error) in
				completionHandler(url, error)
			}
		} else {
			var exportURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(fileName).deletingPathExtension()
			// Append correct file extension to export URL
			exportURL = exportURL.appendingPathExtension(resource.fileExtension)

			// Write the file to disc
			PHAssetResourceManager.default().writeData(for: resource, toFile: exportURL, options: requestOptions) { (error) in
				completionHandler(exportURL, error)
			}
		}
	}

	/**
	Method for exporting video assets
	- parameter fileName: name for the exported asset including file extension
	- parameter utisToConvert: list of file UTIs for media formats which shall be converted to MP4 format
	- parameter completionHandler: called when the file is written to disk or if an error occurs
	*/
	func exportVideo(fileName:String, utisToConvert:[String] = [], completionHandler: @escaping (_ url:URL?, _ error:Error?) -> Void) {

		var outError: Error?
		var exportURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(fileName)

		let videoRequestOptions = PHVideoRequestOptions()
		videoRequestOptions.isNetworkAccessAllowed = true
		// Take care that in case of edited video, the edited content is used
		videoRequestOptions.version = .current
		videoRequestOptions.deliveryMode = .highQualityFormat

		// Request AVAssetExport session (can be also done with requestAVAsset() in conjunction with AVAssetWriter for more fine-grained control)
		PHImageManager.default().requestExportSession(forVideo: self, options: videoRequestOptions, exportPreset: AVAssetExportPresetPassthrough) { (session, info) in
			outError = info?[PHImageErrorKey] as? Error
			if let session = session, let defaultFileType = exportURL.audioVideoAssetType {

				var fileType: AVFileType = defaultFileType

				if utisToConvert.contains(AVFileType.mov.rawValue) {
					exportURL = exportURL.deletingPathExtension().appendingPathExtension("mp4")
					fileType = AVFileType.mp4
				}

				session.determineCompatibleFileTypes { (compatibleFileTypes) in
					if compatibleFileTypes.contains(fileType) {
						session.outputURL = exportURL
						session.outputFileType = fileType
						session.exportAsynchronously {
							completionHandler(exportURL, outError)
						}
					} else {
						completionHandler(nil, outError)
					}
				}
			} else {
				completionHandler(exportURL, outError)
			}
		}
	}

	/**
	Method for exporting asset and handling the cases where the file might be not available locally

	- parameter fileName: name for the exported asset including file extension
	- parameter utisToConvert: list of file UTIs for media formats which shall be converted
	- parameter preferredResourceTypes: list of resource types which shall be preferrably exported
	- parameter completion: called when the file is written to disk or if an error occurs
	*/
	func export(fileName:String, utisToConvert:[String] = [], preferredResourceTypes:[PHAssetResourceType] = [], completion:@escaping (_ url:URL?, _ error:Error?) -> Void) {
		let assetResources = PHAssetResource.assetResources(for: self)
		if assetResources.count > 0 {
			// We have actual data on the device and we can export it directly
			if self.mediaType == .image {
				exportPhoto(resources: assetResources,
							fileName: fileName,
							utisToConvert: utisToConvert,
							preferredResourceTypes: preferredResourceTypes,
							completionHandler: { (url, error) in
					completion(url, error)
				})
			} else if self.mediaType == .video {
				exportVideo(resources: assetResources, fileName: fileName, utisToConvert: utisToConvert) { (url, error) in
					completion(url, error)
				}
			} else {
				completion(nil, NSError(ocError: .internal))
			}
		} else {
			// It could be that we don't have any asset resources locally e.g. since we have to deal with an asset from a cloud album
			if self.mediaType == .image {
				exportPhoto(fileName: fileName,
							utisToConvert: utisToConvert,
							completionHandler: { (url, error) in
					completion(url, error)
				})
			} else if self.mediaType == .video {
				exportVideo(fileName: fileName,
							utisToConvert: utisToConvert) { (url, error) in
					completion(url, error)
				}
			} else {
				completion(nil, NSError(ocError: .internal))
			}
		}
	}

	/**
	Method for uploading assets from photo library to oC instance
	- parameter core: Reference to the core to be used for the upload
	- parameter rootItem: Directory item where the media file shall be uploaded
	- parameter utisToConvert: Array of UTI identifiers describing desired output formats
	- parameter preferredResourceTypes: list of resource types which shall be preferrably exported
	- parameter preserveOriginalName If true, use original file name from the photo library
	- parameter completionHandler: Completion handler called after the media file is imported into the core and placeholder item is created.
	- parameter progressHandler: Receives progress of the at the moment running activity
	- parameter uploadCompleteHandler: Called when core reports that upload is done
	*/
	func upload(with core:OCCore?, at rootItem:OCItem, utisToConvert:[String] = [], preferredResourceTypes:[PHAssetResourceType] = [], preserveOriginalName:Bool = true, progressHandler:((_ progress:Progress) -> Void)? = nil, uploadCompleteHandler:(() -> Void)? = nil) -> (OCItem?, Error?)? {

		func performUpload(sourceURL:URL, copySource:Bool, cellularSwitchIdentifier:OCCellularSwitchIdentifier?) -> (OCItem?, Error?)? {

			@discardableResult func removeSourceFile() -> Bool {
				do {
					try FileManager.default.removeItem(at: sourceURL)
					return true
				} catch {
					return false
				}
			}

			var uploadProgress: Progress?
			var importResult:(OCItem?, Error?)?

			// Sometimes if the image was edited, the name is FullSizeRender.jpg but it is stored in the subfolder
			// in the PhotoLibrary which is named after original image
			var fileName = sourceURL.lastPathComponent
			if !preserveOriginalName {
                fileName = "\(self.ocStyleUploadFileName(with: sourceURL.deletingPathExtension().lastPathComponent.imageFileNameSuffix)).\(sourceURL.pathExtension)"
			}

			// Synchronously import media file into the OCCore and schedule upload
			let importSemaphore = DispatchSemaphore(value: 0)

			uploadProgress = sourceURL.upload(with: core,
											  at: rootItem,
											  alternativeName: fileName,
											  modificationDate: self.creationDate,
											  importByCopy: copySource,
											  cellularSwitchIdentifier: cellularSwitchIdentifier,
											  placeholderHandler: { (item, error) in
												if !copySource && error != nil {
													// Delete the temporary asset file in case of critical error
													removeSourceFile()
												}
												if error != nil {
													Log.error(tagged: ["MEDIA_UPLOAD"], "Sync engine import failed for asset ID \(self.localIdentifier)")
												} else {
													Log.debug(tagged: ["MEDIA_UPLOAD"], "Finished uploading asset ID \(self.localIdentifier)")
												}
												importResult = (item, error)
												importSemaphore.signal()
												uploadCompleteHandler?()

			}, completionHandler: { (_, _) in
				if uploadProgress != nil {
					progressHandler?(uploadProgress!)
				}
			})

			if uploadProgress != nil {
				progressHandler?(uploadProgress!)
			}

			importSemaphore.wait()

			return importResult
		}

		Log.debug(tagged: ["MEDIA_UPLOAD"], "Prepare uploading asset ID \(self.localIdentifier), type:\(self.mediaType), subtypes:\(self.mediaSubtypes), sourceType:\(self.sourceType), creationDate:\(String(describing: self.creationDate)), modificationDate:\(String(describing: self.modificationDate)), favorite:\(self.isFavorite), hidden:\(self.isHidden)")

		var uploadResult:(OCItem?, Error?)?

		if let assetName = self.assetFileName {
			var exportedAssetURL: URL?
			var outError: Error?

			_ = autoreleasepool {

				// Synchronously export asset
				let semaphore = DispatchSemaphore(value: 0)
				export(fileName: assetName, utisToConvert: utisToConvert, preferredResourceTypes: preferredResourceTypes) { (url, error) in
					exportedAssetURL = url
					outError = error
					semaphore.signal()
				}
				semaphore.wait()
			}

			guard outError == nil else {
				Log.error(tagged: ["MEDIA_UPLOAD"], "Asset export failed for asset with identifier: \(self.localIdentifier), type: \(self.mediaType == .video ? "video" : "photo"), error: \(String(describing: outError))")
				uploadResult = (nil, outError)
				// Call completion handler to avoid having media upload jobs stalled forever
				uploadCompleteHandler?()
				return uploadResult
			}

			guard let uploadURL = exportedAssetURL else {
				Log.warning(tagged: ["MEDIA_UPLOAD"], "Missing export URL for asset with identifier: \(self.localIdentifier)")
				// Call completion handler to avoid having media upload jobs stalled forever
				uploadCompleteHandler?()
				uploadResult = (nil, nil)
				return uploadResult
			}

			uploadResult = performUpload(sourceURL: uploadURL, copySource: false, cellularSwitchIdentifier: self.cellSwitchIdentifier)

		} else {
			Log.error(tagged: ["MEDIA_UPLOAD"], "Primary resource not found for asset ID \(self.localIdentifier)")
		}

		return uploadResult
	}
}
