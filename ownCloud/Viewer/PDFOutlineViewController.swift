//
//  PDFOutlineViewController.swift
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

class PDFOutlineViewController: UIViewController {

    enum Mode : Int {
        case ToC, Thumbnails
    }

    var pdfDocument: PDFDocument?
    var themeCollection: ThemeCollection?

    var mode: Mode = .ToC {
        didSet {
            if let control = modeSegmentedControl {
                control.selectedSegmentIndex = mode.rawValue
            }
            setupChildController(forMode: mode)
        }
    }

    var modeSegmentedControl: UISegmentedControl?

    override func viewDidLoad() {
        super.viewDidLoad()
        var iconArray: [UIImage] = [UIImage]()
        if self.pdfDocument?.outlineRoot != nil {
            iconArray.append( UIImage(named: "ic_pdf_outline")!)
        }
        iconArray.append(UIImage(named: "ic_pdf_view_multipage")!)

        modeSegmentedControl = UISegmentedControl(items: iconArray)
        if self.pdfDocument?.outlineRoot != nil {
            modeSegmentedControl?.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
            self.mode = .ToC
        } else {
            self.mode = .Thumbnails
        }
        self.navigationItem.titleView = modeSegmentedControl

        if UIDevice.current.userInterfaceIdiom != .pad {
            let resumeItem = UIBarButtonItem(title: "Resume".localized, style: .plain, target: self, action: #selector(resume))
            self.navigationItem.rightBarButtonItem = resumeItem
        }
    }

    // MARK: - User actions

    @objc func resume() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func modeChanged() {
        if let newMode = Mode(rawValue: modeSegmentedControl!.selectedSegmentIndex) {
            self.mode = newMode
        }
    }

    // MARK: - Private helper methods

    fileprivate func setupChildController(forMode mode:Mode) {

        var fromViewController: UIViewController?
        var toViewController: UIViewController?

        if self.children.count > 0 {
            fromViewController = self.children.first
        }
        if mode == .ToC {
            let tocViewController = PDFTocTableViewController()
            tocViewController.outlineRoot = self.pdfDocument?.outlineRoot
            toViewController = tocViewController
        } else {
            let thumbnaisViewController = PDFThumbnailsCollectionViewController()
            thumbnaisViewController.pdfDocument = self.pdfDocument
            toViewController = thumbnaisViewController
        }

        change(fromViewController: fromViewController, toViewController: toViewController!)
    }

    fileprivate func change(fromViewController:UIViewController?, toViewController:UIViewController) {
        fromViewController?.willMove(toParent: nil)
        self.addChild(toViewController)
        toViewController.view.frame = self.view.frame
        self.view.addSubview(toViewController.view)

        if fromViewController != nil {
            toViewController.view.alpha = 0.0

            UIView.animate(withDuration: 0.25, animations: {
                fromViewController!.view.alpha = 0.0
                toViewController.view.alpha = 1.0
            }, completion: { (_) in
                fromViewController?.view.removeFromSuperview()
                fromViewController?.removeFromParent()
                toViewController.didMove(toParent: self)
            })
        } else {
            toViewController.didMove(toParent: self)
        }
    }
}
