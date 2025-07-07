//
//  Tab+Activity.swift
//  MullvadBrowser
//
//  Created by Benjamin Erhart on 26.11.19.
//  Copyright © 2012 - 2025, Tigas Ventures, LLC (Mike Tigas)
//
//  This file is part of Mullvad Browser. See LICENSE file for redistribution terms.
//

import Foundation
import MobileCoreServices
import UniformTypeIdentifiers
import LinkPresentation

extension Tab: UIActivityItemSource {

	enum Errors: Error {

		case iconLoadFailed
	}

	private var uti: UTType? {
		guard let id = try? downloadedFile?.resourceValues(forKeys: [.typeIdentifierKey]).typeIdentifier else {
			return nil
		}

		return UTType(id)
	}

	private var isImageOrAv: Bool {
		guard let uti = uti else {
			return false
		}

		return uti.conforms(to: .image) || uti.conforms(to: .audiovisualContent)
	}

	private var isDocument: Bool {
		guard let uti = uti else {
			return false
		}

		return uti.conforms(to: .data)
			&& !uti.conforms(to: .html)
			&& !uti.conforms(to: .xml)
	}



	func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
		if let file = downloadedFile,
			isImageOrAv || isDocument {
			return file
		}

		return url
	}

	func activityViewController(_ activityViewController: UIActivityViewController,
								itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {

		Log.debug(for: Self.self, "activityType=\(String(describing: activityType))")

		if let downloadedFile = downloadedFile,
			let activityType = activityType,
			(activityType == .print
				|| activityType == .markupAsPDF
				|| activityType == .mail
				|| activityType == .openInIBooks
				|| activityType == .airDrop
				|| activityType == .copyToPasteboard
				|| activityType == .saveToCameraRoll
				|| activityType.rawValue == "com.apple.DocumentManagerUICore.SaveToFiles" // iOS 14
				|| activityType.rawValue == "com.apple.CloudDocsUI.AddToiCloudDrive")
		{
			// Return local file URL -> The file will be loaded and shared from there
			// and it will use the correct file name.
			return downloadedFile
		}

		if activityType == .message && isImageOrAv {
			return downloadedFile
		}

		return url
	}

	func activityViewController(_ activityViewController: UIActivityViewController,
								subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
		return title
	}

	func activityViewController(_ activityViewController: UIActivityViewController,
								dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {

		return (uti ?? .url).identifier
	}

	func activityViewController(_ activityViewController: UIActivityViewController,
								thumbnailImageForActivityType activityType: UIActivity.ActivityType?,
								suggestedSize size: CGSize) -> UIImage? {

		UIGraphicsBeginImageContext(size)

		if let context = UIGraphicsGetCurrentContext() {
			if downloadedFile != nil {
				previewController?.view.layer.render(in: context)
			}
			else {
				webView?.layer.render(in: context)
			}
		}

		let thumbnail = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()

		return thumbnail
	}

	func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
		let metadata = LPLinkMetadata()
		metadata.originalURL = url
		metadata.url = url
		metadata.title = title

		let bookmark = Bookmark.all.first { $0.url?.host == url.host }

		if #available(iOS 16.0, *), let icon = bookmark?.iconUrl {
			metadata.iconProvider = .init(contentsOf: icon, contentType: .png, openInPlace: false,
										  coordinated: false, visibility: .all)
		}
		else {
			let iconProvider = NSItemProvider()
			iconProvider.registerObject(ofClass: UIImage.self, visibility: .all) { [weak self] completion in
				if let url = self?.url {
					Bookmark.icon(for: url) { image in
						if let image = image {
							completion(image, nil)
						}
						else {
							completion(nil, Errors.iconLoadFailed)
						}
					}
				}
				else {
					completion(nil, Errors.iconLoadFailed)
				}

				return nil
			}

			metadata.iconProvider = iconProvider
		}

		return metadata
	}
}
