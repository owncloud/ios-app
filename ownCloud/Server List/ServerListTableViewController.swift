//
//  ServerListTableViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.03.18.
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
import PocketSVG

class ServerListTableViewController: UITableViewController, Themeable {

	@IBOutlet var welcomeOverlayView: UIView!
	@IBOutlet var welcomeTitleLabel : UILabel!
	@IBOutlet var welcomeMessageLabel : UILabel!
	@IBOutlet var welcomeAddServerButton : ThemeButton!
	@IBOutlet var welcomeLogoImageView : UIImageView!
	@IBOutlet var welcomeLogoTVGView : VectorImageView!
	// @IBOutlet var welcomeLogoSVGView : SVGImageView!

	override init(style: UITableViewStyle) {
		super.init(style: style)

		NotificationCenter.default.addObserver(self, selector: #selector(serverListChanged), name: Notification.Name.BookmarkManagerListChanged, object: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NotificationCenter.default.removeObserver(self, name: Notification.Name.BookmarkManagerListChanged, object: nil)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		self.tableView.register(ServerListBookmarkCell.self, forCellReuseIdentifier: "bookmark-cell")
		self.tableView.rowHeight = UITableViewAutomaticDimension
		self.tableView.estimatedRowHeight = 80

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(addBookmark))

		welcomeOverlayView.translatesAutoresizingMaskIntoConstraints = false

		welcomeLogoTVGView.vectorImage = TVGImage(named: "owncloud-logo")

		/*
		var bezierPaths : [SVGBezierPath]
		(_, bezierPaths) = (TVGImage(named: "owncloud-logo")?.svgBezierPaths())!
		welcomeLogoSVGView.paths = bezierPaths
		*/

		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false

		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.

		self.navigationItem.title = "ownCloud"
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		self.navigationController?.setToolbarHidden(false, animated: animated)

		Theme.shared.register(client: self)

		welcomeOverlayView.layoutSubviews()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

		updateNoServerMessageVisibility()

		self.toolbarItems = [
			UIBarButtonItem(title: "Help", style: UIBarButtonItemStyle.plain, target: self, action: #selector(help)),
			UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
			UIBarButtonItem(title: "Settings", style: UIBarButtonItemStyle.plain, target: self, action: #selector(settings))
		]

		/*
		let shapeLayers : [CAShapeLayer]? = (welcomeLogoSVGView.layer as? SVGLayer)!.value(forKey: "_shapeLayers") as? [CAShapeLayer]

		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
			for shapeLayer in shapeLayers! {
				shapeLayer.strokeColor = UIColor.black.cgColor
				shapeLayer.lineWidth = 2
				shapeLayer.fillColor = nil

				let pathAnimation = CABasicAnimation(keyPath: "strokeEnd")

				pathAnimation.duration = 0.5
				pathAnimation.fromValue = 0
				pathAnimation.toValue = 1

				shapeLayer.add(pathAnimation, forKey: pathAnimation.keyPath)
			}
		}
		*/
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

		self.navigationController?.setToolbarHidden(true, animated: animated)

		Theme.shared.unregister(client: self)
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		welcomeAddServerButton.themeColorCollection = collection.neutralCollection

		self.tableView.applyThemeCollection(collection)

		if event == .update {
			self.tableView.reloadData()
		}
	}

	func updateNoServerMessageVisibility() {
		if BookmarkManager.sharedBookmarkManager.bookmarks.count == 0 {
			let safeAreaLayoutGuide : UILayoutGuide = self.tableView.safeAreaLayoutGuide
			var constraint : NSLayoutConstraint

			if welcomeOverlayView.superview != self.view {

				welcomeOverlayView.alpha = 0

				self.view.addSubview(welcomeOverlayView)

				UIView.animate(withDuration: 0.2, animations: {
					self.welcomeOverlayView.alpha = 1
				})

				welcomeOverlayView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor).isActive = true
				welcomeOverlayView.centerYAnchor.constraint(equalTo: safeAreaLayoutGuide.centerYAnchor).isActive = true

				constraint = welcomeOverlayView.leftAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.leftAnchor, constant: 30)
				constraint.priority = UILayoutPriority(rawValue: 900)
				constraint.isActive = true

				constraint = welcomeOverlayView.rightAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.rightAnchor, constant: 30)
				constraint.priority = UILayoutPriority(rawValue: 900)
				constraint.isActive = true

				tableView.separatorStyle = UITableViewCellSeparatorStyle.none
				tableView.reloadData()
			}

			if self.navigationItem.leftBarButtonItem != nil {
				self.navigationItem.leftBarButtonItem = nil
			}

		} else {

			if welcomeOverlayView.superview == self.view {
				welcomeOverlayView.removeFromSuperview()

				tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
				tableView.reloadData()
			}

			if self.navigationItem.leftBarButtonItem == nil {
				self.navigationItem.leftBarButtonItem = self.editButtonItem
			}
		}
	}

	// MARK: - Actions
	@IBAction func addBookmark() {

        let viewController : BookmarkViewController = BookmarkViewController(style: UITableViewStyle.grouped)
        self.navigationController?.pushViewController(viewController, animated: true)
		updateNoServerMessageVisibility()
	}

	var themeCounter : Int = 0

	@IBAction func help() {
		var themeStyle : ThemeCollectionStyle?

		themeCounter += 1

		switch themeCounter % 3 {
			case 0:	themeStyle = .dark
			case 1:	themeStyle = .light
			case 2:	themeStyle = .contrast
			default: themeStyle = .dark
		}

		UIView.animate(withDuration: 0.25) {
			Theme.shared.activeCollection = ThemeCollection(darkBrandColor: UIColor(hex: 0x1D293B), lightBrandColor: UIColor(hex: 0x468CC8), style: themeStyle!)
		}
	}

	@IBAction func settings() {
		let viewController : GlobalSettingsViewController = GlobalSettingsViewController(style: UITableViewStyle.grouped)

		self.navigationController?.pushViewController(viewController, animated: true)
	}

	// MARK: - Track external changes
	var ignoreServerListChanges : Bool = false

	@objc func serverListChanged() {
		DispatchQueue.main.async {
			if !self.ignoreServerListChanges {
				self.tableView.reloadData()
			}
		}
	}

	// MARK: - Table view delegate
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let bookmark = BookmarkManager.sharedBookmarkManager.bookmark(at: indexPath.row)

		let clientRootViewController = ClientRootViewController(bookmark: bookmark!)

		self.present(clientRootViewController, animated: true, completion: nil)

		Log.log("Bookmark data: \(bookmark?.bookmarkData().description ?? "none")")
	}

	// MARK: - Table view data source
	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return BookmarkManager.sharedBookmarkManager.bookmarks.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let bookmarkCell = self.tableView.dequeueReusableCell(withIdentifier: "bookmark-cell", for: indexPath) as? ServerListBookmarkCell else {

		    let cell = ServerListBookmarkCell()
		    return cell
		}

		if let bookmark : OCBookmark = BookmarkManager.sharedBookmarkManager.bookmark(at: indexPath.row) {
			bookmarkCell.titleLabel.text = bookmark.url.host
			bookmarkCell.detailLabel.text = bookmark.url.absoluteString
		}

		return bookmarkCell
	}

	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		return [
				UITableViewRowAction(style: UITableViewRowActionStyle.destructive, title: "Delete", handler: { (_, indexPath) in
					if let bookmark = BookmarkManager.sharedBookmarkManager.bookmark(at: indexPath.row) {
						let alertController = UIAlertController.init(title: NSString.init(format: NSLocalizedString("Really delete '%@'?", comment: "") as NSString, bookmark.name ?? "" as NSString) as String,
											     message: NSLocalizedString("This will also delete all locally stored file copies.", comment: ""),
											     preferredStyle: .actionSheet)

						alertController.addAction(UIAlertAction.init(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))

						alertController.addAction(UIAlertAction.init(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: { (_) in

							self.ignoreServerListChanges = true

							BookmarkManager.sharedBookmarkManager.removeBookmark(bookmark)

							tableView.performBatchUpdates({
								tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
							}, completion: { (_) in
								self.ignoreServerListChanges = false
							})

							// TODO: Delete vault

							self.updateNoServerMessageVisibility()
						}))

						self.present(alertController, animated: true, completion: nil)
					}
				})
			]
	}

	override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
		BookmarkManager.sharedBookmarkManager.moveBookmark(from: fromIndexPath.row, to: to.row)
	}
}
