import ownCloudSDK

public enum HCL10n {
	public enum Common {
		public static var ok: String { OCLocalizedString("Common.ok" , nil) }
		public static var cancel: String { OCLocalizedString("Common.cancel" , nil) }
	}

	public enum Logo {
		public static var firstPart: String { OCLocalizedString("Logo.firstPart" , nil) }
		public static var secondPart: String { OCLocalizedString("Logo.secondPart" , nil) }
	}

	public enum Onboarding {
		public static var doneButtonTitle: String { OCLocalizedString("Onboarding.doneButtonTitle" , nil) }
		public static var skipButtonTitle: String { OCLocalizedString("Onboarding.skipButtonTitle" , nil) }

		public enum Step_ManageFiles {
			public static var title: String { OCLocalizedString("Onboarding.Step_ManageFiles.title" , nil) }
			public static var subtitle: String { OCLocalizedString("Onboarding.Step_ManageFiles.subtitle" , nil) }
		}
		public enum Step_SyncFiles {
			public static var title: String { OCLocalizedString("Onboarding.Step_SyncFiles.title" , nil) }
			public static var subtitle: String { OCLocalizedString("Onboarding.Step_SyncFiles.subtitle" , nil) }
		}
		public enum Step_FileDeduplication {
			public static var title: String { OCLocalizedString("Onboarding.Step_FileDeduplication.title" , nil) }
			public static var subtitle: String { OCLocalizedString("Onboarding.Step_FileDeduplication.subtitle" , nil) }
		}
		public enum Step_Search {
			public static var title: String { OCLocalizedString("Onboarding.Step_Search.title" , nil) }
			public static var subtitle: String { OCLocalizedString("Onboarding.Step_Search.subtitle" , nil) }
		}
		public enum Step_SecureSharing {
			public static var title: String { OCLocalizedString("Onboarding.Step_SecureSharing.title" , nil) }
			public static var subtitle: String { OCLocalizedString("Onboarding.Step_SecureSharing.subtitle" , nil) }
		}
	}

	public enum Sidebar {
		public static var storageSpace: String { OCLocalizedString("Sidebar.storageSpace" , nil) }
		public static func used(_ a: String, of b: String) -> String { String(format: OCLocalizedString("Sidebar.usedFormat" , nil), a, b) }
		public static func inUse(_ a: String) -> String { String(format: OCLocalizedString("Sidebar.inUseFormat" , nil), a) }
		public static var unlimitedSpace: String { OCLocalizedString("Sidebar.unlimitedSpace" , nil) }
		public static var signOut: String { OCLocalizedString("Sidebar.signOut" , nil) }
	}

	public enum TabBar {
		public static var files: String { OCLocalizedString("TabBar.files", nil) }
		public static var search: String { OCLocalizedString("TabBar.search", nil) }
		public static var status: String { OCLocalizedString("TabBar.status", nil) }
		public static var offline: String { OCLocalizedString("TabBar.offline", nil) }
	}

	public enum Search {
		public enum Empty {
			public static var title: String { OCLocalizedString("Search.Empty.title", nil) }
		}
	}

	public enum Offline {
		public enum Empty {
			public static var title: String { OCLocalizedString("Offline.Empty.title", nil) }
			public static var subtitle: String { OCLocalizedString("Offline.Empty.subtitle", nil) }
		}
	}

	public enum ImageCropAction {
		public static var name: String { OCLocalizedString("ImageCropAction.name", nil) }

		public enum SaveAlert {
			public static var title: String { OCLocalizedString("ImageCropAction.SaveAlert.title", nil) }
			public static var overwrite: String { OCLocalizedString("ImageCropAction.SaveAlert.overwrite", nil) }
			public static var saveACopy: String { OCLocalizedString("ImageCropAction.SaveAlert.saveACopy", nil) }
			public static var discard: String { OCLocalizedString("ImageCropAction.SaveAlert.discard", nil) }
		}
	}

	public enum Auth {
		public enum Login {
			public static var loadingViewTitle: String { OCLocalizedString("Auth.Login.loadingViewTitle", nil) }
			public static var incorrectEmailPassword: String { OCLocalizedString("Auth.Login.incorrectEmailPassword", nil) }
			public static var invalidEmail: String { OCLocalizedString("Auth.Login.invalidEmail", nil) }
			public static var connectionError: String { OCLocalizedString("Auth.Login.connectionError", nil) }
			public static var notAllowedEmailError: String { OCLocalizedString("Auth.Login.notAllowedEmailError", nil) }

			public enum EmailField {
				public static var title: String { OCLocalizedString("Auth.Login.EmailField.title", nil) }
				public static var placeholder: String { OCLocalizedString("Auth.Login.EmailField.placeholder", nil) }
			}

			public enum PasswordField {
				public static var title: String { OCLocalizedString("Auth.Login.PasswordField.title", nil) }
				public static var placeholder: String { OCLocalizedString("Auth.Login.PasswordField.placeholder", nil) }
			}

			public enum DeviceDropdownField {
				public static var title: String { OCLocalizedString("Auth.Login.DeviceDropdownField.title", nil) }
				public static var placeholder: String { OCLocalizedString("Auth.Login.DeviceDropdownField.placeholder", nil) }
			}

