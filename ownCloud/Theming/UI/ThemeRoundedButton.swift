//
//  ThemeRoundedButton.swift
//  ownCloud
//
//  Created by Matthias Hühne on 28.01.19.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
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

class ThemeRoundedButton: ThemeButton {

    override init(frame: CGRect) {
        super.init(frame: frame)
        styleButton()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        styleButton()
    }

    private func styleButton() {
        if self.frame.size.height < self.frame.size.width {
            self.layer.cornerRadius = round(self.frame.size.height / 2)
        } else {
            self.layer.cornerRadius = round(self.frame.size.width / 2)
        }
    }

}
