//
//  Log.swift
//  OnionBrowser
//
//  Created by Benjamin Erhart on 27.02.25.
//

import Foundation
import OSLog

public class Log {

	private static var loggers = [String: Logger]()


	static func error(for class: AnyClass, _ message: String) {
		logger(for: `class`)?
#if DEBUG
			.error("\(message, privacy: .public)")
#else
			.error("\(message)")
#endif
	}

	static func debug(for class: AnyClass, _ message: String) {
		logger(for: `class`)?
#if DEBUG
			.debug("\(message, privacy: .public)")
#else
			.debug("\(message)")
#endif
	}

	static func log(for class: AnyClass, level: OSLogType = .default, _ message: String) {
		logger(for: `class`)?
#if DEBUG
			.log(level: level, "\(message, privacy: .public)")
#else
			.log(level: level, "\(message)")
#endif
	}


	private static func logger(for class: AnyClass) -> Logger? {
		let id = String(describing: `class`)

		if loggers[id] == nil {
			loggers[id] = Logger(subsystem: Bundle(for: `class`).bundleIdentifier ?? id, category: id)
		}

		return loggers[id]
	}
}
