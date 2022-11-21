//
//  AccountControllerCell.swift
//  ownCloudAppShared
//
//  Created by Felix Schwarz on 10.11.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2022, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK
import ownCloudApp

class AccountControllerCell: ThemeableCollectionViewListCell {
	static let avatarSideLength : CGFloat = 45

	public var titleLabel: UILabel = UILabel()
	public var detailLabel: UILabel = UILabel()
	public var logoFallbackView: UIImageView = UIImageView()
	public var iconView: ResourceViewHost = ResourceViewHost(fallbackSize: CGSize(width: AccountControllerCell.avatarSideLength, height: AccountControllerCell.avatarSideLength))
	public var infoView: UIView = UIView()
	public var statusIconView: UIImageView = UIImageView()
	public var disconnectButton: UIButton = UIButton()

	func configure() {
		titleLabel.translatesAutoresizingMaskIntoConstraints = false
		detailLabel.translatesAutoresizingMaskIntoConstraints = false
		iconView.translatesAutoresizingMaskIntoConstraints = false
		logoFallbackView.translatesAutoresizingMaskIntoConstraints = false
		infoView.translatesAutoresizingMaskIntoConstraints = false
		statusIconView.translatesAutoresizingMaskIntoConstraints = false
		disconnectButton.translatesAutoresizingMaskIntoConstraints = false

		logoFallbackView.contentMode = .scaleAspectFit
		logoFallbackView.image = Branding.shared.brandedImageNamed(.bookmarkIcon)

		iconView.fallbackView = logoFallbackView

		titleLabel.font = UIFont.preferredFont(forTextStyle: .title3, with: .bold)
		titleLabel.adjustsFontForContentSizeCategory = true

		detailLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
		detailLabel.adjustsFontForContentSizeCategory = true

		detailLabel.textColor = UIColor.gray

		let symbolConfig = UIImage.SymbolConfiguration(pointSize: 10)

		var buttonConfig = UIButton.Configuration.gray()
		buttonConfig.image = UIImage(systemName: "eject.fill", withConfiguration: symbolConfig)
		buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
		buttonConfig.buttonSize = .mini
		buttonConfig.cornerStyle = .capsule

		// disconnectButton.setImage(UIImage(systemName: "eject.fill"), for: .normal)
		disconnectButton.configuration = buttonConfig
		disconnectButton.addAction(UIAction(handler: { [weak self] _ in
			self?.accountController?.disconnect(completion: nil)
		}), for: .primaryActionTriggered)

		contentView.addSubview(titleLabel)
		contentView.addSubview(detailLabel)
		contentView.addSubview(iconView)
		contentView.addSubview(statusIconView)
		contentView.addSubview(infoView)

		infoView.addSubview(disconnectButton)
	}

	func configureLayout() {
		NSLayoutConstraint.activate([
			iconView.widthAnchor.constraint(equalToConstant: AccountControllerCell.avatarSideLength),
			iconView.heightAnchor.constraint(equalToConstant: AccountControllerCell.avatarSideLength),
			iconView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

			iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
			iconView.trailingAnchor.constraint(equalTo: titleLabel.leadingAnchor, constant: -10),
			iconView.trailingAnchor.constraint(equalTo: detailLabel.leadingAnchor, constant: -10),

			statusIconView.trailingAnchor.constraint(equalTo: iconView.trailingAnchor),
			statusIconView.bottomAnchor.constraint(equalTo: iconView.bottomAnchor),
			statusIconView.widthAnchor.constraint(equalToConstant: 16),
			statusIconView.heightAnchor.constraint(equalToConstant: 16),

			titleLabel.trailingAnchor.constraint(equalTo: infoView.leadingAnchor),
			titleLabel.topAnchor.constraint(equalTo: iconView.topAnchor),

			detailLabel.trailingAnchor.constraint(equalTo: infoView.leadingAnchor),
			detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
			detailLabel.bottomAnchor.constraint(equalTo: iconView.bottomAnchor),

			infoView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
			infoView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),
			infoView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

			disconnectButton.leadingAnchor.constraint(greaterThanOrEqualTo: infoView.leadingAnchor),
			disconnectButton.trailingAnchor.constraint(lessThanOrEqualTo: infoView.trailingAnchor),
			disconnectButton.centerYAnchor.constraint(equalTo: infoView.centerYAnchor),

			contentView.heightAnchor.constraint(equalToConstant: AccountControllerCell.avatarSideLength + 20)

			// separatorLayoutGuide.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor)
		])

