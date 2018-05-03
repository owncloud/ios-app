//
//  PasscodeViewController.swift
//  ownCloud
//
//  Created by Javier Gonzalez on 03/05/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

class PasscodeViewController: UIViewController, Themeable {

    @IBOutlet weak var cancelButton: UIButton?
    @IBOutlet weak var passcodeValueLabel: UILabel?

    @IBOutlet weak var number0Button: ThemeButton?
    @IBOutlet weak var number1Button: ThemeButton?
    @IBOutlet weak var number2Button: ThemeButton?
    @IBOutlet weak var number3Button: ThemeButton?
    @IBOutlet weak var number4Button: ThemeButton?
    @IBOutlet weak var number5Button: ThemeButton?
    @IBOutlet weak var number6Button: ThemeButton?
    @IBOutlet weak var number7Button: ThemeButton?
    @IBOutlet weak var number8Button: ThemeButton?
    @IBOutlet weak var number9Button: ThemeButton?

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Theme.shared.register(client: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions

    @IBAction func cancelButton(sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func numberButton(sender: UIButton) {

    }

    // MARK: Themeing
    func applyThemeCollection(theme: Theme, collection: ThemeCollection) {

        self.number1Button?.applyThemeCollection(collection)
        //self.detailLabel.applyThemeCollection(collection, itemStyle: .message, itemState: itemState)

        //self.iconView.image = theme.image(for: "owncloud-logo", size: CGSize(width: 40, height: 40))
    }

    func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
        self.number0Button?.applyThemeCollection(collection)
        self.number1Button?.applyThemeCollection(collection)
        self.number2Button?.applyThemeCollection(collection)
        self.number3Button?.applyThemeCollection(collection)
        self.number4Button?.applyThemeCollection(collection)
        self.number5Button?.applyThemeCollection(collection)
        self.number6Button?.applyThemeCollection(collection)
        self.number7Button?.applyThemeCollection(collection)
        self.number8Button?.applyThemeCollection(collection)
        self.number9Button?.applyThemeCollection(collection)

        //self.view.applyThemeCollection(collection)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
