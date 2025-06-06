//
//  Thread+Helpers.swift
//  MullvadBrowser
//
//  Created by Benjamin Erhart on 25.10.23.
//  Copyright © 2012 - 2025, Tigas Ventures, LLC (Mike Tigas)
//
//  This file is part of Mullvad Browser. See LICENSE file for redistribution terms.
//

import Foundation

extension Thread {

	class func performOnMain(async: Bool = false, _ block: @escaping () -> Void) {
		if isMainThread {
			block()
		}
		else {
			if async {
				DispatchQueue.main.async(execute: block)
			}
			else {
				DispatchQueue.main.sync(execute: block)
			}
		}
	}
}