		infoView.setContentHuggingPriority(.required, for: .horizontal)
		logoFallbackView.setContentHuggingPriority(.required, for: .vertical)
		titleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
		detailLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		configure()
		configureLayout()
	}

	required init?(coder: NSCoder) {
		fatalError()
	}

	var title: String? {
		didSet {
			titleLabel.text = title
		}
	}
	var detail: String? {
		didSet {
			detailLabel.text = detail
		}
	}

	var avatarViewProvider: OCViewProvider? {
		didSet {
			iconView.activeViewProvider = avatarViewProvider
		}
	}

	var showDisconnectButtonObserver: NSKeyValueObservation?
	var richStatusObserver: NSKeyValueObservation?

	weak var accountController: AccountController? {
		willSet {
			showDisconnectButtonObserver?.invalidate()
			showDisconnectButtonObserver = nil

			richStatusObserver?.invalidate()
			richStatusObserver = nil

			OnMainThread { [weak self] in
				if self?.accountController == nil {
					self?.disconnectButton.isHidden = true
					self?.updateStatus(iconFor: nil)
				}
			}
		}
		didSet {
			if let accountController = accountController {
				showDisconnectButtonObserver = accountController.observe(\.showDisconnectButton, options: .initial, changeHandler: { [weak self] (accountController, change) in
					let showDisconnectButton = accountController.showDisconnectButton

					Log.debug("\(accountController) reports showDisconnectButton \(accountController.showDisconnectButton) \(showDisconnectButton)")

					OnMainThread { [weak self] in
						if accountController == self?.accountController {
							self?.disconnectButton.isHidden = !showDisconnectButton
						}
					}
				})

				richStatusObserver = accountController.connection?.observe(\.richStatus, options: .initial, changeHandler: { [weak self] (accountConnection, change) in
					let richStatus = accountConnection.richStatus

					OnMainThread { [weak self] in
						if let self = self, accountConnection == self.accountController?.connection {
							self.updateStatus(from: richStatus)
						}
					}
				})
			}
		}
	}

	func updateStatus(iconFor status: AccountConnection.Status?) {
		var color: UIColor?

		if let status = status {
			switch status {
				case .offline: break
					// color = .systemGray

				case .connecting, .coreAvailable:
					color = .systemYellow

				case .online:
					color = .systemGreen

				case .busy:
					color = .systemBlue

				case .authenticationError:
					color = .systemRed
			}
		}

		if let color = color {
			var symbolConfig = UIImage.SymbolConfiguration(paletteColors: [ color ])
			symbolConfig = symbolConfig.applying(UIImage.SymbolConfiguration(font: .systemFont(ofSize: 16)))

			statusIconView.preferredSymbolConfiguration = symbolConfig
			statusIconView.contentMode = .scaleAspectFit
			statusIconView.image = UIImage(systemName: "circlebadge.fill")
		} else {
			statusIconView.image = nil
		}
	}

	func updateStatus(from richStatus: AccountConnectionRichStatus?) {
		if let richStatus {
			updateStatus(iconFor: richStatus.status)
		}

		if let richStatus, let richStatusText = richStatus.text, richStatus.status != .offline {
			detailLabel.text = richStatusText
		} else {
			detailLabel.text = detail
		}
	}

	open override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		var backgroundConfig = UIBackgroundConfiguration.listSidebarCell()
		backgroundConfig.cornerRadius = 10
		backgroundConfig.backgroundColor = UIColor(white: 1.0, alpha: 0.5)

		backgroundConfiguration = backgroundConfig
	}
}

extension AccountControllerCell {
	static func registerCellProvider() {
		let accountControllerListCellRegistration = UICollectionView.CellRegistration<AccountControllerCell, CollectionViewController.ItemRef> { (cell, indexPath, collectionItemRef) in
			var title : String?
			var detail : String?
			var avatarViewProvider : OCViewProvider?
			// var expandable = false
			weak var controller: AccountController?

			collectionItemRef.ocCellConfiguration?.configureCell(for: collectionItemRef, with: { itemRecord, item, cellConfiguration in
				if let accountController = item as? AccountController, let bookmark = accountController.connection?.bookmark {
					title = bookmark.displayName
					detail = bookmark.shortName
					avatarViewProvider = bookmark.avatar

					controller = accountController
				}
			})

			cell.title = title
			cell.detail = detail
			cell.avatarViewProvider = avatarViewProvider
			cell.accountController = controller
		}

		CollectionViewCellProvider.register(CollectionViewCellProvider(for: .accountController, with: { collectionView, cellConfiguration, itemRecord, itemRef, indexPath in
			switch cellConfiguration?.style.type {
				default:
					return collectionView.dequeueConfiguredReusableCell(using: accountControllerListCellRegistration, for: indexPath, item: itemRef)
			}
		}))
	}
}
