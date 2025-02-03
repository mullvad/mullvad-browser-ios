//
//  BlocklistViewController.swift
//  AnyoneBrowser
//
//  Created by Benjamin Erhart on 29.01.25.
//  Copyright © 2025 Anyone. All rights reserved.
//

import UIKit

class BlocklistViewController: UITableViewController, UISearchResultsUpdating {

	private var hostsInUse = [String]()
	private var hostsAll = [String]()
	private var hostsFiltered = [String]()

	private var filtered: Bool {
		navigationItem.searchController?.isActive ?? false && !(navigationItem.searchController?.searchBar.text?.isEmpty ?? true)
	}

	init() {
		super.init(style: .grouped)
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		let sc = UISearchController(searchResultsController: nil)
		sc.searchResultsUpdater = self
		sc.obscuresBackgroundDuringPresentation = false

		definesPresentationContext = true
		navigationItem.searchController = sc

		hostsInUse = AppDelegate.shared?.browsingUis
			.compactMap({ $0.currentTab })
			.flatMap({ $0.applicableUrlBlockerRules }) ?? []

		hostsAll = UrlBlocker.shared.hosts

		navigationItem.title = NSLocalizedString("Blocked 3rd-Party Hosts", comment: "")
	}


	// MARK: UITableViewDataSource

	override func numberOfSections(in tableView: UITableView) -> Int {
		2
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		hosts(for: section).count
	}

	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if section == 0 {
			return NSLocalizedString("Rules in use on current page", comment: "")
		}

		return NSLocalizedString("All rules", comment: "")
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "rule") ?? .init(style: .subtitle, reuseIdentifier: "rule")
		cell.selectionStyle = .none

		let host = hosts(for: indexPath.section)[indexPath.row]

		cell.textLabel?.text = host

		let reason = UrlBlocker.shared.isDisabled(host: host)
		let detail = UrlBlocker.shared.description(for: host)

		if let reason = reason {
			cell.textLabel?.textColor = .systemRed
			cell.detailTextLabel?.textColor = .systemRed

			if let detail = detail, !detail.isEmpty {
				cell.detailTextLabel?.text = String(format: NSLocalizedString("%1$@ (Disabled: %2$@)", comment: ""), detail, reason)
			}
			else {
				cell.detailTextLabel?.text = String(format: NSLocalizedString("Disabled: %@", comment: ""), reason)
			}
		}
		else {
			cell.textLabel?.textColor = .label
			cell.detailTextLabel?.textColor = .secondaryLabel

			cell.detailTextLabel?.text = detail
		}

		return cell
	}

	override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		true
	}

	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			toggle(hosts(for: indexPath.section)[indexPath.row])
			tableView.reloadRows(at: [indexPath], with: .automatic)
		}
	}

	override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
		if UrlBlocker.shared.isDisabled(host: hosts(for: indexPath.section)[indexPath.row]) != nil {
			return NSLocalizedString("Enable", comment: "")
		}

		return NSLocalizedString("Disable", comment: "")
	}


	// MARK: UISearchResultsUpdating

	func updateSearchResults(for searchController: UISearchController) {
		if let search = searchController.searchBar.text, !search.isEmpty {
			hostsFiltered = hostsAll.filter({ $0.localizedCaseInsensitiveContains(search) })
		}
		else {
			hostsFiltered.removeAll()
		}

		tableView.reloadSections([1], with: .automatic)
	}


	// MARK: Private Methods

	private func hosts(for section: Int) -> [String] {
		if section == 0 {
			return hostsInUse
		}

		if filtered {
			return hostsFiltered
		}

		return hostsAll
	}

	private func toggle(_ host: String) {
		if UrlBlocker.shared.isDisabled(host: host) != nil {
			UrlBlocker.shared.enable(host: host)
		}
		else {
			UrlBlocker.shared.disable(host: host, with: NSLocalizedString("User disabled", comment: ""))
		}
	}
}
