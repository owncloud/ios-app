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
import MediaPlayer
import ownCloudSDK
import MobileCoreServices

class MediaDisplayViewController : DisplayViewController {

	static let MediaPlaybackFinishedNotification = NSNotification.Name("media_playback.finished")
    static let MediaPlaybackNextTrackNotification = NSNotification.Name("media_playback.play_next")
    static let MediaPlaybackPreviousTrackNotification = NSNotification.Name("media_playback.play_previous")

	private var playerStatusObservation: NSKeyValueObservation?
	private var playerItemStatusObservation: NSKeyValueObservation?
	private var playerItem: AVPlayerItem?
	private var player: AVPlayer?
	private var playerViewController: AVPlayerViewController?

	// Information for now playing
	private var mediaItemArtwork: MPMediaItemArtwork?
	private var mediaItemTitle: String?
	private var mediaItemArtist: String?

	deinit {
		playerStatusObservation?.invalidate()
		playerItemStatusObservation?.invalidate()
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil

		NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
		NotificationCenter.default.removeObserver(self, name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
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
				playerViewController!.updatesNowPlayingInfoCenter = false

				if UIApplication.shared.applicationState == .active {
					playerViewController!.player = player
				}

				addChild(playerViewController!)
				playerViewController!.view.frame = self.view.bounds
				self.view.addSubview(playerViewController!.view)
				playerViewController!.didMove(toParent: self)

				// Add artwork to the player overlay if corresponding meta data item is available in the asset
				if let artworkMetadataItem = asset.commonMetadata.filter({$0.commonKey == AVMetadataKey.commonKeyArtwork}).first,
					let imageData = artworkMetadataItem.dataValue,
					let overlayView = playerViewController?.contentOverlayView {

					if let artworkImage = UIImage(data: imageData) {

						// Construct image view overlay for AVPlayerViewController
						let imageView = UIImageView(image: artworkImage)
						imageView.translatesAutoresizingMaskIntoConstraints = false
						imageView.contentMode = .center
						playerViewController?.contentOverlayView?.addSubview(imageView)

						NSLayoutConstraint.activate([
							imageView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor),
							imageView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor)
						])

						// Create MPMediaItemArtwork to be shown in 'now playing' in the lock screen
						mediaItemArtwork = MPMediaItemArtwork(boundsSize: artworkImage.size, requestHandler: { (_) -> UIImage in
							return artworkImage
						})
					}
				}

				// Extract title meta-data item
				mediaItemTitle = asset.commonMetadata.filter({$0.commonKey == AVMetadataKey.commonKeyTitle}).first?.value as? String

				// Extract artist meta-data item
				mediaItemArtist = asset.commonMetadata.filter({$0.commonKey == AVMetadataKey.commonKeyArtist}).first?.value as? String

