//
//  PDFOutlineViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 04.10.2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import PDFKit

class PDFOutlineViewController: UIViewController, Themeable {

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
        modeSegmentedControl = UISegmentedControl(items: ["ToC", "Thumbnails"])
        modeSegmentedControl?.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        self.navigationItem.titleView = modeSegmentedControl
        let resumeItem = UIBarButtonItem(title: "Resume", style: .plain, target: self, action: #selector(resume))
        self.navigationItem.rightBarButtonItem = resumeItem
        Theme.shared.register(client: self, applyImmediately: true)

        self.mode = .ToC
    }

    deinit {
        Theme.shared.unregister(client: self)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Theme support

    func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
        self.themeCollection = collection
        if self.childViewControllers.count > 0 {
            if let themeableVC = self.childViewControllers.first as? Themeable {
                themeableVC.applyThemeCollection(theme: theme, collection: collection, event: event)
            }
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

        var fromVC: UIViewController?
        var toVC: UIViewController?

        if self.childViewControllers.count > 0 {
            fromVC = self.childViewControllers.first
        }
        if mode == .ToC {
            let tocVC = PDFTocTableViewController()
            tocVC.outlineRoot = self.pdfDocument?.outlineRoot
            tocVC.themeCollection = self.themeCollection
            toVC = tocVC
        } else {
            let thumbnaisVC = PDFThumbnailsCollectionViewController()
            thumbnaisVC.pdfDocument = self.pdfDocument
            thumbnaisVC.themeCollection = self.themeCollection
            toVC = thumbnaisVC
        }

        change(fromViewController: fromVC, toViewController: toVC!)
    }

    fileprivate func change(fromViewController:UIViewController?, toViewController:UIViewController) {
        fromViewController?.willMove(toParentViewController: nil)
        self.addChildViewController(toViewController)
        toViewController.view.frame = self.view.frame
        self.view.addSubview(toViewController.view)

        if fromViewController != nil {
            toViewController.view.alpha = 0.0

            UIView.animate(withDuration: 0.25, animations: {
                fromViewController!.view.alpha = 0.0
                toViewController.view.alpha = 1.0
            }, completion: { (_) in
                fromViewController?.view.removeFromSuperview()
                fromViewController?.removeFromParentViewController()
                toViewController.didMove(toParentViewController: self)
            })
        } else {
            toViewController.didMove(toParentViewController: self)
        }
    }
}
