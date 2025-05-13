//
//  Formatter.swift
//  MullvadBrowser
//
//  Created by Benjamin Erhart on 31.10.19.
//  Copyright © 2012 - 2025, Tigas Ventures, LLC (Mike Tigas)
//
//  This file is part of Mullvad Browser. See LICENSE file for redistribution terms.
//

import UIKit

class Formatter: NSObject {

	class func localize(_ value: Int) -> String {
		return NumberFormatter.localizedString(from: NSNumber(value: value), number: .none)
	}
}
