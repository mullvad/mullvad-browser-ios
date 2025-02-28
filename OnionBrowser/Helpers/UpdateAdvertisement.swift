//
//  UpdateAdvertisement.swift
//  OnionBrowser
//
//  Created by Benjamin Erhart on 28.02.25.
//  Copyright © 2025 Tigas Ventures, LLC (Mike Tigas). All rights reserved.
//

import UIKit

class UpdateAdvertisement {
	
	class func lockdownMode(_ vc: BrowsingViewController) {
		guard !Settings.updateAdvertiseLockdownMode else {
			return
		}

		Settings.updateAdvertiseLockdownMode = true

		AlertHelper.present(
			vc,
			message: String(
				format: NSLocalizedString("%1$@ now selectively supports iOS' %2$@! (From iOS 16 onwards.)%3$@Gold and silver security levels will have this set by default. Your settings won't change automatically, though.%3$@Visit the '%4$@' page to update your default security level!%3$@P.S.: You might also want to have a look at the new '%5$@' feature.",
										  comment: "1. placeholder is 'Onion Browser', 2. is translated 'Lockdown Mode', 3. is two line breaks, 4. is translated 'Default Security', 5. is translated 'Block Insecure HTTP Requests'."),
				Bundle.main.displayName,
				NSLocalizedString("Lockdown Mode", comment: ""),
				"\n\n",
				NSLocalizedString("Default Security", comment: ""),
				NSLocalizedString("Block Insecure HTTP Requests", comment: "")
			),
			title: NSLocalizedString("New Security Features", comment: ""),
			actions: [
				AlertHelper.cancelAction(),
				AlertHelper.defaultAction(NSLocalizedString("Default Security", comment: "")) { _ in
					(vc.showSettings().topViewController as? SettingsViewController)?
						.showDefaultSecurity()
				}
			])
	}
}