			public static var loginButtonTitle: String { OCLocalizedString("Auth.Login.loginButtonTitle", nil) }
			public static var nextButtonTitle: String { OCLocalizedString("Auth.Login.nextButtonTitle", nil) }
			public static var resetPasswordButtonTitle: String { OCLocalizedString("Auth.Login.resetPasswordButtonTitle", nil) }
			public static var detectingDevices: String { OCLocalizedString("Auth.Login.detectingDevices", nil) }
			public static var noDeviceDetected: String { OCLocalizedString("Auth.Login.noDeviceDetected", nil) }
		}

		public enum UnableToConnect {
			public static var navbarTitle: String { OCLocalizedString("Auth.UnableToConnect.navbarTitle", nil) }

			public static var headerText: String { OCLocalizedString("Auth.UnableToConnect.headerText", nil) }
			public static var point1: String { OCLocalizedString("Auth.UnableToConnect.point1", nil) }
			public static var point2: String { OCLocalizedString("Auth.UnableToConnect.point2", nil) }
			public static var point3: String { OCLocalizedString("Auth.UnableToConnect.point3", nil) }
			public static var point4: String { OCLocalizedString("Auth.UnableToConnect.point4", nil) }
			public static var point5: String { OCLocalizedString("Auth.UnableToConnect.point5", nil) }
			public static var footerText: String { OCLocalizedString("Auth.UnableToConnect.footerText", nil) }
			public static var footerLinkText: String { OCLocalizedString("Auth.UnableToConnect.footerLinkText", nil) }
			public static var retryButtonTitle: String { OCLocalizedString("Auth.UnableToConnect.retryButtonTitle", nil) }
		}

		public enum UnableToDetect {
			public static var navbarTitle: String { OCLocalizedString("Auth.UnableToDetect.navbarTitle", nil) }

			public static var headerText: String { OCLocalizedString("Auth.UnableToDetect.headerText", nil) }
			public static var point1: String { OCLocalizedString("Auth.UnableToDetect.point1", nil) }
			public static var point2: String { OCLocalizedString("Auth.UnableToDetect.point2", nil) }
			public static var point3: String { OCLocalizedString("Auth.UnableToDetect.point3", nil) }
			public static var point4: String { OCLocalizedString("Auth.UnableToDetect.point4", nil) }
			public static var point5: String { OCLocalizedString("Auth.UnableToDetect.point5", nil) }
			public static var point6: String { OCLocalizedString("Auth.UnableToDetect.point6", nil) }
			public static var footerText: String { OCLocalizedString("Auth.UnableToDetect.footerText", nil) }
			public static var footerLinkText: String { OCLocalizedString("Auth.UnableToDetect.footerLinkText", nil) }
			public static var retryButtonTitle: String { OCLocalizedString("Auth.UnableToDetect.retryButtonTitle", nil) }
		}

		public enum CodeVerification {
			public static var title: String { OCLocalizedString("Auth.CodeVerification.title", nil) }
			public static var description: String { OCLocalizedString("Auth.CodeVerification.description", nil) }

			public static var allowAccessButtonTitle: String { OCLocalizedString("Auth.CodeVerification.allowAccessButtonTitle", nil) }
			public static var resendCodeButtonTitle: String { OCLocalizedString("Auth.CodeVerification.resendCodeButtonTitle", nil) }
			public static var skipButtonTitle: String { OCLocalizedString("Auth.CodeVerification.skipButtonTitle", nil) }

			public static var invalidCodeError: String { OCLocalizedString("Auth.CodeVerification.invalidCodeError", nil) }
			public static var codeExpiredError: String { OCLocalizedString("Auth.CodeVerification.codeExpiredError", nil) }
			public static var tooManyRequestsError: String { OCLocalizedString("Auth.CodeVerification.tooManyRequestsError", nil) }
			public static var connectionError: String { OCLocalizedString("Auth.CodeVerification.connectionError", nil) }
		}

		public enum Code500 {
			public static var title: String { OCLocalizedString("Auth.Code500.title", nil) }
			public static var description: String { OCLocalizedString("Auth.Code500.description", nil) }
			public static var cancelButtonTitle: String { OCLocalizedString("Auth.Code500.cancelButtonTitle", nil) }
			public static var retryButtonTitle: String { OCLocalizedString("Auth.Code500.retryButtonTitle", nil) }
		}
		public enum CodeUnknownEmail {
			public static var title: String { OCLocalizedString("Auth.CodeUnknownEmail.title", nil) }
			public static var description: String { OCLocalizedString("Auth.CodeUnknownEmail.description", nil) }
			public static var cancelButtonTitle: String { OCLocalizedString("Auth.CodeUnknownEmail.cancelButtonTitle", nil) }
		}

		public enum TooManyRequests {
			public static var title: String { OCLocalizedString("Auth.TooManyRequests.title", nil) }
			public static var description: String { OCLocalizedString("Auth.TooManyRequests.description", nil) }
			public static var cancelButtonTitle: String { OCLocalizedString("Auth.TooManyRequests.cancelButtonTitle", nil) }
		}

