//
//  ServerListTableHeaderView.swift
//  ownCloud
//
//  Created by Matthias Hühne on 27.01.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

import UIKit

class ServerListTableHeaderView: UIView, Themeable {
	
	// MARK: - Constants
	
	fileprivate let shadowHeight: CGFloat = 1.0
	fileprivate let textLabelTopMargin: CGFloat = 10.0
	fileprivate let textLabelHorizontalMargin: CGFloat = 20.0
	fileprivate let textLabelHeight: CGFloat = 24.0
	
	// MARK: - Instance variables.

    var messageThemeApplierToken : ThemeApplierToken?
    var textLabel : UILabel = UILabel()
    
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        Theme.shared.register(client: self, applyImmediately: true)
        
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.text = "Locations".localized
        textLabel.font = UIFont.boldSystemFont(ofSize: 24.0)
        
        self.addSubview(textLabel)
        
        let shadowView = UIView()
        shadowView.backgroundColor = UIColor.init(white: 0.0, alpha: 0.1)
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(shadowView)
        
        NSLayoutConstraint.activate([
            
            shadowView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            shadowView.widthAnchor.constraint(equalTo: self.widthAnchor),
            shadowView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            shadowView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            shadowView.heightAnchor.constraint(equalToConstant: shadowHeight),
            
            textLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: textLabelTopMargin),
            textLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: textLabelHorizontalMargin),
            textLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: textLabelHorizontalMargin),
            textLabel.heightAnchor.constraint(equalToConstant: textLabelHeight)

            ])
        
        
        messageThemeApplierToken = Theme.shared.add(applier: { [weak self] (_, collection, _) in
            self?.backgroundColor = collection.navigationBarColors.backgroundColor
            self?.textLabel.textColor = collection.navigationBarColors.labelColor
        })
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    deinit {
        Theme.shared.unregister(client: self)
        
        if messageThemeApplierToken != nil {
            Theme.shared.remove(applierForToken: messageThemeApplierToken)
            messageThemeApplierToken = nil
        }
    }
    
    
    // MARK: - Theme support
    
    func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {

        self.backgroundColor = collection.navigationBarColors.backgroundColor
        textLabel.textColor = collection.navigationBarColors.labelColor
    }

}
