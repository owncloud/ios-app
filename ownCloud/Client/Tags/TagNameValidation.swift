//
//  TagNameValidation.swift
//  ownCloud
//
//  Copyright © 2025 ownCloud GmbH. All rights reserved.
//

import ownCloudAppShared

enum TagNameValidation {
	static func validationError(for name: String) -> String? {
		if name.count > HCL10n.TagEdit.maxNameLength {
			return HCL10n.TagEdit.nameTooLongError
		}
		if name.rangeOfCharacter(from: HCL10n.TagEdit.forbiddenCharacters) != nil {
			return HCL10n.TagEdit.invalidCharactersError
		}
		return nil
	}
}
