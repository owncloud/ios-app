//
//  PDFViewerViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 29/08/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK
import PDFKit

class PDFViewerViewController: DisplayViewController, DisplayViewProtocol {
    enum ThumbnailViewPosition {
        case left, right, bottom
        func isVertical() -> Bool {
            return self == .bottom ? false : true
        }
    }

    enum PageLayout : Int {
        case single = 0, continuous = 1, multipage = 2
    }

    fileprivate let ANIMATION_DUR = 0.25
    fileprivate let THUMBNAIL_VIEW_WIDTH_MULTIPLIER: CGFloat = 0.15
    fileprivate let THUMBNAIL_VIEW_HEIGHT_MULTIPLIER: CGFloat = 0.05
    fileprivate let pdfView = PDFView()
    fileprivate let thumbnailView = PDFThumbnailView()
    fileprivate let pageLayoutControl = UISegmentedControl(items: [#imageLiteral(resourceName: "ic_pdf_view_single_page"), #imageLiteral(resourceName: "ic_pdf_view_continuous"), #imageLiteral(resourceName: "ic_pdf_view_multipage")])
    fileprivate var isThumbnailViewVisible = true {
        didSet {
            relayoutAnimated()
        }
    }

    fileprivate var thumbnailViewPosition : ThumbnailViewPosition = .bottom {
        didSet {
            switch thumbnailViewPosition {
            case .left, .right:
                thumbnailView.layoutMode = .vertical
            case .bottom:
                thumbnailView.layoutMode = .horizontal
            }
            relayoutAnimated()
        }
    }

    fileprivate var pageLayout : PageLayout = .single {
        didSet {
            switch pageLayout {
            case .single:
                pdfView.displayDirection = .horizontal
                pdfView.displayDirection = .vertical
                pdfView.displayMode = .singlePage
                //pdfView.usePageViewController(true, withViewOptions: nil)
            case .continuous:
                pdfView.usePageViewController(false, withViewOptions: nil)
                pdfView.displayDirection = .vertical
                pdfView.displayMode = .singlePageContinuous
            case .multipage:
                pdfView.usePageViewController(false, withViewOptions: nil)
                pdfView.displayDirection = .vertical
                pdfView.displayMode = .twoUpContinuous
            }
            self.pdfView.layoutDocumentView()
            self.pdfView.scaleFactor = self.pdfView.scaleFactorForSizeToFit
        }
    }

    fileprivate var activeViewConstraints: [NSLayoutConstraint] = [] {
        willSet {
            NSLayoutConstraint.deactivate(activeViewConstraints)
        }
        didSet {
            NSLayoutConstraint.activate(activeViewConstraints)
        }
    }

    // MARK: - DisplayViewProtocol

    static var supportedMimeTypes: [String] = ["application/pdf"]
    static var features: [String : Any]? = [FeatureKeys.canEdit : true, FeatureKeys.showPDF : true]

    override func renderSpecificView() {
        if let document = PDFDocument(url: source) {
            pdfView.document = document
            self.title = document.documentURL?.lastPathComponent

            setupConstraints()
        }
    }

    // MARK: - View lifecycle management

    override func viewDidLoad() {
        super.viewDidLoad()

        self.thumbnailViewPosition = .bottom

        // Configure thumbnail view
        thumbnailView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.backgroundColor = UIColor.gray
        thumbnailView.pdfView = pdfView
        self.view.addSubview(thumbnailView)

        // Configure PDFView instance
        pdfView.translatesAutoresizingMaskIntoConstraints = false
        pdfView.backgroundColor = UIColor.gray
        self.view.addSubview(pdfView)

        self.pageLayout = .single
        pageLayoutControl.selectedSegmentIndex = 0

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        parent?.navigationController?.hidesBarsOnTap = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        parent?.navigationController?.hidesBarsOnTap = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        setupConstraints()
        setupToolbar()
        pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
    }

    override func viewDidLayoutSubviews() {
        self.thumbnailView.isHidden = self.navigationController!.isNavigationBarHidden
    }

    func save(item: OCItem) {
        editingDelegate?.save(item: item, fileURL: source)
    }

    // MARK: - Toolbar actions

    @objc func goToPage() {

        guard let pdf = pdfView.document else { return }

        let ac = UIAlertController(title: "Go to page", message: "This document has \(pdf.pageCount) pages", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        ac.addTextField(configurationHandler: { textField in
            textField.placeholder = "Page"
            textField.keyboardType = .decimalPad
        })

        ac.addAction(UIAlertAction(title: "OK", style: .default, handler: { [unowned self] _ in
            if let pageLabel = ac.textFields?.first?.text {
                self.selectPage(with: pageLabel)
            }
        }))

        self.present(ac, animated: true)
    }

    @objc func search() {
        guard let pdf = pdfView.document else { return }

        let pdfSearchController = PDFSearchViewController()
        let searchNC = UINavigationController(rootViewController: pdfSearchController)
        pdfSearchController.pdfDocument = pdf
        pdfSearchController.userSelectedMatchCallback = { (selection) in
            DispatchQueue.main.async {
                selection.color = UIColor.yellow
                self.pdfView.setCurrentSelection(selection, animate: true)
                self.pdfView.scrollSelectionToVisible(nil)

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
                    self.pdfView.clearSelection()
                })
            }
        }

        self.present(searchNC, animated: true)
    }

    @objc func changeDisplayMode() {
        let selected = pageLayoutControl.selectedSegmentIndex
        self.pageLayout = PageLayout(rawValue: selected)!
    }

    // MARK: - Private helpers

    fileprivate func adjustThumbnailsSize() {
        let thumbnailSize = min(thumbnailView.frame.size.width, thumbnailView.frame.size.height) - 8.0
        if thumbnailSize > 0 {
            thumbnailView.thumbnailSize = CGSize(width: thumbnailSize, height: thumbnailSize)
        }
    }

    fileprivate func relayoutAnimated() {
        if pdfView.superview == nil {
            return
        }
        setupConstraints()
        UIView.animate(withDuration: ANIMATION_DUR) {
            self.view.layoutIfNeeded()
        }
    }

    fileprivate func setupConstraints() {

        let guide = view.safeAreaLayoutGuide

        var constraints = [NSLayoutConstraint]()
        constraints.append(pdfView.topAnchor.constraint(equalTo: guide.topAnchor))

        switch thumbnailViewPosition {
        case .left:
            constraints.append(thumbnailView.topAnchor.constraint(equalTo: guide.topAnchor))
            constraints.append(thumbnailView.leadingAnchor.constraint(equalTo: guide.leadingAnchor))
            //constraints.append(thumbnailView.trailingAnchor.constraint(equalTo: pdfView.leadingAnchor))
            constraints.append(thumbnailView.bottomAnchor.constraint(equalTo: guide.bottomAnchor))

            if isThumbnailViewVisible {
                constraints.append(thumbnailView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: THUMBNAIL_VIEW_WIDTH_MULTIPLIER))
            } else {
                constraints.append(thumbnailView.widthAnchor.constraint(equalToConstant: 0.0))
            }

            constraints.append(pdfView.leadingAnchor.constraint(equalTo: thumbnailView.trailingAnchor))
            constraints.append(pdfView.trailingAnchor.constraint(equalTo: guide.trailingAnchor))
            constraints.append(pdfView.bottomAnchor.constraint(equalTo: guide.bottomAnchor))

        case .right:
            constraints.append(thumbnailView.topAnchor.constraint(equalTo: guide.topAnchor))
            constraints.append(thumbnailView.leadingAnchor.constraint(equalTo: pdfView.trailingAnchor))
            constraints.append(thumbnailView.trailingAnchor.constraint(equalTo: guide.trailingAnchor))
            constraints.append(thumbnailView.bottomAnchor.constraint(equalTo: guide.bottomAnchor))

            if isThumbnailViewVisible {
                constraints.append(thumbnailView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: THUMBNAIL_VIEW_WIDTH_MULTIPLIER))
            } else {
                constraints.append(thumbnailView.widthAnchor.constraint(equalToConstant: 0.0))
            }

            constraints.append(pdfView.leadingAnchor.constraint(equalTo: guide.leadingAnchor))
            constraints.append(pdfView.trailingAnchor.constraint(equalTo: thumbnailView.leadingAnchor))
            constraints.append(pdfView.bottomAnchor.constraint(equalTo: guide.bottomAnchor))

        case .bottom:
            constraints.append(thumbnailView.topAnchor.constraint(equalTo: pdfView.bottomAnchor))
            constraints.append(thumbnailView.leadingAnchor.constraint(equalTo: guide.leadingAnchor))
            constraints.append(thumbnailView.trailingAnchor.constraint(equalTo: guide.trailingAnchor))
            constraints.append(thumbnailView.bottomAnchor.constraint(equalTo: guide.bottomAnchor))

            if isThumbnailViewVisible {
                constraints.append(thumbnailView.heightAnchor.constraint(equalTo: self.view.heightAnchor, multiplier: THUMBNAIL_VIEW_HEIGHT_MULTIPLIER))
            } else {
                constraints.append(thumbnailView.heightAnchor.constraint(equalToConstant: 0.0))
            }

            constraints.append(pdfView.leadingAnchor.constraint(equalTo: guide.leadingAnchor))
            constraints.append(pdfView.trailingAnchor.constraint(equalTo: guide.trailingAnchor))
            constraints.append(pdfView.bottomAnchor.constraint(equalTo: thumbnailView.topAnchor))
        }

        self.activeViewConstraints = constraints

    }

    fileprivate func setupToolbar() {

        let searchButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(search))
        let gotoButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_pdf_go_to_page"), style: .plain, target: self, action: #selector(goToPage))
        pageLayoutControl.addTarget(self, action: #selector(changeDisplayMode), for: .valueChanged)
        let pageLayoutButtonItem = UIBarButtonItem(customView: pageLayoutControl)

        self.parent?.navigationItem.rightBarButtonItems = [
                             pageLayoutButtonItem,
                             gotoButtonItem,
                             searchButtonItem]
    }

    fileprivate func selectPage(with label:String) {
        guard let pdf = pdfView.document else { return }
        if let pageNr = Int(label) {
            if pageNr > 0 && pageNr < pdf.pageCount {
                if let page = pdf.page(at: pageNr - 1) {
                    self.pdfView.go(to: page)
                }
            }
        }
    }
}
