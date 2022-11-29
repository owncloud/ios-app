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

//import TreeSitterAstroRunestone
import TreeSitterBashRunestone
import TreeSitterCRunestone
import TreeSitterCommentRunestone
import TreeSitterCSharpRunestone
import TreeSitterCPPRunestone
import TreeSitterCSSRunestone
import TreeSitterElixirRunestone
import TreeSitterElmRunestone
import TreeSitterGoRunestone
import TreeSitterHaskellRunestone
import TreeSitterHTMLRunestone
import TreeSitterJavaRunestone
import TreeSitterJavaScriptRunestone
import TreeSitterJSDocRunestone
import TreeSitterJSONRunestone
import TreeSitterJSON5Runestone
import TreeSitterJuliaRunestone
import TreeSitterLaTeXRunestone
import TreeSitterLuaRunestone
import TreeSitterMarkdownRunestone
import TreeSitterOCamlRunestone
import TreeSitterPerlRunestone
import TreeSitterPHPRunestone
import TreeSitterPythonRunestone
import TreeSitterRRunestone
import TreeSitterRegexRunestone
import TreeSitterRubyRunestone
import TreeSitterRustRunestone
import TreeSitterSCSSRunestone
import TreeSitterSvelteRunestone
import TreeSitterSwiftRunestone
import TreeSitterTOMLRunestone
import TreeSitterTSXRunestone
import TreeSitterTypeScriptRunestone
import TreeSitterYAMLRunestone

enum SyntaxHighlighting: Int, CaseIterable {
    case bash = 0, c, comment, csharp, cpp, css, elexir, elm, go, haskell, html, java, javascript, jsdoc, json, json5, julia, latex, lua, markdown, ocaml, perl, php, python, r, regex, ruby, rust, scss, svelte, swift, toml, tsx, typescript, yaml
    
    var description: String {
        switch self {
        case .bash:
            return "Bash"
        case .c:
            return "C"
        case .comment:
            return "Comment"
        case .csharp:
            return "C#"
        case .cpp:
            return "C++"
        case .css:
            return "CSS"
        case .elexir:
            return "Elexir"
        case .elm:
            return "Elm"
        case .go:
            return "Go"
        case .haskell:
            return "Haskell"
        case .html:
            return "HTML"
        case .java:
            return "Java"
        case .javascript:
            return "JavaScript"
        case .jsdoc:
            return "JsDoc"
        case .json:
            return "JSON"
        case .json5:
            return "JSON 5"
        case .julia:
            return "Julia"
        case .latex:
            return "LateX"
        case .lua:
            return "Lua"
        case .markdown:
            return "Markdown"
        case .ocaml:
            return "Ocaml"
        case .perl:
            return "Perl"
        case .php:
            return "PHP"
        case .python:
            return "Python"
        case .r:
            return "R"
        case .regex:
            return "RegEx"
        case .ruby:
            return "Ruby"
        case .rust:
            return "Rust"
        case .scss:
            return "SCSS"
        case .svelte:
            return "Svelte"
        case .swift:
            return "Swift"
        case .toml:
            return "Toml"
        case .tsx:
            return "Tsx"
        case .typescript:
            return "TypeScript"
        case .yaml:
            return "Yaml"
        }
    }
    
    var language: TreeSitterLanguage {
        switch self {
        case .bash:
            return .bash
        case .c:
            return .c
        case .comment:
            return .comment
        case .csharp:
            return .cSharp
        case .cpp:
            return .cpp
        case .css:
            return .css
        case .elexir:
            return .elixir
        case .elm:
            return .elm
        case .go:
            return .go
        case .haskell:
            return .haskell
        case .html:
            return .html
        case .java:
            return .java
        case .javascript:
            return .javaScript
        case .jsdoc:
            return .jsDoc
        case .json:
            return .json
        case .json5:
            return .json5
        case .julia:
            return .julia
        case .latex:
            return .latex
        case .lua:
            return .lua
        case .markdown:
            return .markdown
        case .ocaml:
            return .ocaml
        case .perl:
            return .perl
        case .php:
            return .php
        case .python:
            return .python
        case .r:
            return .r
        case .regex:
            return .regex
        case .ruby:
            return .ruby
        case .rust:
            return .rust
        case .scss:
            return .scss
        case .svelte:
            return .svelte
        case .swift:
            return .swift
        case .toml:
            return .toml
        case .tsx:
            return .tsx
        case .typescript:
            return .typeScript
        case .yaml:
            return .yaml
        }
    }
}

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

