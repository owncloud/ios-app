//
//  EditDocumentViewController.swift
//  ownCloud
//
//  Created by Matthias Hühne on 22.01.20.
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
import ownCloudAppShared
import QuickLook
import Runestone

extension String.Encoding {
    
    func printEncoding() {
        switch self {
        case .utf8:
            print("--> utf 8")
        case .ascii:
            print("--> ascii")
        case .isoLatin1:
            print("--> iso latin 1")
        case .isoLatin2:
            print("--> iso latin 2")
        default:
            print("--> unknown")
        }
    }
}

extension Data {
    var stringEncoding: String.Encoding? {
        var nsString: NSString?
        guard case let rawValue = NSString.stringEncoding(for: self, encodingOptions: nil, convertedString: &nsString, usedLossyConversion: nil), rawValue != 0 else { return nil }
        return .init(rawValue: rawValue)
    }
}

class EditTextViewController: UIViewController, TextViewDelegate, Themeable {
    
    enum SavingMode {
        case createCopy, updateContents, discard
    }

	weak var core: OCCore?
	var item: OCItem
	var savingMode: SavingMode?
	var itemTracker: OCCoreItemTracking?
	var dismissedViewWithoutSaving: Bool = false
	var source: URL
    let textView = TextView()
    var contentDidChanged: Bool = false
    var usedEncoding: String.Encoding = .utf8

