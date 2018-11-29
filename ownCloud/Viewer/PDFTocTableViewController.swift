//
//  PDFTocTableViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 04.10.2018.
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
import PDFKit

class PDFTocTableViewController: UITableViewController, Themeable {

    let activityIndicatorView: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)

    fileprivate let tocTableViewCellHeight: CGFloat = 40.0
    fileprivate var enableTocBuilding = true

    class OutlineStackItem {
        var outline:PDFOutline
        var processedChildren:Int = 0

        var childrenCount:Int {
            return outline.numberOfChildren
        }

        init(outline:PDFOutline) {
            self.outline = outline
        }

        func nextChild() -> PDFOutline? {
            self.processedChildren += 1
            if self.processedChildren < self.childrenCount {
                return self.outline.child(at: self.processedChildren)
            }
            return nil
        }
    }

    var outlineRoot: PDFOutline?

    fileprivate var tocItems = [PDFTocItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(PDFTocTableViewCell.self, forCellReuseIdentifier: PDFTocTableViewCell.identifier)
        self.tableView.rowHeight = tocTableViewCellHeight
        tableView.backgroundView = activityIndicatorView
        self.tableView.separatorStyle = .none
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Theme.shared.register(client: self)

        enableTocBuilding = true
        if outlineRoot != nil {
            buildTocList(fromRoot: outlineRoot!)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        enableTocBuilding = false
        Theme.shared.unregister(client: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - Themeable support

    func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
        self.tableView.applyThemeCollection(collection)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tocItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PDFTocTableViewCell.identifier, for: indexPath) as? PDFTocTableViewCell
        cell!.setup(with: tocItems[indexPath.row])
        return cell!
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = tocItems[indexPath.row]
        if let pdfPage = item.page {
            self.dismiss(animated: true) {
                NotificationCenter.default.post(name: PDFViewerViewController.PDFGoToPageNotification.name, object: pdfPage)
            }
        }
    }

    // MARK: - Private helper methods

    fileprivate func buildTocList(fromRoot:PDFOutline) {

        var currentOutline = fromRoot
        var stack: [OutlineStackItem] = []

        func addTocItemForCurrnetOutline() {
            guard let outlineLabel = currentOutline.label else { return }

            guard !outlineLabel.isEmpty else { return }

            let item = PDFTocItem(level: stack.count, outline: currentOutline)
            if let lastItem = tocItems.last {
                if lastItem != item {
                    tocItems.append(item)
                }
            } else {
                tocItems.append(item)
            }
        }

        func pushCurrent() {
            addTocItemForCurrnetOutline()
            stack.append(OutlineStackItem(outline: currentOutline))
            if currentOutline.numberOfChildren > 0 {
                currentOutline = currentOutline.child(at: 0)!
            }
        }

        func popLast() {
            if stack.count > 0 {
                stack.removeLast()
            }
        }

        activityIndicatorView.startAnimating()
        DispatchQueue.global(qos: .background).async {
            // Traverse a tree of PDFOutline objects
            repeat {
                let stackTop: OutlineStackItem? = stack.last

                if currentOutline.numberOfChildren > 0 {
                    if let topOutline = stackTop?.outline {
                        if topOutline != currentOutline {
                            pushCurrent()
                        }
                    } else {
                        pushCurrent()
                    }
                } else {
                    // No children -> just add to ToC
                    addTocItemForCurrnetOutline()
                    if stack.count > 0 {
                        // Get the next child at the same level
                        let stackTop = stack.last!
                        let nextChildOutline = stackTop.nextChild()
                        // Nothing to process at current level, go back in the stack
                        if nextChildOutline == nil {
                            popLast()
                        } else {
                            // Switch over to the next sibling
                            currentOutline = nextChildOutline!
                        }
                    }
                }

                if !self.enableTocBuilding {
                    self.tocItems.removeAll()
                    break
                }

            } while stack.count > 0

            DispatchQueue.main.async {
                self.activityIndicatorView.stopAnimating()
                self.tableView.reloadData()
            }
        }
    }
}
