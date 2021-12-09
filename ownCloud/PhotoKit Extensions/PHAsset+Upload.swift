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

extension PHAsset {
	/**
	 Method for uploading assets from photo library to oC instance
	 - parameter core: Reference to the core to be used for the upload
	 - parameter rootItem: Directory item where the media file shall be uploaded
	 - parameter preferredFormats: Array of UTI identifiers describing desired output formats
	 - parameter completionHandler: Completion handler called after the media file is imported into the core and placeholder item is created.
	 - parameter progressHandler: Receives progress of the at the moment running activity
	 - parameter uploadCompleteHandler: Called when core reports that upload is done
	*/
	func upload(with core:OCCore?, at rootItem:OCItem, preferredFormats:[String]? = nil, progressHandler:((_ progress:Progress) -> Void)? = nil, uploadCompleteHandler:(() -> Void)? = nil) -> (OCItem?, Error?)? {

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
			for component in sourceURL.pathComponents {
				if component.starts(with: "IMG_") {
					fileName = component
					if component != sourceURL.pathComponents.last! {
						fileName += "."
						fileName += sourceURL.pathExtension
					}
					break
				}
			}

			// Synchronously import media file into the OCCore and schedule upload
			let importSemaphore = DispatchSemaphore(value: 0)

			uploadProgress = sourceURL.upload(with: core,
										at: rootItem,
										alternativeName: fileName,
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

		// Setup import options, allow download asset from network if necessary
		let contentInputOptions = PHContentEditingInputRequestOptions()
		contentInputOptions.isNetworkAccessAllowed = true

		var supportedConversionFormats = Set<String>()
		var assetUTI: String?
		var assetURL: URL?
		var avAsset:AVAsset?
		var uploadResult:(OCItem?, Error?)?

		// Synchronously retrieve asset content
		let semaphore = DispatchSemaphore(value: 0)
		_ = autoreleasepool {
			self.requestContentEditingInput(with: contentInputOptions) { (contentInput, requestInfo) in
				if let error = requestInfo[PHContentEditingInputErrorKey] as? NSError {
					Log.error(tagged: ["MEDIA_UPLOAD"], "Requesting content for asset ID \(self.localIdentifier) with error \(String(describing: error))")
				}

				if let input = contentInput {
					// Determine the correct source URL based on media type
					switch self.mediaType {
					case .image:
						assetURL = input.fullSizeImageURL
						assetUTI = input.uniformTypeIdentifier
						supportedConversionFormats.insert(String(kUTTypeJPEG))
					case .video:
						avAsset = input.audiovisualAsset
						assetURL = (avAsset as? AVURLAsset)?.url
						assetUTI = PHAssetResource.assetResources(for: self).first?.uniformTypeIdentifier
						supportedConversionFormats.insert(String(kUTTypeMPEG4))
					default:
						break
					}

					Log.debug(tagged: ["MEDIA_UPLOAD"], "Preparing to export asset ID \(self.localIdentifier), URL: \(String(describing: assetURL)), UTI: \(String(describing: assetUTI))")
				}

				semaphore.signal()
			}
		}
		semaphore.wait()

		guard let url = assetURL else { return (nil, nil) }
		let fileName = url.lastPathComponent
		var exportedAssetURL: URL?
		var conversionError: Error?

		// Check if the conversion was requested and current media format is not found in the list of requested formats
		if let formats = preferredFormats, formats.count > 0 {
			if assetUTI != nil, !formats.contains(assetUTI!) {
				// Conversion is required
				if let outputFormat = formats.first(where: { supportedConversionFormats.contains($0) }) {

					switch (self.mediaType, outputFormat) {
					case (.video, String(kUTTypeMPEG4)):
						if let avAsset = avAsset {
							// Export video
							let localURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName).deletingPathExtension().appendingPathExtension("mp4")
							if avAsset.exportVideo(targetURL: localURL, type: .mp4) {
								exportedAssetURL = localURL
							} else {
								Log.error(tagged: ["MEDIA_UPLOAD"], "Video export failed for asset ID \(self.localIdentifier)")
								conversionError = NSError(ocError: .internal)
							}
						}
					case (.image, String(kUTTypeJPEG)):
						// Convert image to JPEG format
						let localURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName).deletingPathExtension().appendingPathExtension("jpg")
						var imageConverted = false

						if let image = CIImage(contentsOf: assetURL!) {
							imageConverted = image.convert(targetURL: localURL, outputFormat: .JPEG)
						}

						if imageConverted {
							exportedAssetURL = localURL
						} else {
							Log.error(tagged: ["MEDIA_UPLOAD"], "CIImage conversion failed for \(self.localIdentifier)")
							conversionError = NSError(ocError: .internal)
						}
					default:
						break
					}
                } else {
                    Log.debug(tagged: ["MEDIA_UPLOAD"], "No conversion format match for asset ID \(self.localIdentifier), URL: \(String(describing: assetURL)), UTI: \(String(describing: assetUTI))")
                }
			}
		}

		// Bail out if the conversion has failed
		if conversionError != nil {
			return (nil, conversionError)
		}

		// Perform actual upload
		if exportedAssetURL != nil {
			uploadResult = performUpload(sourceURL: exportedAssetURL!, copySource: false)
		} else {
			uploadResult = performUpload(sourceURL: url, copySource: true)
		}

		return uploadResult
	}
}