	init(with file: URL, item: OCItem, core: OCCore? = nil) {
		self.source = file
		self.core = core
		self.item = item

		super.init(nibName: nil, bundle: nil)

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissAnimated))
        self.makeGlobalMenu()
        
        if #available(iOS 16, *) {
            textView.isFindInteractionEnabled = true
        }

		Theme.shared.register(client: self, applyImmediately: true)

		if let core = core, let location = item.location {
			itemTracker = core.trackItem(at: location, trackingHandler: { [weak self, weak core](error, item, _) in
				if let item = item, let self = self {
					var refreshPreview = false

					if let core = core {
						if item.contentDifferent(than: self.item, in: core) {
							refreshPreview = true
						}
					}

					self.item = item

					if refreshPreview {
						OnMainThread {
							//self.reloadData()
                            // Reading it back from the file
                            var inString = ""
                            do {
                                inString = try String(contentsOf: self.source)
                                self.textView.text = inString
                            } catch {
                                assertionFailure("Failed reading from URL: \(self.source), Error: " + error.localizedDescription)
                            }
                            print("Read from the file: \(inString)")
						}
					}
				} else if item == nil {

					OnMainThread {
						let alertController = ThemedAlertController(title: "File no longer exists".localized,
																	message: nil,
																	preferredStyle: .alert)

						alertController.addAction(UIAlertAction(title: "OK".localized, style: .default, handler: { (_) in
							self?.dismiss(animated: true, completion: nil)
						}))

						self?.present(alertController, animated: true, completion: nil)
					}

				} else if let error = error {
					OnMainThread {
						self?.present(error: error, title: "Saving edited file failed".localized)
					}
				}
			})
		}
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		Theme.shared.unregister(client: self)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.editorDelegate = self
        
        setCustomization(on: textView)
        view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let appTheme = Theme.shared.activeCollection
        textView.backgroundColor = appTheme.tableBackgroundColor
        
        self.title = source.lastPathComponent
        
        do {
            let data = try Data(contentsOf: self.source)
            
            if let stringEncoding = data.stringEncoding, let string = String(data: data, encoding: stringEncoding) {
                let appTheme = Theme.shared.activeCollection
                
                let theme = RegularTheme(textColor: appTheme.tableRowColors.labelColor, gutterBackgroundColor: appTheme.tableBackgroundColor, gutterHairlineColor: appTheme.tableRowColors.labelColor, lineNumberColor: appTheme.tintColor, selectedLineBackgroundColor: .gray, selectedLinesLineNumberColor: .purple, selectedLinesGutterBackgroundColor: .red, invisibleCharactersColor: appTheme.tintColor, pageGuideHairlineColor: .darkText, pageGuideBackgroundColor: .lightText, markedTextBackgroundColor: .magenta)
                let state = TextViewState(text: string, theme: theme)
                DispatchQueue.main.async {
                    self.textView.setState(state)
                }
                
                stringEncoding.printEncoding()
            }
           // inString = try String(contentsOf: self.source, usedEncoding: &usedEncoding)
           // usedEncoding.printEncoding()
            
        } catch {
            assertionFailure("Failed reading from URL: \(self.source), Error: " + error.localizedDescription)
        }
	}
    
    private func setCustomization(on textView: TextView) {
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        textView.lineHeightMultiplier = 1.2
        textView.kern = 0.3
        textView.autocorrectionType = .no
        textView.isLineWrappingEnabled = false
        textView.showLineNumbers = true
        textView.showSpaces = false
        textView.showNonBreakingSpaces = false
        textView.showTabs = false
        textView.showLineBreaks = false
        textView.showSoftLineBreaks = false
    }

	@objc func dismissAnimated() {
        if contentDidChanged == false {
            self.dismiss(animated: true)
        } else {
            if savingMode == nil {
                requestsavingMode { (savingMode) in
                    self.dismiss(animated: true) {
                        if let savingMode = self.savingMode {
                            self.saveModifiedContents(at: self.source, savingMode: savingMode)
                        } else {
                            self.dismissedViewWithoutSaving = true
                        }
                    }
                }
            } else {
                self.dismiss(animated: true) {
                    if let savingMode = self.savingMode {
                        self.saveModifiedContents(at: self.source, savingMode: savingMode)
                    } else {
                        self.dismissedViewWithoutSaving = true
                    }
                }
            }
        }
	}
    
    func makeGlobalMenu() {
        var menuItems : [UIMenuElement] = []
        
        let findAction : UIAction = .init(title: "Find".localized, image: UIImage(systemName: "magnifyingglass"), identifier: nil, discoverabilityTitle: nil, attributes: .init(), handler: { (action) in
            if #available(iOS 16, *) {
                self.textView.findInteraction?.presentFindNavigator(showingReplace: false)
            } else {
                // Fallback on earlier versions
            }
        })
        menuItems.append(findAction)
        
        let findReplaceAction : UIAction = .init(title: "Find and Replace".localized, image: UIImage(systemName: "text.magnifyingglass"), identifier: nil, discoverabilityTitle: nil, attributes: .init(), handler: { (action) in
            if #available(iOS 16, *) {
                self.textView.findInteraction?.presentFindNavigator(showingReplace: true)
            } else {
                // Fallback on earlier versions
            }
        })
        menuItems.append(findReplaceAction)
        
        let previewAction : UIAction = .init(title: "Preview".localized, image: UIImage(systemName: "eye.square"), identifier: nil, discoverabilityTitle: nil, attributes: .init(), handler: { (action) in

            guard let mimeType = self.item.mimeType else { return }
            
            let newViewController = WebViewPreviewViewController()
            newViewController.html = self.textView.text
            newViewController.mimeType = mimeType
            
            self.navigationController?.pushViewController(newViewController, animated: false)
        })
        menuItems.append(previewAction)
        
            var submenuItems : [UIMenuElement] = []
        
        let regularFontSizeAction : UIAction = .init(title: "Regular".localized, identifier: nil, discoverabilityTitle: nil, attributes: .init(), handler: { (action) in
            
            
            let appTheme = Theme.shared.activeCollection
            
            let theme = RegularTheme(textColor: appTheme.tableRowColors.labelColor, gutterBackgroundColor: appTheme.tintColor, gutterHairlineColor: .green, lineNumberColor: appTheme.tableRowColors.labelColor, selectedLineBackgroundColor: .gray, selectedLinesLineNumberColor: .purple, selectedLinesGutterBackgroundColor: .red, invisibleCharactersColor: appTheme.tintColor, pageGuideHairlineColor: .darkText, pageGuideBackgroundColor: .lightText, markedTextBackgroundColor: .magenta)
            let state = TextViewState(text: self.textView.text, theme: theme)
            DispatchQueue.main.async {
                self.textView.setState(state)
            }
        })
        submenuItems.append(regularFontSizeAction)
        
        let mediumFontSizeAction : UIAction = .init(title: "Medium".localized, identifier: nil, discoverabilityTitle: nil, attributes: .init(), handler: { (action) in
            
            let appTheme = Theme.shared.activeCollection
            
            let theme = MediumTheme(textColor: appTheme.tableRowColors.labelColor, gutterBackgroundColor: .red, gutterHairlineColor: .green, lineNumberColor: .blue, selectedLineBackgroundColor: .gray, selectedLinesLineNumberColor: .purple, selectedLinesGutterBackgroundColor: .red, invisibleCharactersColor: .brown, pageGuideHairlineColor: .darkText, pageGuideBackgroundColor: .lightText, markedTextBackgroundColor: .magenta)
            
            let state = TextViewState(text: self.textView.text, theme: theme)
            DispatchQueue.main.async {
                self.textView.setState(state)
            }
        })
        submenuItems.append(mediumFontSizeAction)
        
        let largeFontSizeAction : UIAction = .init(title: "Large".localized, identifier: nil, discoverabilityTitle: nil, attributes: .init(), handler: { (action) in
            let appTheme = Theme.shared.activeCollection
            
            let theme = LargeTheme(textColor: appTheme.tableRowColors.labelColor, gutterBackgroundColor: .red, gutterHairlineColor: .green, lineNumberColor: .blue, selectedLineBackgroundColor: .gray, selectedLinesLineNumberColor: .purple, selectedLinesGutterBackgroundColor: .red, invisibleCharactersColor: .brown, pageGuideHairlineColor: .darkText, pageGuideBackgroundColor: .lightText, markedTextBackgroundColor: .magenta)
            
            let state = TextViewState(text: self.textView.text, theme: theme)
            DispatchQueue.main.async {
                self.textView.setState(state)
            }
        })
        submenuItems.append(largeFontSizeAction)
        
        let subMenu = UIMenu(title: "Font Size".localized, image: UIImage(systemName: "textformat.size"), identifier: UIMenu.Identifier("submenu"), options: [], children: submenuItems)
        menuItems.append(subMenu)
        
        
        let lineNumbersAction : UIAction = .init(title: "Line Numbers".localized, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: self.textView.showLineNumbers ? .off : .on, handler: { (action) in
            self.textView.showLineNumbers.toggle()
        })
        menuItems.append(lineNumbersAction)
        
        
        let unvisibleCharactersAction : UIAction = .init(title: "Invisible Characters".localized, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: self.textView.showSpaces ? .off : .on, handler: { (action) in
            self.textView.showSpaces.toggle()
            self.textView.showNonBreakingSpaces.toggle()
            self.textView.showTabs.toggle()
            self.textView.showLineBreaks.toggle()
            self.textView.showSoftLineBreaks.toggle()
        })
        menuItems.append(unvisibleCharactersAction)
        
        let menu = UIMenu(title: "",  children: menuItems)
