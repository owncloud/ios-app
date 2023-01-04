//
//  EditorSplitViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 29.11.22.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

class EditorSplitViewController: UISplitViewController {

    let editorViewController: EditTextViewController
    let previewViewController: WebViewPreviewViewController

    init(with file: URL, item: OCItem, core: OCCore? = nil) {
        editorViewController = EditTextViewController(with: file, item: item, core: core)
        previewViewController = WebViewPreviewViewController()

        super.init(style: .doubleColumn)

        preferredDisplayMode = .oneBesideSecondary
        primaryBackgroundStyle = .sidebar

       // editorViewController.delegate = self
        //outlineViewController.delegate = self

        let previewBarAppearance = UINavigationBarAppearance()
        previewBarAppearance.backgroundColor = .secondarySystemBackground
        
        let previewNavigationController = UINavigationController(rootViewController: previewViewController)
        previewNavigationController.navigationBar.standardAppearance = previewBarAppearance
        setViewController(previewNavigationController, for: .primary)

        let editorBarAppearance = UINavigationBarAppearance()
        editorBarAppearance.backgroundColor = UIColor {
            if $0.userInterfaceStyle == .light {
                return .white
            } else {
                return UIColor(named: "EditorBackgroundColor")!
            }
        }
        
        editorViewController.navigationItem.standardAppearance = editorBarAppearance
        editorViewController.navigationItem.scrollEdgeAppearance = editorBarAppearance

        let editorNavigationController = UINavigationController(rootViewController: editorViewController)
        setViewController(editorNavigationController, for: .secondary)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func openDocument() async throws {
        /*
        guard document.documentState == .closed else {
            return
        }
        let success = await document.open()
        guard success else {
            throw SplitViewError.documentFailedToOpen
        }
        editorViewController.didOpenDocument()
         */
    }
    /*
    // MARK: EditorViewControllerDelegate
    
    func editor(_ editorViewController: EditorViewController, didParse document: ParsedDocument) {
        outlineViewController.outlineElements = document.outline
    }

    // MARK: OutlineViewControllerDelegate

    func outline(_ outlineView: OutlineViewController, didChoose element: OutlineElement) {
        // If the app is in compact width, this will push the editor, otherwise it will have no effect.
        show(.secondary)
        editorViewController.scroll(to: element)
    }
    
    func outline(_ outlineView: OutlineViewController, didSwapTagsFor elements: [OutlineElement], withTag tag: MarkdownTag) {
        document.swapTags(for: elements, with: tag)
    }
    
    func outline(_ outlineView: OutlineViewController, didDuplicate elements: [OutlineElement]) {
        document.duplicate(elements)
    }
    
    func outline(_ outlineView: OutlineViewController, didDelete elements: [OutlineElement]) {
        document.delete(elements)
    }*/
}

extension EditorSplitViewController {
    enum SplitViewError: Error {
        case renamingUnavailable
        case documentFailedToOpen
    }
}

