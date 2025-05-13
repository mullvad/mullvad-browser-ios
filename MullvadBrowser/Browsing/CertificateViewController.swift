//
//  CertificateViewController.swift
//  MullvadBrowser
//
//  Created by Benjamin Erhart on 21.01.20.
//  Copyright © 2012 - 2025, Tigas Ventures, LLC (Mike Tigas)
//
//  This file is part of Mullvad Browser. See LICENSE file for redistribution terms.
//

import UIKit

class CertificateViewController: UITableViewController {

	var certificate: TlsCertificate?

	private var sections = [String]()

	private var data = [[[String: String?]]]()

	private let dateFormatter: DateFormatter = {
		let df = DateFormatter()
		df.timeZone = NSTimeZone.default
		df.dateStyle = .medium
		df.timeStyle = .medium

		return df
	}()


	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.leftBarButtonItem = UIBarButtonItem(
			barButtonSystemItem: .done, target: self, action: #selector(done))

		tableView.allowsSelection = false

		sections.append(NSLocalizedString("Certificate Information", comment: ""))

		var group: [[String: String?]] = [
			kv(NSLocalizedString("Version", comment: ""), certificate?.version.description),
			kv(NSLocalizedString("Serial Number", comment: ""), certificate?.serialNumber),
			kv(NSLocalizedString("Signature Algorithm", comment: ""), certificate?.signatureAlgorithm,
			   certificate?.hasWeakSignatureAlgorithm ?? false ? NSLocalizedString("Error", comment: "") : nil),
		]

		if certificate?.isEv ?? false {
			group.append(kv(NSLocalizedString("Extended Validation: Organization", comment: ""),
							certificate?.evOrgName, "Ok"))
		}

		data.append(group)

		if let subject = certificate?.subject {
			sections.append(NSLocalizedString("Issued To", comment: ""))

			data.append(subject.getAll().map({ kv($0.label, $0.value) }))
		}

		sections.append(NSLocalizedString("Period of Validity", comment: ""))

		data.append([
			kv(NSLocalizedString("Begins On", comment: ""),
			   dateFormatter.string(from: certificate?.validityNotBefore ?? Date(timeIntervalSince1970: 0))),
			kv(NSLocalizedString("Expires After", comment: ""),
			   dateFormatter.string(from: certificate?.validityNotAfter ?? Date(timeIntervalSince1970: 0))),
		])

		if let issuer = certificate?.issuer {
			sections.append(NSLocalizedString("Issued By", comment: ""))

			data.append(issuer.getAll().map({ kv($0.label, $0.value) }))
		}
	}

	// MARK: - Table view data source

	override func numberOfSections(in tableView: UITableView) -> Int {
		return data.count
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete implementation, return the number of rows
		return data[section].count
	}

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return sections[section]
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "info") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "info")

		let d = data[indexPath.section][indexPath.row]

		cell.textLabel?.text = d["k"] as? String
		cell.detailTextLabel?.text = d["v"] as? String

		if let colorO = d["c"], let color = colorO {
			cell.detailTextLabel?.textColor = UIColor(named: color)
		}
		else {
			cell.detailTextLabel?.textColor = nil
		}

		return cell
	}


	// MARK: Actions

	@objc
	func done() {
		dismiss(animated: true)
	}


	// MARK: Private Methods

	private func kv(_ key: String?, _ value: String?, _ color: String? = nil) -> [String: String?] {
		if color != nil {
			return ["k": key, "v": value, "c": color]
		}

		return ["k": key, "v": value]
	}
}
