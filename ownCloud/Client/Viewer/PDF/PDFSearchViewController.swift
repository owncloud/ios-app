//
//  PDFSerachViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 12.09.2018.
//  Copyright © 2018 ownCloud. All rights reserved.
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
import PDFKit
import ownCloudAppShared

class PDFSearchViewController: UITableViewController, PDFDocumentDelegate, Themeable, UISearchBarDelegate {

    typealias PDFSearchMatchSelectedCallback = ([PDFSelection], PDFSelection) -> Void

    fileprivate var searchController: UISearchController?

    var pdfDocument: PDFDocument?

    var userSelectedMatchCallback : PDFSearchMatchSelectedCallback?

    fileprivate var selection: PDFSelection?
    fileprivate var matches = [PDFSelection]()
    fileprivate var searchText = ""
    fileprivate var typeDelayTimer : Timer?
    fileprivate let typingDelay = 0.2
    fileprivate let searchTableViewCellHeight: CGFloat = 40.0

    override func viewDidLoad() {
        super.viewDidLoad()
        self.definesPresentationContext = true

        self.tableView.register(PDFSearchTableViewCell.self, forCellReuseIdentifier: PDFSearchTableViewCell.identifier)
        self.tableView.rowHeight = searchTableViewCellHeight

        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        searchController?.obscuresBackgroundDuringPresentation = false
        searchController?.hidesNavigationBarDuringPresentation = true

        searchController?.searchBar.delegate = self

        navigationItem.searchController =  searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        NotificationCenter.default.addObserver(self, selector: #selector(handleDidFindMatch),
                                               name: .PDFDocumentDidFindMatch,
                                               object: nil)

        Theme.shared.register(client: self, applyImmediately: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.searchController?.searchBar.becomeFirstResponder()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cancelSearch()
    }

    deinit {
        Theme.shared.unregister(client: self)
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func dismissSearch() {
        typeDelayTimer?.invalidate()
        self.dismiss(animated: true) {
            if self.userSelectedMatchCallback != nil && self.selection != nil {
				self.userSelectedMatchCallback!(self.matches, self.selection!)
            }
        }
    }

    // MARK: - USearchBarDelegate

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        dismissSearch()
    }

    // MARK: - Theme support

    func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
        self.tableView.applyThemeCollection(collection)
        self.searchController?.searchBar.applyThemeCollection(collection)

        if event == .update {
            self.tableView.reloadData()
        }
    }

    // MARK: - Table view data source / delegate

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matches.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PDFSearchTableViewCell.identifier, for: indexPath) as? PDFSearchTableViewCell

        let pdfSelection = matches[indexPath.row]
        cell?.setup(with: pdfSelection)

        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        cancelSearch()
        searchController?.isActive = false
        tableView.deselectRow(at: indexPath, animated: true)
        self.selection = self.matches[indexPath.row]
        self.dismissSearch()
    }

    @objc func handleDidFindMatch(notification: NSNotification) {
        if let selection = notification.userInfo?["PDFDocumentFoundSelection"] as? PDFSelection {
            // Add new match to the list and update table view
            self.matches.append(selection)
            let indexPath = IndexPath(row: (self.matches.count - 1), section: 0)
            self.tableView.insertRows(at: [indexPath], with: .automatic)
        }
    }

    // MARK: - Private helpers

    fileprivate func cancelSearch() {
        guard let pdfDocument = pdfDocument else { return }

        if pdfDocument.isFinding {
            pdfDocument.cancelFindString()
        }
    }

    fileprivate func beginSearch() {
        guard let pdfDocument = pdfDocument else { return }

        // Remove data from previous search
        if self.matches.count > 0 {
            self.matches.removeAll()
            self.tableView.reloadData()
        }

        // Cancel eventually pending search
        cancelSearch()
        // Begin a new search
        pdfDocument.beginFindString(self.searchText,
                            withOptions: [.caseInsensitive, .diacriticInsensitive])
    }

}

// MARK: - UISearchResultsUpdating Delegate

extension PDFSearchViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text!
        // Don't start the search immediately but rather wait for a short time since user might continue typing
        typeDelayTimer?.invalidate()
        typeDelayTimer = Timer.scheduledTimer(withTimeInterval: typingDelay, repeats: false, block: {  [unowned self] _ in
            self.beginSearch()
        })
    }
}
