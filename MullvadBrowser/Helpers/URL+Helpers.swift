//
//  URL+Helpers.swift
//  MullvadBrowser
//
//  Created by Benjamin Erhart on 21.11.19.
//  Copyright © 2012 - 2025, Tigas Ventures, LLC (Mike Tigas)
//
//  This file is part of Mullvad Browser. See LICENSE file for redistribution terms.
//

import Foundation

extension URL {

	static let blank = URL(string: "about:blank")!

	static let aboutMullvadBrowser = URL(string: "about:mullvad-browser")!
	static let credits = Bundle.main.url(forResource: "credits", withExtension: "html")!

	static let aboutSecurityLevels = URL(string: "about:security-levels")!
	static let securityLevels = Bundle.main.url(forResource: "security-levels", withExtension: "html")!

	static let start = FileManager.default.cacheDir!.appendingPathComponent("start.html")

	var withFixedScheme: URL? {
		switch scheme?.lowercased() {
		case "onionhttp":
			var urlc = URLComponents(url: self, resolvingAgainstBaseURL: true)
			urlc?.scheme = "http"

			return urlc?.url

		case "onionhttps":
			var urlc = URLComponents(url: self, resolvingAgainstBaseURL: true)
			urlc?.scheme = "https"

			return urlc?.url

		default:
			return self
		}
	}

	var real: URL {
		switch self {
		case URL.aboutMullvadBrowser:
			return URL.credits

		case URL.aboutSecurityLevels:
			return URL.securityLevels

		default:
			return self
		}
	}

	var clean: URL? {
		switch self {
		case URL.credits:
			return URL.aboutMullvadBrowser

		case URL.securityLevels:
			return URL.aboutSecurityLevels

		case URL.start:
			return nil

		default:
			return self
		}
	}

	var isSpecial: Bool {
		switch scheme?.lowercased() {
		case "http", "https", "onionhttp", "onionhttps":
			break

		default:
			return true
		}

		switch self {
		case URL.blank, URL.aboutMullvadBrowser, URL.credits, URL.aboutSecurityLevels, URL.securityLevels, URL.start:
			return true

		default:
			return false
		}
	}

	var isSearchable: Bool {
		switch self {
		case URL.blank, URL.start:
			return false

		default:
			return true
		}
	}

	var isHttp: Bool {
		["http", "onionhttp"].contains(scheme?.lowercased())
	}

	var isHttps: Bool {
		["https", "onionhttps"].contains(scheme?.lowercased())
	}

	var isOnion: Bool {
		host?.lowercased().hasSuffix(".onion") ?? false
	}

	var exists: Bool {
		(try? self.checkResourceIsReachable()) ?? false
	}
}

@objc
extension NSURL {

	var withFixedScheme: NSURL? {
		return (self as URL).withFixedScheme as NSURL?
	}
}
