//
//  StaticTableViewController.swift
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

enum StaticTableViewEvent {
	case Initial
	case AppBecameActive
	case TableViewWillAppear
	case TableViewWillDisappear
	case TableViewDidDisappear
}

class StaticTableViewController: UITableViewController {
	public var sections : Array<StaticTableViewSection> = Array()

	// MARK: - Section administration
	func addSection(_ section: StaticTableViewSection, animated animateThis: Bool = false) {
		self.insertSection(section, at: sections.count, animated: animateThis)
	}
	
	func insertSection(_ section: StaticTableViewSection, at index: Int, animated: Bool = false) {
		section.viewController = self

		if (animated) {
			tableView.performBatchUpdates({
				sections.insert(section, at: index)
				tableView.insertSections(IndexSet.init(integer: index), with: UITableViewRowAnimation.fade)
			}, completion: { (completed) in

			})
		}
		else
		{
			sections.insert(section, at: index)
			
			tableView.reloadData()
		}
	}

	func removeSection(_ section: StaticTableViewSection, animated: Bool = false) {
		if (animated) {
			tableView.performBatchUpdates({
				if let index : Int = sections.index(of: section)
				{
					sections.remove(at: index)
					tableView.deleteSections(IndexSet.init(integer: index), with: UITableViewRowAnimation.fade)
				}
			}, completion: { (completed) in
				section.viewController = nil
			})
		}
		else
		{
			sections.remove(at: sections.index(of: section)!)

			section.viewController = nil

			tableView.reloadData()
		}
	}

	// MARK: - Search
	func sectionForIdentifier(_ sectionID: String) -> StaticTableViewSection? {
		for section in sections {
			if (section.identifier == sectionID) {
				return section
			}
		}

		return nil
	}

	func rowInSection(_ inSection: StaticTableViewSection?, rowIdentifier: String) -> StaticTableViewRow? {
		if (inSection == nil) {
			for section in sections {
				if let row = section.row(withIdentifier: rowIdentifier) {
					return row
				}
			}
		} else {
			return inSection?.row(withIdentifier: rowIdentifier)
		}

		return nil
	}

	// MARK: - View Controller
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false
		
		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem
	}

	// MARK: - Tools
	func staticRowForIndexPath(_ indexPath: IndexPath) -> StaticTableViewRow {
		return (sections[indexPath.section].rows[indexPath.row])
	}

	// MARK: - Table view data source
	override func numberOfSections(in tableView: UITableView) -> Int {
		// #warning Incomplete implementation, return the number of sections
		return sections.count
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete implementation, return the number of rows
		return sections[section].rows.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		return sections[indexPath.section].rows[indexPath.row].cell!
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let staticRow : StaticTableViewRow = staticRowForIndexPath(indexPath)

		staticRow.action!(staticRow, self)

		tableView.deselectRow(at: indexPath, animated: true)
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return sections[section].headerTitle
	}
	
	override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		return sections[section].footerTitle
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

}
