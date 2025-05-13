//
//  FileManager+Helpers.swift
//  MullvadBrowser
//
//  Copyright © 2012 - 2025, Tigas Ventures, LLC (Mike Tigas)
//
//  This file is part of Mullvad Browser. See LICENSE file for redistribution terms.
//

import Foundation

public extension FileManager {

	var cacheDir: URL? {
		urls(for: .cachesDirectory, in: .userDomainMask).last
	}

	var docsDir: URL? {
		urls(for: .documentDirectory, in: .userDomainMask).last
	}


	func createSecureDirIfNotExists(at url: URL) throws {
		// Try to remove it, if it is *not* a directory.
		if fileExists(atPath: url.path) {
			if !((try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false) {
				try removeItem(at: url)
			}
		}

		// Try to create it, and all its intermediate directories, if it doesn't
		// exist. Create with secure permissions.
		if !fileExists(atPath: url.path) {
			try createDirectory(
				at: url, withIntermediateDirectories: true,
				attributes: [.posixPermissions: NSNumber(value: 0o700)])
		}
	}

	func sizeOfItem(atPath path: String) -> Int64? {
		return (try? attributesOfItem(atPath: path))?[.size] as? Int64
	}
}
