//
//  MediaDisplayViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 30.06.2019.
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

import UIKit
import AVKit
import ownCloudSDK

class MediaDisplayViewController : DisplayViewController {

	static let MediaPlaybackFinishedNotification = NSNotification.Name("media_playback.finished")

	private var playerStatusObservation: NSKeyValueObservation?
	private var playerItemStatusObservation: NSKeyValueObservation?
	private var playerItem: AVPlayerItem?
	private var player: AVPlayer?
	private var playerViewController: AVPlayerViewController?

	deinit {
		playerStatusObservation?.invalidate()
		playerItemStatusObservation?.invalidate()
		NotificationCenter.default.removeObserver(self)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		self.requiresLocalItemCopy = !(OCAppIdentity.shared.userDefaults?.streamingEnabled ?? false)

		NotificationCenter.default.addObserver(self, selector: #selector(handleDidEnterBackgroundNotification), name: UIApplication.didEnterBackgroundNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleWillEnterForegroundNotification), name: UIApplication.willEnterForegroundNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(handleAVPlayerItem(notification:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}

	override func viewSafeAreaInsetsDidChange() {
		super.viewSafeAreaInsetsDidChange()

		if let playerController = self.playerViewController {
			playerController.view.translatesAutoresizingMaskIntoConstraints = false

			NSLayoutConstraint.activate([
				playerController.view.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
				playerController.view.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
				playerController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
				playerController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
				])
		}

		self.view.layoutIfNeeded()
	}

	override func renderSpecificView(completion: @escaping (Bool) -> Void) {
		if let sourceURL = source {
			playerItemStatusObservation?.invalidate()
			playerItemStatusObservation = nil
			player?.pause()

			let asset = AVURLAsset(url: sourceURL, options: self.httpAuthHeaders != nil ? ["AVURLAssetHTTPHeaderFieldsKey" : self.httpAuthHeaders!] : nil )
			playerItem = AVPlayerItem(asset: asset)

			playerItemStatusObservation = playerItem?.observe(\AVPlayerItem.status, options: [.initial, .new], changeHandler: { [weak self] (item, _) in
				if item.status == .failed {
					self?.present(error: item.error)
				}
			})

			if player == nil {
				player = AVPlayer(playerItem: playerItem)
				player?.allowsExternalPlayback = true
				playerViewController = AVPlayerViewController()
				playerViewController!.player = player

				addChild(playerViewController!)
				playerViewController!.view.frame = self.view.bounds
				self.view.addSubview(playerViewController!.view)
				playerViewController!.didMove(toParent: self)

				// Add artwork to the player overlay if corresponding meta data item is available in the asset
				if let artworkMetadataItem = asset.commonMetadata.filter({$0.commonKey == AVMetadataKey.commonKeyArtwork}).first,
					let imageData = artworkMetadataItem.dataValue,
					let overlayView = playerViewController?.contentOverlayView {

					let artworkImage = UIImage(data: imageData)
					let imageView = UIImageView(image: artworkImage)
					imageView.translatesAutoresizingMaskIntoConstraints = false
					imageView.contentMode = .center
					playerViewController?.contentOverlayView?.addSubview(imageView)

					NSLayoutConstraint.activate([
						imageView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
						imageView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor)
					])
				}

				playerStatusObservation = player!.observe(\AVPlayer.status, options: [.initial, .new], changeHandler: { [weak self] (player, _) in
					if player.status == .readyToPlay {

						try? AVAudioSession.sharedInstance().setCategory(.playback)
						try? AVAudioSession.sharedInstance().setActive(true)

						self?.player?.play()
					} else if player.status == .failed {
						self?.present(error: self?.player?.error)
					}
				})
			} else {
				player!.replaceCurrentItem(with: playerItem)
			}
			completion(true)
		} else {
			completion(false)
		}
	}

	private func present(error:Error?) {
		guard let error = error else { return }

		OnMainThread { [weak self] in
			let alert = ThemedAlertController(with: "Error".localized, message: error.localizedDescription, okLabel: "OK".localized, action: {
				self?.navigationController?.popViewController(animated: true)
			})

			self?.parent?.present(alert, animated: true)
		}
	}

	@objc private func handleDidEnterBackgroundNotification() {
		playerViewController?.player = nil
	}

	@objc private func handleWillEnterForegroundNotification() {
		playerViewController?.player = player
	}

	@objc private func handleAVPlayerItem(notification:Notification) {
		try? AVAudioSession.sharedInstance().setActive(false)
		OnMainThread {
			NotificationCenter.default.post(name: MediaDisplayViewController.MediaPlaybackFinishedNotification, object: self.item)
		}
	}
}

// MARK: - Display Extension.
extension MediaDisplayViewController: DisplayExtension {
	static var customMatcher: OCExtensionCustomContextMatcher? = { (context, defaultPriority) in
		do {
			if let mimeType = context.location?.identifier?.rawValue {
				let supportedFormatsRegex = try NSRegularExpression(pattern: "\\A((video/)|(audio/))",
																	options: .caseInsensitive)
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
	static var displayExtensionIdentifier: String = "org.owncloud.media"
	static var supportedMimeTypes: [String]?
	static var features: [String : Any]? = [FeatureKeys.canEdit : false]
}
