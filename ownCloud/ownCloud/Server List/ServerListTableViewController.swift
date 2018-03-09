//
//  ServerListTableViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 08.03.18.
//  Copyright © 2018 ownCloud. All rights reserved.
//

import UIKit
import ownCloudSDK

class ServerListTableViewController: UITableViewController {

	@IBOutlet var welcomeOverlayView: UIView!

	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.tableView.register(ServerListBookmarkCell.self, forCellReuseIdentifier: "bookmark-cell")
		self.tableView.rowHeight = UITableViewAutomaticDimension
		self.tableView.estimatedRowHeight = 80

		self.navigationItem.rightBarButtonItem = UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.add, target: self, action: #selector(addBookmark))
		
		welcomeOverlayView.translatesAutoresizingMaskIntoConstraints = false

		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false
		
		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		updateNoServerMessageVisibility()
		
		self.navigationController?.setToolbarHidden(false, animated: false)
		self.toolbarItems = [
			UIBarButtonItem.init(title: "Help", style: UIBarButtonItemStyle.plain, target: self, action: #selector(help)),
			UIBarButtonItem.init(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil),
			UIBarButtonItem.init(title: "Settings", style: UIBarButtonItemStyle.plain, target: self, action: #selector(settings))
		]
	}
	
	func updateNoServerMessageVisibility() {
		if (BookmarkManager.sharedBookmarkManager.bookmarks.count == 0)
		{
			let safeAreaLayoutGuide : UILayoutGuide = self.tableView.safeAreaLayoutGuide
			var constraint : NSLayoutConstraint

			if (welcomeOverlayView.superview != self.view) {
			
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
		}
		else
		{
			if (welcomeOverlayView.superview == self.view)
			{
				welcomeOverlayView.removeFromSuperview()

				tableView.separatorStyle = UITableViewCellSeparatorStyle.singleLine
				tableView.reloadData()
			}
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: - Actions
	@IBAction func addBookmark() {
		let bookmark = OCBookmark.init(for: URL.init(string: "https://demo.owncloud.org"))
	
		BookmarkManager.sharedBookmarkManager.addBookmark(bookmark!)
		
		tableView.reloadData()
		
		updateNoServerMessageVisibility()
	}

	@IBAction func help() {
	}

	@IBAction func settings() {
		let viewController : GlobalSettingsViewController = GlobalSettingsViewController.init(style: UITableViewStyle.grouped)
		
		self.navigationController?.pushViewController(viewController, animated: true)
	}

	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		// #warning Incomplete implementation, return the number of sections
		return 1
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete implementation, return the number of rows
		return BookmarkManager.sharedBookmarkManager.bookmarks.count
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		welcomeOverlayView.layoutSubviews()
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let bookmarkCell : ServerListBookmarkCell = self.tableView.dequeueReusableCell(withIdentifier: "bookmark-cell") as! ServerListBookmarkCell
		let bookmark : OCBookmark = BookmarkManager.sharedBookmarkManager.bookmark(at: indexPath.row)
		
		bookmarkCell.titleLabel.text = bookmark.url.host
		bookmarkCell.detailLabel.text = bookmark.url.absoluteString
		bookmarkCell.imageView?.image = UIImage.init(named: "owncloud-primary-small")
		
		return bookmarkCell
	}
	
	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		return [
				UITableViewRowAction.init(style: UITableViewRowActionStyle.destructive, title: "Delete", handler: { (action, indexPath) in
					let bookmark : OCBookmark

					bookmark = BookmarkManager.sharedBookmarkManager.bookmark(at: indexPath.row)

					BookmarkManager.sharedBookmarkManager.removeBookmark(bookmark)
					
					// TODO: Add confirmation prompt
					
					tableView.performBatchUpdates({
						tableView.deleteRows(at: [indexPath], with: UITableViewRowAnimation.fade)
					}, completion: nil)

					self.updateNoServerMessageVisibility()
				})
			]
	}
}
	
	
	

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