				// Setup player status observation handler
				playerStatusObservation = player!.observe(\AVPlayer.status, options: [.initial, .new], changeHandler: { [weak self] (player, _) in
					if player.status == .readyToPlay {

						self?.setupRemoteTransportControls()

						try? AVAudioSession.sharedInstance().setCategory(.playback)
						try? AVAudioSession.sharedInstance().setActive(true)

						self?.player?.play()

						self?.updateNowPlayingInfoCenter()

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

	private func setupRemoteTransportControls() {
		// Get the shared MPRemoteCommandCenter
		let commandCenter = MPRemoteCommandCenter.shared()

		// Add handler for Play Command
		commandCenter.playCommand.addTarget { [weak self] _ in
			if let player = self?.player {
				if player.rate == 0.0 {
                    player.play()
                    self?.updateNowPlayingTimeline()
					return .success
				}
			}

			return .commandFailed
		}

		// Add handler for Pause Command
		commandCenter.pauseCommand.addTarget { [weak self] _ in
			if let player = self?.player {
				if player.rate == 1.0 {
					player.pause()
                    self?.updateNowPlayingTimeline()
					return .success
				}
			}

			return .commandFailed
		}

		// Add handler for skip forward command
		commandCenter.skipForwardCommand.addTarget { [weak self] (_) -> MPRemoteCommandHandlerStatus in
			if let player = self?.player {
				let time = player.currentTime() + CMTime(seconds: 10.0, preferredTimescale: 1)
				player.seek(to: time) { (finished) in
					if finished {
                        self?.updateNowPlayingTimeline()
					}
				}
                return .success
			}
			return .commandFailed
		}

		// Add handler for skip backward command
		commandCenter.skipBackwardCommand.addTarget { [weak self] (_) -> MPRemoteCommandHandlerStatus in
			if let player = self?.player {
				let time = player.currentTime() - CMTime(seconds: 10.0, preferredTimescale: 1)
				player.seek(to: time) { (finished) in
					if finished {
                        self?.updateNowPlayingTimeline()
					}
				}
                return .success
			}
			return .commandFailed
		}
        
        // TODO: Skip controls are useful for podcasts but not so much for music.
        // Disable them for now but keep the implementation of command handlers
        commandCenter.skipForwardCommand.isEnabled = false
        commandCenter.skipBackwardCommand.isEnabled = false

		// Configure next / previous track buttons according to number of items to be played
        var enableNextTrackCommand = false
        var enablePreviousTrackCommand = false

        if let itemIndex = self.itemIndex {
            if itemIndex > 0 {
                enablePreviousTrackCommand = true
            }
            
            if let displayHostController = self.parent as? DisplayHostViewController, let items = displayHostController.items {
                enableNextTrackCommand = itemIndex < (items.count - 1)
            }
        }
        
        commandCenter.nextTrackCommand.isEnabled = enableNextTrackCommand
		commandCenter.previousTrackCommand.isEnabled = enablePreviousTrackCommand
        
        // Add handler for seek forward command
        commandCenter.nextTrackCommand.addTarget { [weak self] (_) -> MPRemoteCommandHandlerStatus in
            if let player = self?.player {
                player.pause()
                OnMainThread {
                    NotificationCenter.default.post(name: MediaDisplayViewController.MediaPlaybackNextTrackNotification, object: nil)
                }
                return .success
            }
            return .commandFailed
        }
        
        // Add handler for seek backward command
        commandCenter.previousTrackCommand.addTarget { [weak self] (_) -> MPRemoteCommandHandlerStatus in
            if let player = self?.player {
                player.pause()
                OnMainThread {
                    NotificationCenter.default.post(name: MediaDisplayViewController.MediaPlaybackPreviousTrackNotification, object: nil)
                }
                return .success
            }
            return .commandFailed
        }
	}

    private func updateNowPlayingTimeline() {

        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyElapsedPlaybackTime] = self.playerItem?.currentTime().seconds
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = self.player?.rate
    }
    
	private func updateNowPlayingInfoCenter() {
        guard let player = self.player else { return }
		guard let playerItem = self.playerItem else { return }

		var nowPlayingInfo = [String : Any]()

		nowPlayingInfo[MPMediaItemPropertyTitle] = mediaItemTitle
		nowPlayingInfo[MPMediaItemPropertyArtist] = mediaItemArtist
		nowPlayingInfo[MPNowPlayingInfoPropertyAssetURL] = source
        nowPlayingInfo[MPNowPlayingInfoPropertyCurrentPlaybackDate] = playerItem.currentDate()
		nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = playerItem.currentTime().seconds
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = playerItem.asset.duration.seconds

		if mediaItemArtwork != nil {
			nowPlayingInfo[MPMediaItemPropertyArtwork] = mediaItemArtwork
		}

		MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
        
        updateNowPlayingTimeline()
	}
}

// MARK: - Display Extension.
extension MediaDisplayViewController: DisplayExtension {
	static var customMatcher: OCExtensionCustomContextMatcher? = { (context, defaultPriority) in
		if let mimeType = context.location?.identifier?.rawValue {

			if MediaDisplayViewController.mimeTypeConformsTo(mime: mimeType, utTypeClass: kUTTypeAudiovisualContent) {
				return OCExtensionPriority.locationMatch
			}
		}
		return OCExtensionPriority.noMatch
	}
	static var displayExtensionIdentifier: String = "org.owncloud.media"
	static var supportedMimeTypes: [String]?
	static var features: [String : Any]? = [FeatureKeys.canEdit : false]
}