extension EditTextViewController: UINavigationItemRenameDelegate {
  
    func navigationItem(_: UINavigationItem, didEndRenamingWith title: String) {
        guard let core = core else { return }
        let rootItem = item.parentItem(from: core)
        
        if title.contains("/") || title.contains("\\") {
           // return (false, nil, "File name cannot contain / or \\".localized)
        } else {
            if let rootItem = rootItem {
                if ((try? self.core?.cachedItem(inParent: rootItem, withName: title, isDirectory: true)) != nil) ||
                   ((try? self.core?.cachedItem(inParent: rootItem, withName: title, isDirectory: false)) != nil) {
                    //return (false, "Item with same name already exists".localized, "An item with the same name already exists in this location.".localized)
                } else {
                    self.core?.move(item, to: rootItem, withName: title, options: nil, resultHandler: { (error, _, _, _) in
                        if error != nil {
                            Log.log("Error \(String(describing: error)) renaming \(String(describing: self.item.path))")
                        }
                    })
                }
            }

        }
    }
    
    func navigationItemShouldBeginRenaming(_: UINavigationItem) -> Bool {
        return true
    }
    /*
    func navigationItem(_: UINavigationItem, willBeginRenamingWith suggestedTitle: String, selectedRange: Range<String.Index>) -> (String, Range<String.Index>) {
        
    }*/
    
    func navigationItem(_: UINavigationItem, shouldEndRenamingWith title: String) -> Bool {
        return true
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
    var canPreviewDocument: Bool = false {
        didSet {
            updateBarButtons()
        }
    }
    var language: TreeSitterLanguage? {
        didSet {
            self.activateRunestoneTheme(with: self.fontSize, collection: Theme.shared.activeCollection)
            updateBarButtons()
        }
    }
    var syntax: SyntaxHighlighting?
    var fontSize: CGFloat = 12.0 {
        didSet {
            self.activateRunestoneTheme(with: self.fontSize, collection: Theme.shared.activeCollection)
            updateBarButtons()
        }
    }

	init(with file: URL, item: OCItem, core: OCCore? = nil) {
		self.source = file
		self.core = core
		self.item = item

		super.init(nibName: nil, bundle: nil)

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissAnimated))
        
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
    