#if !targetEnvironment(macCatalyst)
            if #available(iOS 16.0, *) {
                menu.preferredElementSize = .medium
            }
#endif
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: nil, image: UIImage(systemName: "ellipsis.circle"), primaryAction: nil, menu: menu)
    }
    

    private func createDisplayViewController(for mimeType: String) -> (DisplayViewController) {
        let locationIdentifier = OCExtensionLocationIdentifier(rawValue: mimeType)
        let location: OCExtensionLocation = OCExtensionLocation(ofType: .viewer, identifier: locationIdentifier)
        let context = OCExtensionContext(location: location, requirements: nil, preferences: nil)

        var extensions: [OCExtensionMatch]?

        do {
            try extensions = OCExtensionManager.shared.provideExtensions(for: context)
        } catch {
            return DisplayViewController()
        }

        guard let matchedExtensions = extensions else {
            return DisplayViewController()
        }

        guard matchedExtensions.count > 0 else {
            return DisplayViewController()
        }

        let preferredExtension: OCExtension = matchedExtensions[0].extension

        guard let displayViewController = preferredExtension.provideObject(for: context) as? (DisplayViewController & DisplayExtension) else {
            return DisplayViewController()
        }

        return displayViewController
    }

	func requestsavingMode(completion: ((SavingMode) -> Void)? = nil) {
		let alertController = ThemedAlertController(title: "Save File".localized,
													message: nil,
													preferredStyle: .alert)

		if item.permissions.contains(.writable) {
			alertController.addAction(UIAlertAction(title: "Overwrite original".localized, style: .default, handler: { (_) in
				self.savingMode = .updateContents

				completion?(.updateContents)
			}))
		}
		if let core = core, item.parentItem(from: core)?.permissions.contains(.createFile) == true {
			alertController.addAction(UIAlertAction(title: "Save as copy".localized, style: .default, handler: { (_) in
				self.savingMode = .createCopy

				completion?(.createCopy)
			}))
		}

		alertController.addAction(UIAlertAction(title: "Discard changes".localized, style: .destructive, handler: { (_) in
			self.savingMode = .discard

			completion?(.discard)
		}))

		self.present(alertController, animated: true, completion: nil)
	}

	func saveModifiedContents(at url: URL, savingMode: SavingMode) {
        do {
            let dir = try? FileManager.default.url(for: .documentDirectory,
                  in: .userDomainMask, appropriateFor: nil, create: true)
            
            guard let fileURL = dir?.appendingPathComponent(source.lastPathComponent), let core = core, let parentItem = item.parentItem(from: core) else {
                fatalError("Not able to create URL")
            }
            
            try textView.text.write(to: fileURL, atomically: true, encoding: .utf8)
            
            switch savingMode {
            case .createCopy:
                self.core?.importFileNamed(item.name, at: parentItem, from: fileURL, isSecurityScoped: true, options: [ .automaticConflictResolutionNameStyle : OCCoreDuplicateNameStyle.bracketed.rawValue, OCCoreOption.importByCopying : true], placeholderCompletionHandler: { (error, _) in
                    if let error = error {
                        self.present(error: error, title: "Saving edited file failed".localized)
                    }
                }, resultHandler: nil)
            case .updateContents:
                core.reportLocalModification(of: item, parentItem: parentItem, withContentsOfFileAt: fileURL, isSecurityScoped: true, options: [OCCoreOption.importByCopying : true], placeholderCompletionHandler: { (error, _) in
                    if let error = error {
                        self.present(error: error, title: "Saving edited file failed".localized)
                    }
                }, resultHandler: nil)
            default:
                break
            }
        } catch {
            assertionFailure("Failed writing to URL, Error: " + error.localizedDescription)
        }
    }

	func present(error: Error, title: String) {
		var presentationStyle: UIAlertController.Style = .actionSheet
		if UIDevice.current.isIpad {
			presentationStyle = .alert
		}

		let alertController = ThemedAlertController(title: title,
													message: error.localizedDescription,
													preferredStyle: presentationStyle)

		alertController.addAction(UIAlertAction(title: "OK".localized, style: .cancel, handler: nil))

		self.present(alertController, animated: true, completion: nil)
	}

    func applyThemeCollection(theme: ownCloudAppShared.Theme, collection: ThemeCollection, event: ThemeEvent) {
        let runestoneTheme = RegularTheme(textColor: collection.tableRowColors.labelColor, gutterBackgroundColor: collection.tableBackgroundColor, gutterHairlineColor: collection.tableRowColors.labelColor, lineNumberColor: collection.tintColor, selectedLineBackgroundColor: .gray, selectedLinesLineNumberColor: .purple, selectedLinesGutterBackgroundColor: .red, invisibleCharactersColor: collection.tintColor, pageGuideHairlineColor: .darkText, pageGuideBackgroundColor: .lightText, markedTextBackgroundColor: .magenta)
        let state = TextViewState(text: self.textView.text, theme: runestoneTheme)
        DispatchQueue.main.async {
            self.textView.setState(state)
            self.textView.backgroundColor = collection.tableBackgroundColor
        }
	}
    
    func textViewDidChange(_ textView: Runestone.TextView) {
        contentDidChanged = true
    }
}


