//
//  CALayer+Helpers.swift
//  MullvadBrowser
//
//  Created by alexey kosylo on 29/04/2022.
//  Copyright © 2012 - 2025, Tigas Ventures, LLC (Mike Tigas)
//
//  This file is part of Mullvad Browser. See LICENSE file for redistribution terms.
//

import UIKit

extension CALayer {

	func makeSnapshot(scale: CGFloat = UIScreen.main.scale) -> UIImage? {
		let format = UIGraphicsImageRendererFormat.default()
		format.scale = scale

		let renderer = UIGraphicsImageRenderer(size: frame.size, format: format)

		return renderer.image { [weak self] context in
			self?.render(in: context.cgContext)
		}
	}
}
