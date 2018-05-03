//
//  PasscodeViewController.swift
//  ownCloud
//
//  Created by Javier Gonzalez on 03/05/2018.
//  Copyright © 2018 ownCloud GmbH. All rights reserved.
//

import UIKit

class PasscodeViewController: UIViewController {

    @IBOutlet weak var cancelButton: UIButton?
    @IBOutlet weak var passcodeValueLabel: UILabel?

    @IBOutlet weak var number1Button: UIButton?
    @IBOutlet weak var number2Button: UIButton?
    @IBOutlet weak var number3Button: UIButton?
    @IBOutlet weak var number4Button: UIButton?
    @IBOutlet weak var number5Button: UIButton?
    @IBOutlet weak var number6Button: UIButton?
    @IBOutlet weak var number7Button: UIButton?
    @IBOutlet weak var number8Button: UIButton?
    @IBOutlet weak var number9Button: UIButton?
    @IBOutlet weak var number0Button: UIButton?


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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
