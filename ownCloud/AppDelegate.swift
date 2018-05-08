//
//  AppDelegate.swift
//  ownCloud
//
//  Created by Pablo Carrascal on 07/03/2018.
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
import ownCloudSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	var serverListTableViewController: ServerListTableViewController?
    var orientationLock = UIInterfaceOrientationMask.all

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.
		var navigationController: UINavigationController?

		window = UIWindow(frame: UIScreen.main.bounds)

		serverListTableViewController = ServerListTableViewController(style: UITableViewStyle.plain)

		navigationController = ThemeNavigationController(rootViewController: serverListTableViewController!)

		/*window?.rootViewController = navigationController!
		window?.addSubview((navigationController?.view)!)
        PasscodeUtilities.sharedPasscodeUtilities.showPasscodeIfNeeded(viewController: (window?.rootViewController)!, hiddenOverlay: true)*/



        if OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath) != nil {

            let passcodeViewController = PasscodeViewController(mode: PasscodeInterfaceMode.unlockPasscode, hiddenOverlay:false, handler: {
                print("Show app")
                DispatchQueue.main.async {    
                    self.window?.rootViewController = navigationController!
                    self.window?.addSubview((navigationController?.view)!)
                }
            })
            window?.rootViewController = passcodeViewController
        } else {
            window?.rootViewController = navigationController!
            window?.addSubview((navigationController?.view)!)
        }




        

        self.window?.makeKeyAndVisible()

		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.

        PasscodeUtilities.sharedPasscodeUtilities.showPasscodeIfNeeded(viewController: (window?.rootViewController)!, hiddenOverlay: false)

        /*if OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath) != nil {

            self.passcodeViewController = PasscodeViewController(mode: PasscodeInterfaceMode.unlockPasscode, hiddenOverlay:hiddenOverlay, handler: {

            })
            viewController.present(self.passcodeViewController!, animated: false, completion: nil)
        }*/
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

        //PasscodeUtilities.sharedPasscodeUtilities.dismissAskedPasscodeIfDateToAskIsLower()
    }

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

        if OCAppIdentity.shared().keychain.readDataFromKeychainItem(forAccount: passcodeKeychainAccount, path: passcodeKeychainPath) != nil {
            PasscodeUtilities.sharedPasscodeUtilities.storeDateHomeButtonPressed()
        }
	}
}