		public enum DevOptions {
			public static var title: String { OCLocalizedString("Auth.DevOptions.title", nil) }
			public static var deviceTextFieldTitle: String { OCLocalizedString("Auth.DevOptions.deviceTextFieldTitle", nil) }
			public static var deviceTextFieldInvalidURLError: String { OCLocalizedString("Auth.DevOptions.deviceTextFieldInvalidURLError", nil) }
			public static var settingsSwitchLabel: String { OCLocalizedString("Auth.DevOptions.settingsSwitchLabel", nil) }
		}
	}

	public enum Sharing {
		public static var sharingNotPossible: String { OCLocalizedString("Sharing.sharingNotPossible", nil) }
		public static var raNotAvilableDescription: String { OCLocalizedString("Sharing.raNotAvilableDescription", nil) }
		public static var publicNotAvilableDescription: String { OCLocalizedString("Sharing.publicNotAvilableDescription", nil) }
	}

	public enum TrustPrompt {
		public static var title: String { OCLocalizedString("TrustPrompt.title", nil) }
		public static var messageFormat: String { OCLocalizedString("TrustPrompt.messageFormat", nil) }
		public static var trust: String { OCLocalizedString("TrustPrompt.trust", nil) }
	}

	public enum Network {
		public static var findingNetwork: String { OCLocalizedString("Network.findingNetwork", nil) }
		public static var noInternet: String { OCLocalizedString("Network.noInternet", nil) }
	}

	public enum TagsList {
		public static var title: String { OCLocalizedString("TagsList.title", nil) }
		public static var empty: String { OCLocalizedString("TagsList.empty", nil) }
		public static var loadingError: String { OCLocalizedString("TagsList.loadingError", nil) }
		public static var errorOk: String { OCLocalizedString("TagsList.errorOk", nil) }
		public static var alreadyExists: String { OCLocalizedString("TagsList.alreadyExists", nil) }
		public enum Delete {
			public static var error: String { OCLocalizedString("TagsList.Delete.error", nil) }
			public static var title: String { OCLocalizedString("TagsList.Delete.title", nil) }
			public static var description: String { OCLocalizedString("TagsList.Delete.description", nil) }
			public static var cancel: String { OCLocalizedString("TagsList.Delete.cancel", nil) }
			public static var confirm: String { OCLocalizedString("TagsList.Delete.confirm", nil) }
		}
		public enum Create {
			public static var error: String { OCLocalizedString("TagsList.Create.error", nil) }
		}
		public enum Update {
			public static var error: String { OCLocalizedString("TagsList.Update.error", nil) }
		}
	}

	public enum TagManage {
		public static var title: String { OCLocalizedString("TagManage.title", nil) }
		public static var actionTitle: String { OCLocalizedString("TagManage.actionTitle", nil) }
		public static var selectTagPlaceholder: String { OCLocalizedString("TagManage.selectTagPlaceholder", nil) }
		public static var noTagsAvailableHint: String { OCLocalizedString("TagManage.noTagsAvailableHint", nil) }
		public static var addTagFormat: String { OCLocalizedString("TagManage.addTagFormat", nil) }
		public static var emptyFileMessage: String { OCLocalizedString("TagManage.emptyFileMessage", nil) }
		public static var showMoreFormat: String { OCLocalizedString("TagManage.showMoreFormat", nil) }
		public static var showLess: String { OCLocalizedString("TagManage.showLess", nil) }
		public static var assignFailed: String { OCLocalizedString("TagManage.assignFailed", nil) }
		public static var removeFailed: String { OCLocalizedString("TagManage.removeFailed", nil) }
		public static var loadingError: String { OCLocalizedString("TagManage.loadingError", nil) }
		public static var errorOk: String { OCLocalizedString("TagManage.errorOk", nil) }
		public static var createError: String { OCLocalizedString("TagManage.createError", nil) }
		public static var alreadyExists: String { OCLocalizedString("TagManage.alreadyExists", nil) }
	}

	public enum TagEdit {
		public static var done: String { OCLocalizedString("TagEdit.done", nil) }
		public static var cancel: String { OCLocalizedString("TagEdit.cancel", nil) }
		public static var add: String { OCLocalizedString("TagEdit.add", nil) }
		public static var edit: String { OCLocalizedString("TagEdit.edit", nil) }
		public static var addPlaceholder: String { OCLocalizedString("TagEdit.addPlaceholder", nil) }
		public static var editPlaceholder: String { OCLocalizedString("TagEdit.editPlaceholder", nil) }
		public static var nameTooLongError: String {
			String(format: OCLocalizedString("TagEdit.nameTooLong", nil), TagEdit.maxNameLength)
		}
		public static var invalidCharactersError: String {
			OCLocalizedString("TagEdit.invalidCharacters", nil)
		}
		public static let maxNameLength: Int = 30
		// Disallowed characters in tag names: control chars, path separators and other
		// punctuation/special symbols that have no place in a human-readable tag.
		public static let forbiddenCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|`~!@#$%^&()+={}[];,")
			.union(.controlCharacters)
			.union(.newlines)
	}
}