    @objc func showFindUI() {
        
        if #available(iOS 16, *) {
            self.textView.findInteraction?.presentFindNavigator(showingReplace: false)
        } else {
            // Fallback on earlier versions
        }
    }
    
    @objc func showFindReplaceUI() {
        
        if #available(iOS 16, *) {
            self.textView.findInteraction?.presentFindNavigator(showingReplace: true)
        } else {
            // Fallback on earlier versions
        }
    }

	override func viewDidLoad() {
		super.viewDidLoad()
        
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.editorDelegate = self
        
        updateToolbar()
        updateBarButtons()
        
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
                self.textView.text = string
                determineTreeSitterLanguage()
                
                stringEncoding.printEncoding()
            }
           // inString = try String(contentsOf: self.source, usedEncoding: &usedEncoding)
           // usedEncoding.printEncoding()
            
        } catch {
            assertionFailure("Failed reading from URL: \(self.source), Error: " + error.localizedDescription)
        }
	}
    
    func determineTreeSitterLanguage() {
        let fileExtension = source.pathExtension
        
        if fileExtension.hasPrefix("php") || fileExtension == "phtml" {
            language = .php
            syntax = .php
        } else if fileExtension == "md" {
            language = .markdown
            syntax = .markdown
            canPreviewDocument = true
        } else if fileExtension == "html" {
            language = .html
            syntax = .html
            canPreviewDocument = true
        } else if fileExtension == "swift" {
            language = .swift
            syntax = .swift
        } else if fileExtension == "comment" {
            language = .comment
            syntax = .comment
        } else if fileExtension == "css" {
            language = .css
            syntax = .css
        } else if fileExtension == "js" {
            language = .javaScript
            syntax = .javascript
        } else if fileExtension == "sh" {
            language = .bash
            syntax = .bash
        } else if fileExtension == "hs" {
            language = .haskell
            syntax = .haskell
        } else if ["c", "h"].contains(fileExtension) {
            language = .c
            syntax = .c
        } else if fileExtension == "cpp" {
            language = .cpp
            syntax = .cpp
        } else if fileExtension == "cs" {
            language = .cSharp
            syntax = .csharp
        } else if fileExtension == "elm" {
            language = .elm
            syntax = .elm
        } else if fileExtension == "go" {
            language = .go
            syntax = .go
        } else if fileExtension == "java" {
            language = .java
            syntax = .java
        } else if fileExtension == "jl" {
            language = .julia
            syntax = .julia
        } else if fileExtension == "tex" {
            language = .latex
            syntax = .latex
        } else if fileExtension == "lua" {
            language = .lua
            syntax = .lua
        } else if ["ml", "mli"].contains(fileExtension) {
            language = .ocaml
            syntax = .ocaml
        } else if ["ex", "exs"].contains(fileExtension) {
            language = .ocaml
            syntax = .ocaml
        } else if fileExtension == "pl" {
            language = .perl
            syntax = .perl
        } else if fileExtension == "py" {
            language = .python
            syntax = .python
        } else if fileExtension == "r" {
            language = .r
            syntax = .r
        } else if fileExtension == "rb" {
            language = .ruby
            syntax = .ruby
        } else if fileExtension == "rs" {
            language = .rust
            syntax = .rust
        } else if fileExtension == "scss" {
            language = .scss
            syntax = .scss
        } else if fileExtension == "svelte" {
            language = .svelte
            syntax = .svelte
        } else if fileExtension == "toml" {
            language = .toml
            syntax = .toml
        } else if fileExtension == "tsx" {
            language = .tsx
            syntax = .tsx
        } else if fileExtension == "ts" {
            language = .typeScript
            syntax = .typescript
        } else if ["yml", "yaml"].contains(fileExtension) {
            language = .yaml
            syntax = .yaml
        }
    }
    
    func activateRunestoneTheme(with fontSize: CGFloat, collection: ThemeCollection, text: String? = nil) {
        let runestoneTheme = RegularTheme(collection: collection, fontSize: fontSize)
        //self.fontSize = fontSize

        let state = TextViewState(text: text ?? self.textView.text, theme: runestoneTheme)
        DispatchQueue.main.async {
            self.textView.setState(state)
            
            if let language = self.language {
                let languageMode = TreeSitterLanguageMode(language: language)
                self.textView.setLanguageMode(languageMode)
            }
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
    
    func updateToolbar() {
        if #available(iOS 16.0, *) {
            navigationItem.style = .editor
            
            let documentProperties = UIDocumentProperties (url: source)
            navigationItem.documentProperties = documentProperties
            navigationItem.renameDelegate = self
            
            let findBarButton = UIBarButtonItem(title: "Find".localized, image: UIImage(systemName: "magnifyingglass"), target: self, action: #selector(showFindUI)).creatingOptionalGroup(customizationIdentifier: "fcom.owncloud.toolbar.editor.find")
            
            let findReplaceBarButton = UIBarButtonItem(title: "Find and Replace".localized, image: UIImage(systemName: "text.magnifyingglass"), target: self, action: #selector(showFindReplaceUI)).creatingOptionalGroup(customizationIdentifier: "com.owncloud.toolbar.editor.find-replace", isInDefaultCustomization: false)
            
            let previewBarButton = UIBarButtonItem(title: "Preview".localized, image: UIImage(systemName: "eye.square"), target: self, action: #selector(previewContent)).creatingOptionalGroup(customizationIdentifier: "com.owncloud.toolbar.editor.preview")
            
            if canPreviewDocument {
                navigationItem.centerItemGroups = [findBarButton, findReplaceBarButton, previewBarButton]
                navigationItem.customizationIdentifier = "com.owncloud.toolbar.editor-preview"
            } else {
                navigationItem.centerItemGroups = [findBarButton, findReplaceBarButton]
                navigationItem.customizationIdentifier = "com.owncloud.toolbar.editor"
            }
            
            navigationItem.titleMenuProvider = { suggestedActions in
                var children = suggestedActions
                
                var languageItems : [UIMenuElement] = []
                
                for item in SyntaxHighlighting.allCases {
                    let itemAction : UIAction = .init(title: item.description, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: self.syntax == item ? .on : .off, handler: { (action) in
                        self.syntax = item
                        self.language = item.language
                    })
                    languageItems.append(itemAction)
                }
                
                let languageMenu = UIMenu(title: "Syntax Highlighing".localized, image: UIImage(systemName: "ellipsis.curlybraces"), identifier: UIMenu.Identifier("syntaxmenu"), options: [], children: languageItems)
                
                children += [
                    languageMenu
                ]
                return UIMenu(children: children)
            }
        }
    }
    
    func updateBarButtons() {
        var menuItems : [UIMenuElement] = []
        
        /*
        if #unavailable(iOS 16.0) {
            let findAction : UIAction = .init(title: "Find".localized, image: UIImage(systemName: "magnifyingglass"), identifier: nil, discoverabilityTitle: nil, attributes: .init(), handler: { (action) in
                if #available(iOS 16, *) {
                    self.textView.findInteraction?.presentFindNavigator(showingReplace: false)
                } else {
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
        }*/
        
        if canPreviewDocument {
            let previewAction : UIAction = .init(title: "Preview".localized, image: UIImage(systemName: "eye.square"), identifier: nil, discoverabilityTitle: nil, attributes: .init(), handler: { (action) in
                self.previewContent()
            })
            menuItems.append(previewAction)
        }
        
        
        var languageItems : [UIMenuElement] = []
        
        for item in SyntaxHighlighting.allCases {
            let itemAction : UIAction = .init(title: item.description, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: self.syntax == item ? .on : .off, handler: { (action) in
                self.syntax = item
                self.language = item.language
                })
            languageItems.append(itemAction)
        }
        
        let languageMenu = UIMenu(title: "Syntax Highlighing".localized, image: UIImage(systemName: "ellipsis.curlybraces"), identifier: UIMenu.Identifier("syntaxmenu"), options: [], children: languageItems)
        menuItems.append(languageMenu)
        
        var submenuItems : [UIMenuElement] = []
        
        let regularFontSizeAction : UIAction = .init(title: "Regular".localized, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: self.fontSize == 12.0 ? .on : .off, handler: { (action) in
            self.fontSize = 12.0
        })
        submenuItems.append(regularFontSizeAction)
        
        let mediumFontSizeAction : UIAction = .init(title: "Medium".localized, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: self.fontSize == 14.0 ? .on : .off, handler: { (action) in
            self.fontSize = 14.0
        })
        submenuItems.append(mediumFontSizeAction)
        
        let largeFontSizeAction : UIAction = .init(title: "Large".localized, identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: self.fontSize == 17.0 ? .on : .off, handler: { (action) in
            self.fontSize = 17.0
        })
        submenuItems.append(largeFontSizeAction)
        
        let subMenu = UIMenu(title: "Font Size".localized, image: UIImage(systemName: "textformat.size"), identifier: UIMenu.Identifier("submenu"), options: [], children: submenuItems)
        menuItems.append(subMenu)
        
        
        let lineNumbersAction : UIAction = .init(title: "Line Numbers".localized, image: UIImage(systemName: "list.number"), identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: self.textView.showLineNumbers == true ? .on : .off, handler: { (action) in
            self.textView.showLineNumbers.toggle()
            self.updateBarButtons()
        })
        menuItems.append(lineNumbersAction)
        
        
        let unvisibleCharactersAction : UIAction = .init(title: "Invisible Characters".localized, image: UIImage(systemName: "paragraphsign"), identifier: nil, discoverabilityTitle: nil, attributes: .init(), state: self.textView.showSpaces == true ? .on : .off, handler: { (action) in
            self.textView.showSpaces.toggle()
            self.textView.showNonBreakingSpaces.toggle()
            self.textView.showTabs.toggle()
            self.textView.showLineBreaks.toggle()
            self.textView.showSoftLineBreaks.toggle()
            self.updateBarButtons()
        })
        menuItems.append(unvisibleCharactersAction)
        
        let menu = UIMenu(title: "",  children: menuItems)
#if !targetEnvironment(macCatalyst)
        if #available(iOS 16.0, *) {
            menu.preferredElementSize = .medium
        }
#endif
        
        if #available(iOS 16.0, *) {
            let dynamicElements = UIDeferredMenuElement { completion in
                DispatchQueue.main.async {
                    let items: [UIMenuElement] = menuItems
                    completion(items)
                }
            }
            navigationItem.additionalOverflowItems = dynamicElements
        } else {
            let menuButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "ellipsis.circle"), primaryAction: nil, menu: menu)
            
            if canPreviewDocument {
                let previewButton = UIBarButtonItem(image: UIImage(systemName: "eye.square"), style: .plain, target: self, action: #selector(previewContent))
                
                navigationItem.rightBarButtonItems = [menuButton, previewButton]
            } else {
                navigationItem.rightBarButtonItem = menuButton
            }
        }
    }
    
    @objc func previewContent() {
        guard let mimeType = self.item.mimeType else { return }
        
        let newViewController = WebViewPreviewViewController()
        newViewController.html = self.textView.text
        newViewController.mimeType = mimeType
        
        self.navigationController?.pushViewController(newViewController, animated: false)
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
        self.activateRunestoneTheme(with: self.fontSize, collection: Theme.shared.activeCollection)
        self.textView.backgroundColor = collection.tableBackgroundColor
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
    var lineNumberFont: UIFont
    var selectedLineBackgroundColor: UIColor
    var selectedLinesLineNumberColor: UIColor
    var selectedLinesGutterBackgroundColor: UIColor
    var invisibleCharactersColor: UIColor
    var pageGuideHairlineColor: UIColor
    var pageGuideBackgroundColor: UIColor
    var markedTextBackgroundColor: UIColor
    var font: UIFont
    var collection: ThemeCollection
    
    init(collection: ThemeCollection, fontSize: CGFloat) {
        self.collection = collection
        self.textColor = collection.tableRowColors.labelColor
        self.gutterBackgroundColor = collection.tableBackgroundColor
        self.gutterHairlineColor = collection.tableRowColors.labelColor
        self.lineNumberColor = collection.tintColor
        self.selectedLineBackgroundColor = collection.tintColor
        self.selectedLinesLineNumberColor = collection.tintColor
        self.selectedLinesGutterBackgroundColor = collection.tintColor
        self.invisibleCharactersColor = collection.tintColor
        self.pageGuideHairlineColor = collection.tintColor
        self.pageGuideBackgroundColor = collection.tintColor
        self.markedTextBackgroundColor = collection.tintColor
        self.font = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
        self.lineNumberFont = .monospacedSystemFont(ofSize: fontSize, weight: .regular)
    }
    
    func textColor(for highlightName: String) -> UIColor? {
            guard let highlightName = HighlightName(highlightName) else {
                return nil
            }
            switch highlightName {
            case .comment:
                return collection.toolbarColors.secondaryLabelColor
            case .constructor:
                return collection.successColor.darker(0.2)
            case .function:
                return collection.successColor
            case .keyword, .type:
                return collection.warningColor
            case .number, .constantBuiltin, .constantCharacter:
                return collection.tintColor
            case .property:
                return collection.tintColor
            case .string:
                return collection.errorColor
            case .variableBuiltin:
                return collection.errorColor.darker(0.3)
            case .operator, .punctuation:
                return collection.errorColor.withAlphaComponent(0.75)
            case .variable:
                return nil
            }
        }
}

enum HighlightName: String {
    case comment
    case constantBuiltin = "constant.builtin"
    case constantCharacter = "constant.character"
    case constructor
    case function
    case keyword
    case number
    case `operator`
    case property
    case punctuation
    case string
    case type
    case variable
    case variableBuiltin = "variable.builtin"

    init?(_ rawHighlightName: String) {
        var comps = rawHighlightName.split(separator: ".")
        while !comps.isEmpty {
            let candidateRawHighlightName = comps.joined(separator: ".")
            if let highlightName = Self(rawValue: candidateRawHighlightName) {
                self = highlightName
                return
            }
            comps.removeLast()
        }
        return nil
    }
}
