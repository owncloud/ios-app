//
//  PDFSerachViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 12.09.2018.
//  Copyright © 2018 ownCloud. All rights reserved.
//

import UIKit
import PDFKit

class PDFSearchViewController: UITableViewController, PDFDocumentDelegate, Themeable {

    typealias PDFSearchMatchSelectedCallback = (PDFSelection) -> Void

    fileprivate var searchController: UISearchController?

    var pdfDocument: PDFDocument?

    var userSelectedMatchCallback : PDFSearchMatchSelectedCallback?

    fileprivate var matches = [PDFSelection]()
    fileprivate var searchText = ""
    fileprivate var typeDelayTimer : Timer?
    fileprivate let typingDelay = 0.2
    fileprivate let searchTableViewCellHeight: CGFloat = 40.0

    fileprivate let activityView = UIActivityIndicatorView(activityIndicatorStyle: .gray)

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.register(PDFSearchTableViewCell.self, forCellReuseIdentifier: PDFSearchTableViewCell.identifier)
        self.tableView.rowHeight = searchTableViewCellHeight

        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        searchController?.obscuresBackgroundDuringPresentation = false
        searchController?.hidesNavigationBarDuringPresentation = true

        navigationItem.searchController =  searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        NotificationCenter.default.addObserver(self, selector: #selector(handleDidBeginFind),
                                               name: .PDFDocumentDidBeginFind,
                                               object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(handleDidEndFind),
                                               name: .PDFDocumentDidEndFind,
                                               object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(handleDidFindMatch),
                                               name: .PDFDocumentDidFindMatch,
                                               object: nil)

        activityView.sizeToFit()
        activityView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        activityView.hidesWhenStopped = true

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissSearch))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: activityView)

        Theme.shared.register(client: self, applyImmediately: true)
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
        self.presentingViewController?.dismiss(animated: true, completion: nil)
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
        tableView.deselectRow(at: indexPath, animated: true)
        let selection = self.matches[indexPath.row]
        dismissSearch()
        if self.userSelectedMatchCallback != nil {
            userSelectedMatchCallback!(selection)
        }
    }

    // MARK: - Norification observers
    @objc func handleDidBeginFind(notification: NSNotification) {
        // TODO: Start displaying progress
        activityView.startAnimating()
    }

    @objc func handleDidEndFind(notification: NSNotification) {
        // TODO: End displaying progress
        activityView.stopAnimating()
    }

    @objc func handleDidFindMatch(notification: NSNotification) {
        if let selection = notification.userInfo?["PDFDocumentFoundSelection"] as? PDFSelection {
            // Add new match to the list and update table view
            self.matches.append(selection)
            let indexPath = IndexPath(row: (self.matches.count - 1), section: 0)
            self.tableView.insertRows(at: [indexPath], with: .bottom)
        }
    }

    // MARK: - Private helpers

    fileprivate func cancelSearch() {
        guard let pdf = pdfDocument else { return }

        if pdf.isFinding {
            pdf.cancelFindString()
        }
    }

    fileprivate func beginSearch() {
        guard let pdf = pdfDocument else { return }

        // Remove data from previous search
        self.matches.removeAll()
        self.tableView.reloadData()
        // Cancel eventually pending search
        cancelSearch()
        // Begin a new search
        pdf.beginFindString(self.searchText,
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
