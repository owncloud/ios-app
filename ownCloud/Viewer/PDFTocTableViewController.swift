//
//  PDFTocTableViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 04.10.2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import PDFKit

class PDFTocTableViewController: UITableViewController {

    class OutlineStackItem {
        var outline:PDFOutline
        var processedChildren:Int = 0

        var childrenCount:Int {
            get {
                return outline.numberOfChildren
            }
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
        self.tableView.register(PDFTocTableViewCell.self, forCellReuseIdentifier: PDFTocTableViewCell.identifier)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: PDFTocTableViewCell.identifier, for: indexPath) as? PDFTocTableViewCell
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

        var currentOutline = fromRoot
        var stack: [OutlineStackItem] = []

        func addTocItemForCurrnetOutline() {
            guard let outlineLabel = currentOutline.label else { return }
            guard !outlineLabel.isEmpty else { return }

            let item = PDFTocItem(level: stack.count, outline: currentOutline)
            if let lastItem = items.last {
                if lastItem != item {
                    items.append(item)
                }
            } else {
                items.append(item)
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

        } while stack.count > 0
    }
}
