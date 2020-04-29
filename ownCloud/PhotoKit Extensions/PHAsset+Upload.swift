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
import CoreServices

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

	/**
	Method for export of the resource to disk (not used right now but could be used later export RAW images and video-clips tied to live photo assets)
	*/
	public func export(to targetURL:URL? = nil, completionHandler: @escaping (_ url:URL?, _ error:Error?) -> Void) {

		let options = PHAssetResourceRequestOptions()
		options.isNetworkAccessAllowed = true

		let exportURL = targetURL != nil ? targetURL! : URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(self.originalFilename)

		if self.isPhoto || self.isVideo {
			PHAssetResourceManager.default().writeData(for: self, toFile: exportURL, options: options) { (error) in
				completionHandler(exportURL, error)
			}
		} else {
			completionHandler(exportURL, NSError(ocError: .internal))
		}
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
	- parameter fileName: name for the exported asset including file extension
	- parameter utisToConvert: list of file UTIs for image formats which shall be converted to JPEG format
	- parameter completionHandler: called when the file is written to disk or if an error occurs
	*/
	func exportPhoto(fileName:String, utisToConvert:[String] = [], completionHandler: @escaping (_ url:URL?, _ error:Error?) -> Void) {

		// Allow to fetch photo asset from network (e.g. in case of iCloud library)
		let requestOptions = PHImageRequestOptions()
		requestOptions.isNetworkAccessAllowed = true
		requestOptions.version = .original

		// Fetch photo asset data
		PHImageManager.default().requestImageData(for: self, options: requestOptions) { (imageData, typeIdentifier, _, info) in
			var outError: Error?
			var exportURL = URL(fileURLWithPath:NSTemporaryDirectory()).appendingPathComponent(fileName)
			if let data = imageData, let ciImage = CIImage(data: data), let uti = typeIdentifier {
				// Check if image has to be converted to JPEG
				if utisToConvert.contains(uti) {
					exportURL = exportURL.deletingPathExtension().appendingPathExtension("jpg")
					outError = ciImage.convert(targetURL: exportURL, outputFormat: .JPEG)
				} else {
					// No conversion -> just write a file to disk
					do {
						try data.write(to: exportURL)
					} catch let error as NSError {
						outError = error
					}
				}
			} else {
				outError = info?[PHImageErrorKey] as? Error
			}

			completionHandler(exportURL, outError)
		}
	}

	/**
	Method for exporting video assets using PHImageManager and AVAssetExportSession
	- parameter fileName: name for the exported asset including file extension
	- parameter utisToConvert: list of file UTIs for media formats which shall be converted to MP4 format
	- parameter completionHandler: called when the file is written to disk or if an error occurs
	*/
	func exportVideo(fileName:String, utisToConvert:[String] = [], completionHandler: @escaping (_ url:URL?, _ error:Error?) -> Void) {
		var outError : Error?
		if self.mediaType == .video {
			// Allow to fetch video from the network (e.g. iCloud photo library)
			let options = PHVideoRequestOptions()
			options.isNetworkAccessAllowed = true
			options.deliveryMode = .highQualityFormat

			var exportURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)

			var outputFileType = AVFileType.mov

			// Convert to MP4 if desired
			if utisToConvert.contains(outputFileType.rawValue) {
				outputFileType = AVFileType.mp4
				exportURL = exportURL.deletingPathExtension().appendingPathExtension("mp4")
			}

			// Request AVAssetExport session (can be also done with requestAVAsset() in conjunction with AVAssetWriter for more fine-grained control)
			PHImageManager.default().requestExportSession(forVideo: self, options: options, exportPreset: AVAssetExportPresetPassthrough) { (session, info) in
				outError = info?[PHImageErrorKey] as? Error
				if let session = session {
					session.outputURL = exportURL
					session.outputFileType = outputFileType
					session.exportAsynchronously {
						completionHandler(exportURL, outError)
					}
				} else {
					completionHandler(exportURL, outError)
				}
			}
		} else {
			completionHandler(nil, NSError(ocError: .internal))
		}
	}

	/**
	Method for uploading assets from photo library to oC instance
	- parameter core: Reference to the core to be used for the upload
	- parameter rootItem: Directory item where the media file shall be uploaded
	- parameter utisToConvert: Array of UTI identifiers describing desired output formats
	- parameter preserveOriginalName If true, use original file name from the photo library
	- parameter completionHandler: Completion handler called after the media file is imported into the core and placeholder item is created.
	- parameter progressHandler: Receives progress of the at the moment running activity
	- parameter uploadCompleteHandler: Called when core reports that upload is done
	*/
	func upload(with core:OCCore?, at rootItem:OCItem, utisToConvert:[String] = [], preserveOriginalName:Bool = true, progressHandler:((_ progress:Progress) -> Void)? = nil, uploadCompleteHandler:(() -> Void)? = nil) -> (OCItem?, Error?)? {

		func performUpload(sourceURL:URL, copySource:Bool) -> (OCItem?, Error?)? {

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
				fileName = "\(self.ocStyleUploadFileName(with: sourceURL.lastPathComponent.imageFileNameSuffix)).\(sourceURL.pathExtension)"
			}

			// Synchronously import media file into the OCCore and schedule upload
			let importSemaphore = DispatchSemaphore(value: 0)

			uploadProgress = sourceURL.upload(with: core,
											  at: rootItem,
											  alternativeName: fileName,
											  modificationDate: self.creationDate,
											  importByCopy: copySource,
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

			}, completionHandler: { (_, _) in
				if uploadProgress != nil {
					progressHandler?(uploadProgress!)
				}
				uploadCompleteHandler?()
			})

			if uploadProgress != nil {
				progressHandler?(uploadProgress!)
			}

			importSemaphore.wait()

			return importResult
		}

		Log.debug(tagged: ["MEDIA_UPLOAD"], "Prepare uploading asset ID \(self.localIdentifier), type:\(self.mediaType), subtypes:\(self.mediaSubtypes), sourceType:\(self.sourceType), creationDate:\(String(describing: self.creationDate)), modificationDate:\(String(describing: self.modificationDate)), favorite:\(self.isFavorite), hidden:\(self.isHidden)")

		// Prepare progress object for importing full size asset from photo library
		let importProgress = Progress(totalUnitCount: 100)
		importProgress.localizedDescription = "Importing from photo library".localized

		var uploadResult:(OCItem?, Error?)?

		if let assetName = self.assetFileName {
			var exportedAssetURL: URL?
			var outError: Error?

			// Synchronously export asset
			let semaphore = DispatchSemaphore(value: 0)
			_ = autoreleasepool {

				if self.mediaType == .image {
					exportPhoto(fileName: assetName, utisToConvert: utisToConvert, completionHandler: { (url, error) in
						exportedAssetURL = url
						outError = error
						semaphore.signal()
					})
				} else if self.mediaType == .video {
					exportVideo(fileName: assetName, utisToConvert: utisToConvert) { (url, error) in
						exportedAssetURL = url
						outError = error
						semaphore.signal()
					}
				} else {
					outError = NSError(ocError: .internal)
					semaphore.signal()
				}

			}
			semaphore.wait()

			// Do we have an error at export stage?
			if outError != nil {
				Log.error(tagged: ["MEDIA_UPLOAD"], "Asset export failed for asset with UTI \(String(describing: self.primaryResource?.uniformTypeIdentifier)) ID \(String(describing: self.primaryResource?.assetLocalIdentifier)), error: \(String(describing: outError))")
				uploadResult = (nil, outError)
			} else {
				// Perform actual upload
				if let uploadURL = exportedAssetURL {
					uploadResult = performUpload(sourceURL: uploadURL, copySource: false)
				}
			}

		} else {
			Log.error(tagged: ["MEDIA_UPLOAD"], "Primary resource not found for asset ID \(self.localIdentifier)")
		}

		return uploadResult
	}
}