class RegularTheme: Runestone.Theme {
    var textColor: UIColor
    
    var gutterBackgroundColor: UIColor
    
    var gutterHairlineColor: UIColor
    
    var lineNumberColor: UIColor
    
    var lineNumberFont: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular)
    
    var selectedLineBackgroundColor: UIColor
    
    var selectedLinesLineNumberColor: UIColor
    
    var selectedLinesGutterBackgroundColor: UIColor
    
    var invisibleCharactersColor: UIColor
    
    var pageGuideHairlineColor: UIColor
    
    var pageGuideBackgroundColor: UIColor
    
    var markedTextBackgroundColor: UIColor
    
    func textColor(for highlightName: String) -> UIColor? {
        return nil
    }
    
    let font: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular)
    
    init(textColor: UIColor, gutterBackgroundColor: UIColor, gutterHairlineColor: UIColor, lineNumberColor: UIColor, selectedLineBackgroundColor: UIColor, selectedLinesLineNumberColor: UIColor, selectedLinesGutterBackgroundColor: UIColor, invisibleCharactersColor: UIColor, pageGuideHairlineColor: UIColor, pageGuideBackgroundColor: UIColor, markedTextBackgroundColor: UIColor) {
        self.textColor = textColor
        self.gutterBackgroundColor = gutterBackgroundColor
        self.gutterHairlineColor = gutterHairlineColor
        self.lineNumberColor = lineNumberColor
        self.selectedLineBackgroundColor = selectedLineBackgroundColor
        self.selectedLinesLineNumberColor = selectedLinesLineNumberColor
        self.selectedLinesGutterBackgroundColor = selectedLinesGutterBackgroundColor
        self.invisibleCharactersColor = invisibleCharactersColor
        self.pageGuideHairlineColor = pageGuideHairlineColor
        self.pageGuideBackgroundColor = pageGuideBackgroundColor
        self.markedTextBackgroundColor = markedTextBackgroundColor
    }
}

