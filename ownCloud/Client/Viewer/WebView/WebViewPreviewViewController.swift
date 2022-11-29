//
//  WebViewPreviewViewController.swift
//  ownCloud
//
//  Created by Matthias Hü+hne on 21/11/2022.
//  Copyright © 2022 ownCloud GmbH. All rights reserved.
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
import WebKit

class WebViewPreviewViewController: UIViewController, WKNavigationDelegate {

	var webView: WKWebView?
    var html: String = ""
    var mimeType: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        renderItem { state in
            let printButton = UIBarButtonItem(image: UIImage(systemName: "printer"), style: .plain, target: self, action: #selector(self.printWebView))
            self.navigationItem.rightBarButtonItem = printButton
        }
    }

    func renderItem(completion: @escaping (Bool) -> Void) {
        if self.webView == nil {
            let configuration: WKWebViewConfiguration = WKWebViewConfiguration()
            
            self.webView = WKWebView(frame: .zero, configuration: configuration)
            self.webView?.navigationDelegate = self
            
            if let webView = self.webView {
                let layoutGuide = self.view.safeAreaLayoutGuide
                
                webView.scrollView.bouncesZoom = false
                webView.translatesAutoresizingMaskIntoConstraints = false
                self.view.addSubview(webView)
                
                NSLayoutConstraint.activate([
                    webView.topAnchor.constraint(equalTo: layoutGuide.topAnchor),
                    webView.bottomAnchor.constraint(equalTo: layoutGuide.bottomAnchor),
                    webView.rightAnchor.constraint(equalTo: layoutGuide.rightAnchor),
                    webView.leftAnchor.constraint(equalTo: layoutGuide.leftAnchor)
                ])
            }
        }
        
        do {
            if mimeType == "text/markdown" {
                let html = try html.toHTML()
                webView?.loadHTMLString(html, baseURL: nil)
            } else if mimeType == "text/html" {
                webView?.loadHTMLString(html, baseURL: nil)
            } else {
                webView?.loadHTMLString(html.replacingOccurrences(of: "\n", with: "<br />"), baseURL: nil)
            }
        } catch {
            self.navigationController?.popViewController(animated: false)
            print("Error: " + error.localizedDescription)
        }
        
        completion(true)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        insertCSSString(into: webView)
    }

    func insertCSSString(into webView: WKWebView) {
        let cssString = "body { font-family: -apple-system; font-size: 50px; }"
        let jsString = "var style = document.createElement('style'); style.innerHTML = '\(cssString)'; document.head.appendChild(style);"
        webView.evaluateJavaScript(jsString, completionHandler: nil)
    }
    
    @objc func printWebView() {
        guard let webView = webView else { return }

        let printInfo = UIPrintInfo(dictionary:nil)
        printInfo.outputType = UIPrintInfo.OutputType.general

        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo
        
        let renderer: UIPrintPageRenderer = UIPrintPageRenderer()
        webView.viewPrintFormatter().printPageRenderer?.headerHeight = 30.0
        webView.viewPrintFormatter().printPageRenderer?.footerHeight = 30.0
        renderer.addPrintFormatter(webView.viewPrintFormatter(), startingAtPageAt: 0)
        printController.printPageRenderer = renderer

        printController.present(from: self.view.frame, in: self.view, animated: true, completionHandler: nil)
    }
}
