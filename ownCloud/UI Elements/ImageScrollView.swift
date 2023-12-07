//
//  ImageScrollView.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 19/10/2018.
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
import VisionKit
import ownCloudSDK
import ownCloudAppShared

class ImageScrollView: UIScrollView {
	// MARK: - Constants
	private let MAXIMUM_ZOOM_SCALE: CGFloat = 6.0

	// MARK: - Instance Variables
	private var imageView: UIImageView?
	private var imageAnalysisInteraction: Any?

	// MARK: - Init
	override init(frame: CGRect) {
		super.init(frame: frame)

		showsVerticalScrollIndicator = false
		showsHorizontalScrollIndicator = false
		decelerationRate = UIScrollView.DecelerationRate.fast
		delegate = self
		backgroundColor = .black
		maximumZoomScale = MAXIMUM_ZOOM_SCALE
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		centerImage()
	}

	// MARK: - Manage Scale
	private func centerImage() {
		guard let imageView else {
			return
		}

		let boundsSize: CGSize = bounds.size
		var frameToCenter: CGRect = imageView.frame

		// center horizontally
		if frameToCenter.size.width < boundsSize.width {
			frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width)/2
		} else {
			frameToCenter.origin.x = 0
		}

		// center vertically
		if frameToCenter.size.height < boundsSize.height {
			frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height)/2
		} else {
			frameToCenter.origin.y = 0
		}

		imageView.frame = frameToCenter
	}

	private func setMinZoomScaleForCurrentBounds(_ size: CGSize? = nil) {
		guard let image = imageView?.image else { return }

		var boundsSize: CGSize
		if size == nil {
			boundsSize = self.bounds.size
		} else {
			boundsSize = size!
		}
		let imageSize = image.size

		let xScale =  boundsSize.width  / imageSize.width
		let yScale = boundsSize.height / imageSize.height
		let minScale = min(xScale, yScale)

		self.minimumZoomScale = minScale
	}
}

// MARK: - Public API
extension ImageScrollView {
	func updateScaleForRotation(size: CGSize) {
		contentSize = size
		setMinZoomScaleForCurrentBounds(size)
		setZoomScale(zoomScale, animated: true)
		zoomScale = minimumZoomScale
		centerImage()
		setNeedsLayout()
	}

	func display(image: UIImage, inSize: CGSize) {
		imageView?.removeFromSuperview()

		imageView = UIImageView(image: image)
		guard let imageView else { return }

		imageView.accessibilityIdentifier = "loaded-image-gallery"
		imageView.contentMode = .scaleAspectFit

		addSubview(imageView)
		updateScaleForRotation(size: inSize)

		if imageInteractionsAllowed {
			analyzeImage(image: image)
		}
	}

	var hasActiveImageAnalysisSelection: Bool {
		if #available(iOS 16, *) {
			if let interaction = imageAnalysisInteraction as? ImageAnalysisInteraction {
				return interaction.selectableItemsHighlighted
			}
		}

		return false
	}

	func analyzeImage(image: UIImage) {
		if #available(iOS 16, *) {
			guard ImageAnalyzer.isSupported else {
				return
			}

			let interaction = ImageAnalysisInteraction()
			imageView?.addInteraction(interaction)

			imageAnalysisInteraction = interaction

			Task.detached(priority: .userInitiated, operation: {
				do {
					let configuration = ImageAnalyzer.Configuration([.machineReadableCode, .text, .visualLookUp])
					let analyzer = ImageAnalyzer()
					let analysis = try await analyzer.analyze(image, configuration: configuration)
					await MainActor.run {
						interaction.analysis = analysis
						interaction.preferredInteractionTypes = [.automatic]
					}
				} catch {
					await MainActor.run(body: {
						interaction.preferredInteractionTypes = []
					})
				}
			})
		}
	}
}

// MARK: - ScrollViewDelegate
extension ImageScrollView: UIScrollViewDelegate {
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return imageView
	}

	func scrollViewDidZoom(_ scrollView: UIScrollView) {
		centerImage()
	}

}

// MARK: - Class Settings
public extension OCClassSettingsKey {
	static let allowImageInteractions = OCClassSettingsKey("allow-image-interactions")
}

extension ImageScrollView {
	static func registerImageInteractionsSettings() {
		Action.registerOCClassSettingsDefaults([
			.allowImageInteractions : true
		], metadata: [
			.allowImageInteractions : [
				.type 		: OCClassSettingsMetadataType.boolean,
				.label		: "Allow Image Interactions",
				.description 	: "Allow (true) or disallow (false) text/selection/OCR interactions with images.",
				.status		: OCClassSettingsKeyStatus.advanced,
				.category	: "Actions"
			]
		])
	}

	var imageInteractionsAllowed: Bool {
		return Action.classSetting(forOCClassSettingsKey: .allowImageInteractions) as? Bool ?? true
	}
}
