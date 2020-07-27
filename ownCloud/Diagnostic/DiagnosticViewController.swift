//
//  DiagnosticViewController.swift
//  ownCloud
//
//  Created by Felix Schwarz on 27.07.20.
//  Copyright © 2020 ownCloud GmbH. All rights reserved.
//

/*
 * Copyright (C) 2020, ownCloud GmbH.
 *
 * This code is covered by the GNU Public License Version 3.
 *
 * For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
 * You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
 *
 */

import UIKit
import ownCloudSDK

class DiagnosticViewController: StaticTableViewController {

	var context : OCDiagnosticContext?

	var rootNode : OCDiagnosticNode?
	var nodes : [OCDiagnosticNode]? {
		didSet {
			rebuildTable()
		}
	}

	init(for node: OCDiagnosticNode, context: OCDiagnosticContext?) {
		self.context = context

		super.init(style: .grouped)

		self.rootNode = node

		self.navigationItem.title = node.label
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "open-in"), style: .plain, target: self, action: #selector(self.shareAsMarkdown(_:)))
		self.nodes = node.children

		rebuildTable()
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	private var section : StaticTableViewSection?
	private var newSections : [StaticTableViewSection]?

	private func add(nodes: [OCDiagnosticNode]) {
		for node in nodes {
			if node.isEmpty { continue }

			switch node.type {
				case .info:
					if let length = node.content?.count, length < 20 {
						section?.add(row: StaticTableViewRow(valueRowWithAction: nil, title: node.label ?? "", value: node.content ?? ""))
					} else {
						section?.add(row: StaticTableViewRow(rowWithAction: nil, title: node.label ?? "", subtitle: node.content))
					}

				case .action:
					section?.add(row: StaticTableViewRow(buttonWithAction: { (_, _) in
						node.action?()
					}, title: node.label ?? ""))

				case .group:
					if let children = node.children {
						section = StaticTableViewSection(headerTitle: node.label)
						newSections?.append(section!)

						add(nodes: children)
					}
			}
		}
	}

	func rebuildTable() {
		newSections = []

		if let nodes = nodes {
			section = StaticTableViewSection(headerTitle: nil)
			newSections?.append(section!)

			add(nodes: nodes)
		}

		self.sections = newSections ?? []
	}

	@objc func shareAsMarkdown(_ sender: UIView) {
		if let markdown = self.rootNode?.composeMarkdown() {
			let shareViewController = UIActivityViewController(activityItems: [markdown], applicationActivities:nil)
			shareViewController.completionWithItemsHandler = { (_, _, _, _) in
			}

			if UIDevice.current.isIpad() {
				shareViewController.popoverPresentationController?.sourceView = sender
				shareViewController.popoverPresentationController?.sourceRect = sender.frame
			}
			self.present(shareViewController, animated: true, completion: nil)

			Log.debug("\(markdown)")
		}
	}
}
