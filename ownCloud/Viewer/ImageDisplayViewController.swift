//
//  ImageDisplayViewController.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 30/08/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit
import ownCloudSDK

class ImageDisplayViewController: UIViewController, DisplayViewProtocol {
	static var supportedMimeTypes: [String] = ["image/jpeg"]

	var extensionIdentifier: String!

	var imageView: UIImageView!

	static var features: [String : Any]? = [FeatureKeys.canEdit : true, FeatureKeys.showImages : true]

	var source: URL!

	weak var editingDelegate: DisplayViewEditingDelegate?

	required init() {
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		view.backgroundColor = .blue

		self.imageView = UIImageView()
		imageView.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(imageView)

		NSLayoutConstraint.activate([
			imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
			imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
			imageView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
			imageView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor)
			])

		imageView.backgroundColor = .black
		imageView.contentMode = .scaleAspectFit

		do {
			let imageData: Data = try Data(contentsOf: source)
			let image = UIImage(data: imageData)
			imageView.image = image
		} catch {
			print("LOG --->Error fetching the image from data")
			return
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
