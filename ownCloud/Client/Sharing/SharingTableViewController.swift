//
//  SharingTableViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 10.04.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2019, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

class SharingTableViewController: StaticTableViewController, UISearchResultsUpdating, UISearchBarDelegate, OCRecipientSearchControllerDelegate {

	// MARK: - Instance Variables
	var shares : [OCShare] = []
	var core : OCCore?
	var item : OCItem?
	var searchController : UISearchController?
	var recipientSearchController : OCRecipientSearchController?

	override func viewDidLoad() {
		super.viewDidLoad()

		let resultsController = SharingSearchResultsTableViewController(style: .grouped)
		resultsController.core = core
		resultsController.item = item

		searchController = UISearchController(searchResultsController: nil)
		searchController?.searchResultsUpdater = self
		searchController?.hidesNavigationBarDuringPresentation = true
		searchController?.dimsBackgroundDuringPresentation = false
		searchController?.searchBar.placeholder = "Search User, Group, Remote".localized
		searchController?.searchBar.delegate = self
		navigationItem.hidesSearchBarWhenScrolling = false
		navigationItem.searchController = searchController
		definesPresentationContext = true

		//navigationController?.navigationItem.searchController?.searchBar.applyThemeCollection(collection)

		guard let item = item else { return }

		recipientSearchController = core?.recipientSearchController(for: item)
		recipientSearchController?.delegate = self

		self.navigationItem.title = "Sharing".localized
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissAnimated))

		addSectionFor(type: .userShare, with: "Users".localized)
		addSectionFor(type: .groupShare, with: "Groups".localized)
		addSectionFor(type: .remote, with: "Remote Users".localized)
	}

	func addSectionFor(type: OCShareType, with title: String) {
		var shareRows: [StaticTableViewRow] = []

		let user = shares.filter { (OCShare) -> Bool in
			if OCShare.type == type {
				return true
			}
			return false
		}

		if user.count > 0 {
			for share in user {
				let resharedUsers = shares.filter { (OCShare) -> Bool in
					if OCShare.owner == share.recipient?.user {
						return true
					}
					return false
				}

				var canEdit = false
				var accessoryType : UITableViewCell.AccessoryType = .none
				if core?.connection.loggedInUser?.userName == share.owner?.userName || core?.connection.loggedInUser?.userName == share.itemOwner?.userName {
					canEdit = true
					accessoryType = .disclosureIndicator
				}

				shareRows.append( StaticTableViewRow(rowWithAction: { (row, _) in

					if canEdit {
						let editSharingViewController = SharingEditUserGroupsTableViewController(style: .grouped)
						editSharingViewController.share = share
						editSharingViewController.reshares = resharedUsers
						editSharingViewController.core = self.core
						self.navigationController?.pushViewController(editSharingViewController, animated: true)
					} else {
						row.cell?.selectionStyle = .none
					}
				}, title: share.recipient!.displayName!, subtitle: share.permissionDescription(), accessoryType: accessoryType) )
			}

			let section : StaticTableViewSection = StaticTableViewSection(headerTitle: title, footerTitle: nil, identifier: "share-section", rows: shareRows)
			self.addSection(section)
		}
	}

	// MARK: - UISearchResultsUpdating Delegate
	func updateSearchResults(for searchController: UISearchController) {
		guard let text = searchController.searchBar.text else { return }
		if text.count > 1 {
			recipientSearchController?.searchTerm = text
			recipientSearchController?.search()
		}
	}

	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
		guard let text = searchBar.text else { return }
		if text.count > 1 {
			recipientSearchController?.searchTerm = text
			recipientSearchController?.search()
		} else {
			resetTable(showShares: false)
		}
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if shares.count == 0 {
		self.searchController?.isActive = true
		OnMainThread {
			self.searchController?.searchBar.becomeFirstResponder()
		}
		}
	}

	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		self.resetTable(showShares: true)
	}

	func searchControllerHasNewResults(_ searchController: OCRecipientSearchController, error: Error?) {
		//print("---> searchController.recipients \(searchController.recipients)")
		OnMainThread {
		guard let recipients = searchController.recipients else {
			self.message(show: true, imageName: "icon-search", title: "No matches".localized, message: "There is no results for this search".localized)
			return
		}

			self.message(show: false)
			var rows : [StaticTableViewRow] = []
			for recipient in recipients {
				guard let user = recipient.user, let name = user.displayName, let itemPath = self.item?.path else { continue }

				rows.append(
					StaticTableViewRow(rowWithAction: { (_, _) in
						let share = OCShare(recipient: recipient, path: itemPath, permissions: .read, expiration: nil)

						self.searchController?.searchBar.text = ""
						self.searchController?.dismiss(animated: true, completion: nil)
						self.core?.connection.createShare(share, options: nil, resultTarget: OCEventTarget(ephermalEventHandlerBlock: { (event, _) in
							if event.error == nil {
								OnMainThread {
									self.shares.append(share)
									self.resetTable(showShares: false)
								}
							} else {
								if let error = event.error {
									self.resetTable(showShares: true)
								let alertController = UIAlertController(with: "Adding User to Share failed".localized, message: error.localizedDescription, okLabel: "OK".localized, action: nil)
								self.present(alertController, animated: true)
								}
							}
						}, userInfo: nil, ephermalUserInfo: nil))
					}, title: name)
				)
			}
			if let section = self.sectionForIdentifier("share-section") {
				self.removeSection(section)
			}
			if let section = self.sectionForIdentifier("search-results") {
				self.removeSection(section)
			}

			self.addSection(
				StaticTableViewSection(headerTitle: nil, footerTitle: nil, identifier: "search-results", rows: rows)
			)
		}
	}

	func searchController(_ searchController: OCRecipientSearchController, isWaitingForResults isSearching: Bool) {

	}

	func resetTable(showShares : Bool) {
		if let section = self.sectionForIdentifier("share-section") {
			self.removeSection(section)
		}
		if let section = self.sectionForIdentifier("search-results") {
			self.removeSection(section)
		}
		if shares.count > 0 && showShares {
			self.message(show: false)
			self.addSectionFor(type: .userShare, with: "Users".localized)
			self.addSectionFor(type: .groupShare, with: "Groups".localized)
			self.addSectionFor(type: .remote, with: "Remote Users".localized)
		} else {
			self.message(show: true, imageName: "icon-search", title: "Search Recipients".localized, message: "Start typing to search users, groups and remote users.".localized)
		}
	}

	// MARK: - Message
	var messageView : UIView?
	var messageContainerView : UIView?
	var messageImageView : VectorImageView?
	var messageTitleLabel : UILabel?
	var messageMessageLabel : UILabel?
	var messageThemeApplierToken : ThemeApplierToken?

	func message(show: Bool, imageName : String? = nil, title : String? = nil, message : String? = nil) {
		if !show {
			if messageView?.superview != nil {
				messageView?.removeFromSuperview()
			}
			if !show {
				return
			}
		}

		if messageView == nil {
			var rootView : UIView
			var containerView : UIView
			var imageView : VectorImageView
			var titleLabel : UILabel
			var messageLabel : UILabel

			rootView = UIView()
			rootView.translatesAutoresizingMaskIntoConstraints = false

			containerView = UIView()
			containerView.translatesAutoresizingMaskIntoConstraints = false

			imageView = VectorImageView()
			imageView.translatesAutoresizingMaskIntoConstraints = false

			titleLabel = UILabel()
			titleLabel.translatesAutoresizingMaskIntoConstraints = false

			messageLabel = UILabel()
			messageLabel.translatesAutoresizingMaskIntoConstraints = false
			messageLabel.numberOfLines = 0
			messageLabel.textAlignment = .center

			containerView.addSubview(imageView)
			containerView.addSubview(titleLabel)
			containerView.addSubview(messageLabel)

			containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[imageView]-(20)-[titleLabel]-[messageLabel]|",
																		options: NSLayoutConstraint.FormatOptions(rawValue: 0),
																		metrics: nil,
																		views: ["imageView" : imageView, "titleLabel" : titleLabel, "messageLabel" : messageLabel])
			)

			imageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
			imageView.widthAnchor.constraint(equalToConstant: 96).isActive = true
			imageView.heightAnchor.constraint(equalToConstant: 96).isActive = true

			titleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
			titleLabel.leftAnchor.constraint(greaterThanOrEqualTo: containerView.leftAnchor).isActive = true
			titleLabel.rightAnchor.constraint(lessThanOrEqualTo: containerView.rightAnchor).isActive = true

			messageLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor).isActive = true
			messageLabel.leftAnchor.constraint(greaterThanOrEqualTo: containerView.leftAnchor).isActive = true
			messageLabel.rightAnchor.constraint(lessThanOrEqualTo: containerView.rightAnchor).isActive = true

			rootView.addSubview(containerView)

			containerView.centerXAnchor.constraint(equalTo: rootView.centerXAnchor).isActive = true
			containerView.centerYAnchor.constraint(equalTo: rootView.centerYAnchor).isActive = true

			containerView.leftAnchor.constraint(greaterThanOrEqualTo: rootView.leftAnchor, constant: 20).isActive = true
			containerView.rightAnchor.constraint(lessThanOrEqualTo: rootView.rightAnchor, constant: -20).isActive = true
			containerView.topAnchor.constraint(greaterThanOrEqualTo: rootView.topAnchor, constant: 20).isActive = true
			containerView.bottomAnchor.constraint(lessThanOrEqualTo: rootView.bottomAnchor, constant: -20).isActive = true

			messageView = rootView
			messageContainerView = containerView
			messageImageView = imageView
			messageTitleLabel = titleLabel
			messageMessageLabel = messageLabel

			messageThemeApplierToken = Theme.shared.add(applier: { [weak self] (_, collection, _) in
				self?.messageView?.backgroundColor = collection.tableBackgroundColor

				self?.messageTitleLabel?.applyThemeCollection(collection, itemStyle: .bigTitle)
				self?.messageMessageLabel?.applyThemeCollection(collection, itemStyle: .bigMessage)
			})
		}

		if messageView?.superview == nil {
			if let rootView = self.messageView, let containerView = self.messageContainerView {
				containerView.alpha = 0
				containerView.transform = CGAffineTransform(translationX: 0, y: 15)

				rootView.alpha = 0

				self.view.addSubview(rootView)

				rootView.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor).isActive = true
				rootView.rightAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.rightAnchor).isActive = true
				rootView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor).isActive = true
				rootView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor).isActive = true

				UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut, animations: {
					rootView.alpha = 1
				}, completion: { (_) in
					UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
						containerView.alpha = 1
						containerView.transform = CGAffineTransform.identity
					})
				})
			}
		}

		if imageName != nil {
			messageImageView?.vectorImage = Theme.shared.tvgImage(for: imageName!)
		}
		if title != nil {
			messageTitleLabel?.text = title!
		}
		if message != nil {
			messageMessageLabel?.text = message!
		}
	}
/*
	// MARK: - Theme support

	override func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.searchController?.searchBar.applyThemeCollection(collection)
		super.applyThemeCollection(theme: theme, collection: collection, event: event)
	}*/
}