class MediumTheme: Runestone.Theme {
    var textColor: UIColor
    
    var gutterBackgroundColor: UIColor
    
    var gutterHairlineColor: UIColor
    
    var lineNumberColor: UIColor
    
    var lineNumberFont: UIFont = .monospacedSystemFont(ofSize: 17, weight: .regular)
    
    var selectedLineBackgroundColor: UIColor
    
    var selectedLinesLineNumberColor: UIColor
    
    var selectedLinesGutterBackgroundColor: UIColor
    
    var invisibleCharactersColor: UIColor
    
    var pageGuideHairlineColor: UIColor
    
    var pageGuideBackgroundColor: UIColor
    
    var markedTextBackgroundColor: UIColor
    
    func textColor(for highlightName: String) -> UIColor? {
        return nil
    }
    
    let font: UIFont = .monospacedSystemFont(ofSize: 17, weight: .regular)
    
    init(textColor: UIColor, gutterBackgroundColor: UIColor, gutterHairlineColor: UIColor, lineNumberColor: UIColor, selectedLineBackgroundColor: UIColor, selectedLinesLineNumberColor: UIColor, selectedLinesGutterBackgroundColor: UIColor, invisibleCharactersColor: UIColor, pageGuideHairlineColor: UIColor, pageGuideBackgroundColor: UIColor, markedTextBackgroundColor: UIColor) {
        self.textColor = textColor
        self.gutterBackgroundColor = gutterBackgroundColor
        self.gutterHairlineColor = gutterHairlineColor
        self.lineNumberColor = lineNumberColor
        self.selectedLineBackgroundColor = selectedLineBackgroundColor
        self.selectedLinesLineNumberColor = selectedLinesLineNumberColor
        self.selectedLinesGutterBackgroundColor = selectedLinesGutterBackgroundColor
        self.invisibleCharactersColor = invisibleCharactersColor
        self.pageGuideHairlineColor = pageGuideHairlineColor
        self.pageGuideBackgroundColor = pageGuideBackgroundColor
        self.markedTextBackgroundColor = markedTextBackgroundColor
    }
    
}

class LargeTheme: Runestone.Theme {
    var textColor: UIColor
    
    var gutterBackgroundColor: UIColor
    
    var gutterHairlineColor: UIColor
    
    var lineNumberColor: UIColor
    
    var lineNumberFont: UIFont = .monospacedSystemFont(ofSize: 22, weight: .regular)
    
    var selectedLineBackgroundColor: UIColor
    
    var selectedLinesLineNumberColor: UIColor
    
    var selectedLinesGutterBackgroundColor: UIColor
    
    var invisibleCharactersColor: UIColor
    
    var pageGuideHairlineColor: UIColor
    
    var pageGuideBackgroundColor: UIColor
    
    var markedTextBackgroundColor: UIColor
    
    func textColor(for highlightName: String) -> UIColor? {
        return nil
    }
    
    let font: UIFont = .monospacedSystemFont(ofSize: 22, weight: .regular)
    
    init(textColor: UIColor, gutterBackgroundColor: UIColor, gutterHairlineColor: UIColor, lineNumberColor: UIColor, selectedLineBackgroundColor: UIColor, selectedLinesLineNumberColor: UIColor, selectedLinesGutterBackgroundColor: UIColor, invisibleCharactersColor: UIColor, pageGuideHairlineColor: UIColor, pageGuideBackgroundColor: UIColor, markedTextBackgroundColor: UIColor) {
        self.textColor = textColor
        self.gutterBackgroundColor = gutterBackgroundColor
        self.gutterHairlineColor = gutterHairlineColor
        self.lineNumberColor = lineNumberColor
        self.selectedLineBackgroundColor = selectedLineBackgroundColor
        self.selectedLinesLineNumberColor = selectedLinesLineNumberColor
        self.selectedLinesGutterBackgroundColor = selectedLinesGutterBackgroundColor
        self.invisibleCharactersColor = invisibleCharactersColor
        self.pageGuideHairlineColor = pageGuideHairlineColor
        self.pageGuideBackgroundColor = pageGuideBackgroundColor
        self.markedTextBackgroundColor = markedTextBackgroundColor
    }
}
