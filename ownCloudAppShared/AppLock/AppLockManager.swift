//
//  AppLockManager.swift
//  ownCloud
//
//  Created by Javier Gonzalez on 06/05/2018.
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
import LocalAuthentication

public class AppLockManager: NSObject {

	// MARK: - UI
	private var userDefaults: UserDefaults

	// MARK: - Availability
	public static var supportedOnDevice : Bool {
		if #available(iOS 14, *), ProcessInfo.processInfo.isiOSAppOnMac {
			return false
		}

		return true
	}

	// MARK: - State
	private var lastApplicationBackgroundedDate : Date? {
		didSet {
			if let date = lastApplicationBackgroundedDate {
				let archivedData = try? NSKeyedArchiver.archivedData(withRootObject: date as NSDate, requiringSecureCoding: true)
				self.keychain?.write(archivedData, toKeychainItemForAccount: keychainAccount, path: keychainLockedDate)
			} else {
				_ = self.keychain?.removeItem(forAccount: keychainAccount, path: keychainLockedDate)
			}
		}
	}

	public var unlocked: Bool = false {
		didSet {
			let archivedData = try? NSKeyedArchiver.archivedData(withRootObject: unlocked as NSNumber, requiringSecureCoding: true)
			self.keychain?.write(archivedData, toKeychainItemForAccount: keychainAccount, path: keychainUnlocked)
		}
	}

	public static var isPassCodeEnabled : Bool {
		let defaults = OCAppIdentity.shared.userDefaults

		if let applockEnabled = defaults?.bool(forKey: "applock-lock-enabled") {
			return applockEnabled
		}

		return false
	}

	private var failedPasscodeAttempts: Int {
		get {
			return userDefaults.integer(forKey: "applock-failed-passcode-attempts")
		}
		set(newValue) {
			self.userDefaults.set(newValue, forKey: "applock-failed-passcode-attempts")
		}
	}
	private var lockedUntilDate: Date? {
		get {
			return userDefaults.object(forKey: "applock-locked-until-date") as? Date
		}
		set(newValue) {
			self.userDefaults.set(newValue, forKey: "applock-locked-until-date")
		}
	}

	private let maximumPasscodeAttempts: Int = 3
	private let powBaseDelay: Double = 1.5
	private var lockTimer: Timer?

	// MARK: - Passcode
	private let keychainAccount = "app.passcode"
	private let keychainPasscodePath = "passcode"
	private let keychainLockEnabledPath = "lockEnabled"
	private let keychainLockedDate = "lockedDate"
	private let keychainUnlocked = "unlocked"

	private var keychain : OCKeychain? {
		return OCAppIdentity.shared.keychain
	}

	public var passcode: String? {
		get {
			if let passcodeData = self.keychain?.readDataFromKeychainItem(forAccount: keychainAccount, path: keychainPasscodePath) {
				return String(data: passcodeData, encoding: .utf8)
			}

			return nil
		}

		set(newPasscode) {
			if let passcode = newPasscode {
				_ = self.keychain?.write(passcode.data(using: .utf8), toKeychainItemForAccount: keychainAccount, path: keychainPasscodePath)
			} else {
				_ = self.keychain?.removeItem(forAccount: keychainAccount, path: keychainPasscodePath)
			}
		}
	}

	// MARK: - Settings
	public var lockEnabled: Bool {
		get {
			return userDefaults.bool(forKey: "applock-lock-enabled")
		}
		set(newValue) {
			self.userDefaults.set(newValue, forKey: "applock-lock-enabled")
		}
	}

	public var lockDelay: Int {
		get {
			return userDefaults.integer(forKey: "applock-lock-delay")
		}

		set(newValue) {
			self.userDefaults.set(newValue, forKey: "applock-lock-delay")
		}
	}

	public var biometricalSecurityEnabled: Bool {
		get {
			return self.userDefaults.bool(forKey: "security-settings-use-biometrical")
		}

		set(newValue) {
			self.userDefaults.set(newValue, forKey: "security-settings-use-biometrical")
		}
	}

	// Set a view controller only, if you want to use it in an extension, when UIWindow is not working
	public var passwordViewHostViewController: UIViewController?

	// MARK: - Init
	public static var shared = AppLockManager()

	public override init() {
		userDefaults = OCAppIdentity.shared.userDefaults!

		super.init()

		if AppLockManager.supportedOnDevice {
			NotificationCenter.default.addObserver(self, selector: #selector(self.appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
			NotificationCenter.default.addObserver(self, selector: #selector(self.appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
			NotificationCenter.default.addObserver(self, selector: #selector(self.updateLockscreens), name: ThemeWindow.themeWindowListChangedNotification, object: nil)
		}
	}

	deinit {
		if AppLockManager.supportedOnDevice {
			NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
			NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
			NotificationCenter.default.removeObserver(self, name: ThemeWindow.themeWindowListChangedNotification, object: nil)
		}
	}

	// MARK: - Show / Dismiss Passcode View
	public func showLockscreenIfNeeded(forceShow: Bool = false, context: LAContext = LAContext()) {
		if self.shouldDisplayLockscreen || forceShow {
			lockscreenOpenForced = forceShow
			lockscreenOpen = true

			// Show biometrical
			if !forceShow, !self.shouldDisplayCountdown {
				showBiometricalAuthenticationInterface(context: context)
			}
		}
	}

	public func dismissLockscreen(animated:Bool) {
		if animated {
			let animationGroup = DispatchGroup()

			for themeWindow in ThemeWindow.themeWindows {
				if let appLockWindow = applockWindowByWindow.object(forKey: themeWindow) {
					animationGroup.enter()

					appLockWindow.hideWindowAnimation {
						appLockWindow.isHidden = true
						animationGroup.leave()
					}
				}
			}

			animationGroup.notify(queue: .main) {
				self.lockscreenOpen = false
			}
		} else {
			self.lockscreenOpen = false
		}
	}

	// MARK: - Lock window management
	private var lockscreenOpenForced : Bool = false
	private var lockscreenOpen : Bool = false {
		didSet {
			updateLockscreens()
		}
	}

	private var passcodeControllerByWindow : NSMapTable<ThemeWindow, PasscodeViewController> = NSMapTable.weakToStrongObjects()
	private var applockWindowByWindow : NSMapTable<ThemeWindow, AppLockWindow> = NSMapTable.weakToStrongObjects()

	open var cancelAction : (() -> Void)?

	@objc private func cancelPressed () {
		cancelAction?()
	}

	@objc func updateLockscreens() {
		if lockscreenOpen {
			if let passwordViewHostViewController = passwordViewHostViewController {
				if let passcodeViewController = passwordViewHostViewController.children.last as? PasscodeViewController {
					passcodeViewController.screenBlurringEnabled = lockscreenOpenForced
				} else {
					let passcodeViewController = passwordViewController()
					let navigationController = ThemeNavigationController(rootViewController: passcodeViewController)
					navigationController.modalPresentationStyle = .overFullScreen

					if cancelAction != nil {
						let itemCancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelPressed))
						passcodeViewController.navigationItem.setRightBarButton(itemCancel, animated: false)
					}
					passcodeViewController.navigationItem.title = VendorServices.shared.appName

					passwordViewHostViewController.present(navigationController, animated: false, completion: nil)

					self.startLockCountdown()

					if self.shouldDisplayCountdown {
						passcodeViewController.keypadButtonsHidden = true
						updateLockCountdown()
					}
				}
			} else {
				for themeWindow in ThemeWindow.themeWindows {
					if let passcodeViewController = passcodeControllerByWindow.object(forKey: themeWindow) {
						passcodeViewController.screenBlurringEnabled = lockscreenOpenForced
					} else {
						var appLockWindow : AppLockWindow
						let passcodeViewController = passwordViewController()

						if #available(iOS 13, *) {
							if let windowScene = themeWindow.windowScene {
								appLockWindow = AppLockWindow(windowScene: windowScene)
							} else {
								appLockWindow = AppLockWindow(frame: UIScreen.main.bounds)
							}
						} else {
							appLockWindow = AppLockWindow(frame: UIScreen.main.bounds)
						}
						/*
						Workaround to the lack of status bar animation when returning true for prefersStatusBarHidden in
						PasscodeViewController.

						The documentation notes that "The ordering of windows within a given window level is not guaranteed.",
						so that with a future iOS update this might break and the status bar be displayed regardless. In that
						case, implement prefersStatusBarHidden in PasscodeViewController to return true and remove the dismiss
						animation (the re-appearance of the status bar will lead to a jump in the UI otherwise).
						*/
						appLockWindow.windowLevel = UIWindow.Level.statusBar
						appLockWindow.rootViewController = passcodeViewController
						appLockWindow.makeKeyAndVisible()

						passcodeControllerByWindow.setObject(passcodeViewController, forKey: themeWindow)
						applockWindowByWindow.setObject(appLockWindow, forKey: themeWindow)

						self.startLockCountdown()

						if self.shouldDisplayCountdown {
							passcodeViewController.keypadButtonsHidden = true
							updateLockCountdown()
						}
					}
				}
			}
		} else {
			if let passwordViewHostViewController = passwordViewHostViewController, let passcodeViewController = passwordViewHostViewController.topMostViewController as? PasscodeViewController {
				passcodeViewController.dismiss(animated: false, completion: nil)
			} else {
				for themeWindow in ThemeWindow.themeWindows {
					if let appLockWindow = applockWindowByWindow.object(forKey: themeWindow) {
						appLockWindow.isHidden = true

						passcodeControllerByWindow.removeObject(forKey: themeWindow)
						applockWindowByWindow.removeObject(forKey: themeWindow)
					}
				}
			}
		}
	}

	func passwordViewController() -> PasscodeViewController {
		var passcodeViewController : PasscodeViewController

		passcodeViewController = PasscodeViewController(completionHandler: { (viewController: PasscodeViewController, passcode: String) in
			self.attemptUnlock(with: passcode, passcodeViewController: viewController)
		})

		passcodeViewController.message = "Enter code".localized
		passcodeViewController.cancelButtonHidden = false

		passcodeViewController.screenBlurringEnabled = lockscreenOpenForced && !self.shouldDisplayLockscreen

		return passcodeViewController
	}

	// MARK: - App Events
	@objc func appDidEnterBackground() {
		lastApplicationBackgroundedDate = Date()

		showLockscreenIfNeeded(forceShow: true)
	}

	@objc func appWillEnterForeground() {
		if self.shouldDisplayLockscreen {
			showLockscreenIfNeeded()
		} else {
			dismissLockscreen(animated: false)
		}
	}

	// MARK: - Unlock
	func attemptUnlock(with testPasscode: String?, customErrorMessage: String? = nil, passcodeViewController: PasscodeViewController? = nil) {
		if testPasscode == self.passcode {
			unlocked = true
			lastApplicationBackgroundedDate = nil
			failedPasscodeAttempts = 0
			dismissLockscreen(animated: true)
		} else {
			unlocked = false
			passcodeViewController?.errorMessage = (customErrorMessage != nil) ? customErrorMessage! : "Incorrect code".localized

			failedPasscodeAttempts += 1

			if self.failedPasscodeAttempts >= self.maximumPasscodeAttempts {
				let delayUntilNextAttempt = pow(powBaseDelay, Double(failedPasscodeAttempts))

				lockedUntilDate = Date().addingTimeInterval(delayUntilNextAttempt)
				startLockCountdown()
			}

			passcodeViewController?.passcode = nil
		}
	}

	// MARK: - Status
	private var shouldDisplayLockscreen: Bool {
		if !self.lockEnabled {
			return false
		}

		if unlocked, !self.shouldDisplayCountdown {
			if let date = self.lastApplicationBackgroundedDate {
				if Int(-date.timeIntervalSinceNow) < self.lockDelay {
					return false
				}
			}
		}
		unlocked = false
		return true
	}

	private var shouldDisplayCountdown : Bool {
		if let startLockBeforeDate = self.lockedUntilDate {
			return startLockBeforeDate > Date()
		}

		return false
	}

	// MARK: - Countdown display
	private func startLockCountdown() {
		if self.shouldDisplayCountdown {
			performPasscodeViewControllerUpdates { (passcodeViewController) in
				passcodeViewController.keypadButtonsHidden = true
			}
			updateLockCountdown()

			lockTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateLockCountdown), userInfo: nil, repeats: true)
		}
	}

	@objc private func updateLockCountdown() {
		if let date = self.lockedUntilDate {
			let interval = Int(date.timeIntervalSinceNow)
			let seconds = interval % 60
			let minutes = (interval / 60) % 60
			let hours = (interval / 3600)

			let dateFormatted:String?
			if hours > 0 {
				dateFormatted = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
			} else {
				dateFormatted = String(format: "%02d:%02d", minutes, seconds)
			}

			let timeoutMessage:String = NSString(format: "Please try again in %@".localized as NSString, dateFormatted!) as String

			performPasscodeViewControllerUpdates { (passcodeViewController) in
				passcodeViewController.timeoutMessage = timeoutMessage
			}

			if date <= Date() {
				// Time elapsed, allow entering passcode again
				self.lockTimer?.invalidate()
				performPasscodeViewControllerUpdates { (passcodeViewController) in
					passcodeViewController.keypadButtonsHidden = false
					passcodeViewController.timeoutMessage = nil
					passcodeViewController.errorMessage = nil
				}
			}
		}
	}

	private func performPasscodeViewControllerUpdates(_ updateHandler: (_: PasscodeViewController) -> Void) {
		for themeWindow in ThemeWindow.themeWindows {
			if let passcodeViewController = passcodeControllerByWindow.object(forKey: themeWindow) {
				updateHandler(passcodeViewController)
			}
		}
	}

	// MARK: - Biometrical Unlock
	private var biometricalAuthenticationInterfaceShown : Bool = false

	func showBiometricalAuthenticationInterface(context: LAContext) {
		if shouldDisplayLockscreen, biometricalSecurityEnabled, !biometricalAuthenticationInterfaceShown {
			var evaluationError: NSError?

			// Check if the device can evaluate the policy.
			if context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &evaluationError) {
				let reason = NSString.init(format: "Unlock %@".localized as NSString, VendorServices.shared.appName) as String

				performPasscodeViewControllerUpdates { (passcodeViewController) in
					OnMainThread {
						passcodeViewController.errorMessage = nil
					}
				}

				context.localizedCancelTitle = "Enter code".localized
				context.localizedFallbackTitle = ""

				self.biometricalAuthenticationInterfaceShown = true

				context.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { (success, error) in
					self.biometricalAuthenticationInterfaceShown = false

					if success {
						// Fill the passcode dots
						OnMainThread {
							self.performPasscodeViewControllerUpdates { (passcodeViewController) in
								passcodeViewController.passcode = self.passcode
							}
						}
						// Remove the passcode after small delay to give user feedback after use the biometrical unlock
						OnMainThread(after: 0.3) {
							self.attemptUnlock(with: self.passcode)
						}
					} else {
						if let error = error {
							switch error {
								case LAError.biometryLockout:
									OnMainThread {
										self.performPasscodeViewControllerUpdates { (passcodeViewController) in
											passcodeViewController.errorMessage = error.localizedDescription
										}
									}

								case LAError.authenticationFailed:
									OnMainThread {
										self.attemptUnlock(with: nil, customErrorMessage: "Biometric authentication failed".localized)
									}

								default: break
							}
						}
					}
				}
			} else {
				if let error = evaluationError, biometricalSecurityEnabled {
					OnMainThread {
						self.performPasscodeViewControllerUpdates { (passcodeViewController) in
							passcodeViewController.errorMessage = error.localizedDescription
						}
					}
				}
			}
		}
	}
}
