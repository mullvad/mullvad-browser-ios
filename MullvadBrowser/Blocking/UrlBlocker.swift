//
//  UrlBlocker.swift
//  AnyoneBrowser
//
//  Created by Benjamin Erhart on 30.01.25.
//  Copyright © 2025 Anyone. All rights reserved.
//

import Foundation

@objcMembers
@objc(URLBlocker)
class UrlBlocker: NSObject {

	static let shared = UrlBlocker()

	static let updateUrl = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?
		.appendingPathComponent("blocklist.txt")


	private(set) var hosts = [String]()

	private(set) var title = "HaGeZi's Light DNS Blocklist"

	private(set) var desc = "Hand brush - Cleans the Internet and protects your privacy! Blocks Ads, Tracking, Metrics and some Badware."

	private(set) var modified = "–"


	private static let disabledUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last?
		.appendingPathComponent("url_blocker_disabled.plist")


	private var disabled = [String: String]()

	private lazy var ruleCache: NSCache<NSString, NSString> = {
		let cache = NSCache<NSString, NSString>()
		cache.countLimit = 128

		return cache
	}()

	private lazy var titleRegex = try? NSRegularExpression(pattern: "^#\\s*Title:\\s*(.+)$", options: .caseInsensitive)
	private lazy var descRegex = try? NSRegularExpression(pattern: "^#\\s*Description:\\s*(.+)$", options: .caseInsensitive)
	private lazy var modifiedRegex = try? NSRegularExpression(pattern: "^#\\s*Last\\s+modified:\\s*(.+)$", options: .caseInsensitive)


	private override init() {
		super.init()

		reload()

		if let disabledUrl = Self.disabledUrl, disabledUrl.exists {
			do {
				let data = try Data(contentsOf: disabledUrl)

				disabled = try PropertyListDecoder().decode([String: String].self, from: data)
			}
			catch {
				assertionFailure(error.localizedDescription)
			}
		}
	}


	// MARK: Public Methods

	func reload() {
		var blocklist = ""

		if let updateUrl = Self.updateUrl, updateUrl.exists {
			blocklist = (try? String(contentsOf: updateUrl, encoding: .utf8)) ?? ""
		}
		else if let url = Bundle.main.url(forResource: "light-onlydomains", withExtension: "txt") {
			do {
				blocklist = try String(contentsOf: url, encoding: .utf8)
			}
			catch {
				assertionFailure("light-onlydomains.txt file could not be found!")

				// Injected for testing.
				blocklist = "twitter.com"
			}
		}

		ruleCache.removeAllObjects()

		hosts.removeAll()

		for line in blocklist.split(whereSeparator: { $0.isNewline }) {
			guard !line.hasPrefix("#") else {
				let line = String(line)
				let range = NSRange(line.startIndex ..< line.endIndex, in: line)

				if let match = titleRegex?.firstMatch(in: line, range: range),
				   match.numberOfRanges > 1,
				   let range = Range(match.range(at: 1), in: line)
				{
					title = String(line[range])
				}
				else if let match = descRegex?.firstMatch(in: line, range: range),
				   match.numberOfRanges > 1,
				   let range = Range(match.range(at: 1), in: line)
				{
					desc = String(line[range])
				}
				else if let match = modifiedRegex?.firstMatch(in: line, range: range),
				   match.numberOfRanges > 1,
				   let range = Range(match.range(at: 1), in: line)
				{
					modified = String(line[range])
				}

				continue
			}

			hosts.append(String(line))
		}

		hosts.sort(using: .localizedStandard)
	}

	func blockRule(for url: URL, withMain mainUrl: URL? = nil) -> String? {
		guard Settings.enableUrlBlocker else {
			return nil
		}

		let rule = blockRule(for: url)

		if let rule = rule, let mainUrl = mainUrl {
			// If this same rule would have blocked our main URL, allow it,
			// since the user is probably viewing this site and this isn't a sneaky tracker.
			if rule == blockRule(for: mainUrl) {
				return nil
			}
		}

		return rule
	}

	func isDisabled(host: String) -> String? {
		disabled[host]
	}

	func disable(host: String, with reason: String) {
		disabled[host] = reason
		store()

		ruleCache.removeObject(forKey: host as NSString)
	}

	func enable(host: String) {
		disabled.removeValue(forKey: host)
		store()

		ruleCache.removeObject(forKey: host as NSString)
	}


	// MARK: Private Methods

	private func store() {
		guard let disabledUrl = Self.disabledUrl else {
			assertionFailure("url_blocker_disabled.plist file URL could not be constructed!")
			return
		}

		do {
			let data = try PropertyListEncoder().encode(disabled)

			try data.write(to: disabledUrl)
		}
		catch {
			assertionFailure(error.localizedDescription)
		}
	}

	private func blockRule(for url: URL) -> String? {
		guard let host = url.host?.lowercased() else {
			return nil
		}

		if let rule = ruleCache.object(forKey: host as NSString) as String? {
			return rule.isEmpty ? nil : rule
		}

		var rule = ""

		if hosts.firstIndex(of: host) != nil {
			rule = host
		}
		else {
			// now for x.y.z.example.com, try *.y.z.example.com, *.z.example.com, *.example.com, etc.
			let p = host.components(separatedBy: ".")

			if p.count > 2 {
				for i in 1 ..< p.count - 1 {
					let domain = p[i ..< p.count].joined(separator: ".")

					if hosts.firstIndex(of: domain) != nil {
						rule = domain
						break
					}
				}
			}
		}

		if rule.isEmpty || disabled[rule] != nil {
			ruleCache.setObject("", forKey: host as NSString)

			return nil
		}

		ruleCache.setObject(rule as NSString, forKey: host as NSString)

		return rule
	}
}
