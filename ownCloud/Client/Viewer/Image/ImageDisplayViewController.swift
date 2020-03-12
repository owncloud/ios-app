//
//  ImageDisplayViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 17/10/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
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

import UIKit
import ownCloudSDK

public class ImageDisplayViewController : DisplayViewController {

	private let max_zoom_divider: CGFloat = 3.0
	private let activityIndicatorHeight: CGFloat = 50.0

	private let serialQueue: DispatchQueue = DispatchQueue(label: "decode queue")

	// MARK: - Instance variables
	var scrollView: ImageScrollView?

	var activityIndicatorView: UIActivityIndicatorView = {
		let activityIndicator = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.white)
		activityIndicator.translatesAutoresizingMaskIntoConstraints = false
		return activityIndicator
	}()

	// MARK: - Gesture recognizers
	var tapToZoomGestureRecognizer : UITapGestureRecognizer!
	var showHideBarsTapGestureRecognizer: UITapGestureRecognizer!

	// MARK: - View controller lifecycle

	override public func viewDidDisappear(_ animated: Bool) {
		super.viewDidAppear(animated)

		scrollView?.setZoomScale(scrollView!.minimumZoomScale, animated: true)
	}

	override public func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		scrollView?.updateScaleForRotation(size: self.view!.bounds.size)
	}

	func downSampleImage(completion:@escaping (_ downsampledImage:CGImage?) -> Void) {
		if let source = source {
			let size: CGSize = self.view.bounds.size
			let scale: CGFloat = UIScreen.main.scale
			let imageSourceOptions = [kCGImageSourceShouldCache: true] as CFDictionary

			if let imageSource = CGImageSourceCreateWithURL(source as CFURL, imageSourceOptions) {
				let maxDimensionInPixels = max(size.width, size.height) * scale
				let downsampleOptions =  [kCGImageSourceCreateThumbnailFromImageAlways: true,
										  kCGImageSourceShouldCacheImmediately: true,
										  kCGImageSourceCreateThumbnailWithTransform: true,
										  kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels] as CFDictionary
				serialQueue.async {
					if let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) {
						completion(downsampledImage)
					} else {
						completion(nil)
					}
				}
			}
		}
	}

	// MARK: - Specific view

	override func renderSpecificView(completion: @escaping (Bool) -> Void) {

		if source != nil {
			activityIndicatorView.startAnimating()

			downSampleImage {(downsampledImage) in
				OnMainThread {

					self.activityIndicatorView.stopAnimating()
					if downsampledImage != nil {
						self.scrollView = ImageScrollView(frame: .zero)
						self.scrollView?.translatesAutoresizingMaskIntoConstraints = false

						self.view.addSubview(self.scrollView!)
						NSLayoutConstraint.activate([
							self.scrollView!.leftAnchor.constraint(equalTo: self.view.leftAnchor),
							self.scrollView!.rightAnchor.constraint(equalTo: self.view.rightAnchor),
							self.scrollView!.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
							self.scrollView!.topAnchor.constraint(equalTo: self.view.topAnchor)
							])

						self.scrollView?.addSubview(self.activityIndicatorView)
						NSLayoutConstraint.activate([
							self.activityIndicatorView.centerYAnchor.constraint(equalTo: self.scrollView!.centerYAnchor),
							self.activityIndicatorView.centerXAnchor.constraint(equalTo: self.scrollView!.centerXAnchor),
							self.activityIndicatorView.heightAnchor.constraint(equalToConstant: self.activityIndicatorHeight),
							self.activityIndicatorView.widthAnchor.constraint(equalTo: self.activityIndicatorView.heightAnchor)
							])

						let image = UIImage(cgImage: downsampledImage!)
						self.scrollView?.display(image: image, inSize: self.view.bounds.size)

						self.tapToZoomGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapToZoom))
						self.tapToZoomGestureRecognizer.numberOfTapsRequired = 2
						self.scrollView?.addGestureRecognizer(self.tapToZoomGestureRecognizer)

						self.showHideBarsTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.showHideBars))
						self.scrollView?.addGestureRecognizer(self.showHideBarsTapGestureRecognizer)

						self.tapToZoomGestureRecognizer.delegate = self
						self.showHideBarsTapGestureRecognizer.delegate = self

						completion(true)
					} else {
						completion(false)
					}
				}
			}

		} else {
			let alert = ThemedAlertController(with: "Error".localized, message: "Could not get the picture".localized, okLabel: "OK")
			self.parent?.present(alert, animated: true) {
				self.parent?.dismiss(animated: true)
			}
		}
	}

	// MARK: - Frame changes
	override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		self.scrollView?.updateScaleForRotation(size: size)
	}

	// MARK: - Gesture recognizers actions.
	@objc func tapToZoom() {
		if scrollView!.zoomScale != scrollView!.minimumZoomScale {
			scrollView!.setZoomScale(scrollView!.minimumZoomScale, animated: true)
		} else {
			scrollView!.setZoomScale(scrollView!.maximumZoomScale / max_zoom_divider, animated: true)
		}

		setNeedsUpdateOfHomeIndicatorAutoHidden()
	}

	@objc func showHideBars() {
		guard let navigationController = navigationController else {
			return
		}

		if !navigationController.isNavigationBarHidden {
			navigationController.setNavigationBarHidden(true, animated: true)
		} else {
			navigationController.setNavigationBarHidden(false, animated: true)
		}

		setNeedsUpdateOfHomeIndicatorAutoHidden()
	}

	override public var prefersHomeIndicatorAutoHidden: Bool {
		guard let navigationController = navigationController else {
			return false
		}

		guard scrollView != nil else {
			return false
		}

		guard navigationController.isNavigationBarHidden else {
			return false
		}

		return true
	}
}

// MARK: - Display Extension.
extension ImageDisplayViewController: DisplayExtension {
	public static var customMatcher: OCExtensionCustomContextMatcher? = { (context, defaultPriority) in
		do {
			if let mimeType = context.location?.identifier?.rawValue {
				let supportedFormatsRegex = try NSRegularExpression(pattern: "\\A((image/(?!(gif|svg*))))", options: .caseInsensitive)
				let matches = supportedFormatsRegex.numberOfMatches(in: mimeType, options: .reportCompletion, range: NSRange(location: 0, length: mimeType.count))

				if matches > 0 {
					return OCExtensionPriority.locationMatch
				}
			}

			return OCExtensionPriority.noMatch
		} catch {
			return OCExtensionPriority.noMatch
		}
	}
	public static var displayExtensionIdentifier: String = "org.owncloud.image"
	public static var supportedMimeTypes: [String]?
	public static var features: [String : Any]? = [FeatureKeys.canEdit : false]
}

// MARK: - Gesture recognizer delegete.
extension ImageDisplayViewController: UIGestureRecognizerDelegate {

	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		if gestureRecognizer === tapToZoomGestureRecognizer && otherGestureRecognizer === showHideBarsTapGestureRecognizer {
			return true
		}

		return false
	}

	public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		if gestureRecognizer === tapToZoomGestureRecognizer && otherGestureRecognizer === showHideBarsTapGestureRecognizer {
			return false
		}

		if gestureRecognizer === showHideBarsTapGestureRecognizer && otherGestureRecognizer === tapToZoomGestureRecognizer {
			return false
		}

		return true
	}
}
