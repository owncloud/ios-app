//
//  PDFTocTableViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 04.10.2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import PDFKit

class PDFTocItem {
    var label: String?
    var level: Int
    var page: PDFPage?

    init(level:Int, outline:PDFOutline) {
        self.level = level
        self.label = outline.label
        self.page = outline.destination?.page
    }
}

extension PDFSearchTableViewCell {
    func setup(with tocItem:PDFTocItem) {
        self.titleLabel.text = tocItem.label
        if let page = tocItem.page {
            self.pageLabel.text = page.label
        }
        self.indentationLevel = tocItem.level
        // TODO: Use different fonts for different levels
    }
}

class PDFTocTableViewController: UITableViewController {

    var outlineRoot: PDFOutline? {
        didSet {
            if outlineRoot != nil {
                setupTocList(fromRoot: outlineRoot!)
            }
        }
    }

    var themeCollection: ThemeCollection?

    fileprivate var items = [PDFTocItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(PDFSearchTableViewCell.self, forCellReuseIdentifier: PDFSearchTableViewCell.identifier)
        self.tableView.rowHeight = 40.0
        self.tableView.separatorStyle = .none
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.themeCollection != nil {
            self.tableView.applyThemeCollection(self.themeCollection!)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PDFSearchTableViewCell.identifier, for: indexPath) as? PDFSearchTableViewCell
        cell!.setup(with: items[indexPath.row])
        return cell!
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        if let pdfPage = item.page {
            self.dismiss(animated: true) {
                NotificationCenter.default.post(name: PDFViewerViewController.PDFGoToPageNotification.name, object: pdfPage)
            }
        }
    }

    // MARK: - Private helper methods

    fileprivate func setupTocList(fromRoot:PDFOutline) {
        // TODO: traverse a complete tree
        for index in 0..<fromRoot.numberOfChildren {
            let child = fromRoot.child(at: index)
            if child?.destination?.page != nil {
                let item = PDFTocItem(level: 0, outline: child!)
                items.append(item)
            }
        }
    }
}
