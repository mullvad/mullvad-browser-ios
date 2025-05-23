//
//  Tab+WKNavigationDelegate.swift
//  MullvadBrowser
//
//  Created by Benjamin Erhart on 27.07.22.
//  Copyright © 2012 - 2025, Tigas Ventures, LLC (Mike Tigas)
//
//  This file is part of Mullvad Browser. See LICENSE file for redistribution terms.
//

@preconcurrency import WebKit

extension Tab: WKNavigationDelegate {

	private static let universalLinksWorkaroundKey = "yayprivacy"


	func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
				 preferences: WKWebpagePreferences,
				 decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void)
	{
		guard let url = navigationAction.request.url else {
			return decisionHandler(.cancel, preferences)
		}

		let hs = HostSettings.for(url.host)

		if hs.blockInsecureHttp && url.isHttp {
			return decisionHandler(.cancel, preferences)
		}

		if let rule = UrlBlocker.shared.blockRule(for: url, withMain: self.url) {
			applicableUrlBlockerRules.insert(rule)

			return decisionHandler(.cancel, preferences)
		}

		let navigationType = navigationAction.navigationType

		// Try to prevent universal links from triggering by refusing the initial request and starting a new one.
		let iframe = url.absoluteString != navigationAction.request.mainDocumentURL?.absoluteString

		if hs.universalLinkProtection {
			if iframe {
				Log.debug(for: Self.self, "[Tab \(index)] not doing universal link workaround for iframe \(url).")
			}
			else if navigationType == .backForward {
				Log.debug(for: Self.self, "[Tab \(index)] not doing universal link workaround for back/forward navigation to \(url).")
			}
			else if navigationType == .formSubmitted {
				Log.debug(for: Self.self, "[Tab \(index)] not doing universal link workaround for form submission to \(url).")
			}
			else if (url.isHttp || url.isHttps)
						&& (URLProtocol.property(forKey: Tab.universalLinksWorkaroundKey, in: navigationAction.request) == nil)
			{
				if let tr = navigationAction.request as? NSMutableURLRequest {
					URLProtocol.setProperty(true, forKey: Tab.universalLinksWorkaroundKey, in: tr)

					Log.debug(for: Self.self, "[Tab \(index)] doing universal link workaround for \(url).")

					load(tr as URLRequest)

					return decisionHandler(.cancel, preferences)
				}
			}
		}
		else {
			Log.debug(for: Self.self, "[Tab \(index)] not doing universal link workaround for \(url) due to HostSettings.")
		}

		if !iframe {
			reset(navigationAction.request.mainDocumentURL)
		}

		preferences.allowsContentJavaScript = hs.javaScript

		if #available(iOS 16.0, *) {
#if DEBUG
			// There is no web-browser entitlement in debugging, and without that,
			// *disabling* lockdown mode is disallowed and we would crash here.
			// Hence, only try to enable it, if it's *not* enabled, yet, but it should.
			if !preferences.isLockdownModeEnabled && hs.lockdownMode {
				preferences.isLockdownModeEnabled = true
			}
#else
			preferences.isLockdownModeEnabled = hs.lockdownMode
#endif
		}

		if navigationAction.shouldPerformDownload {
			decisionHandler(.download, preferences)
		}
		else {
			cancelDownload()

			decisionHandler(.allow, preferences)
		}
	}

	func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
				 decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void)
	{
		if navigationResponse.canShowMIMEType {
			decisionHandler(.allow)
		}
		else {
			decisionHandler(.download)
		}
	}

	func webView(_ webView: WKWebView, didCommit navigation: WKNavigation?) {
		url = webView.url ?? URL.start

		tabDelegate?.updateChrome()
	}

	func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) {
		download.delegate = self
	}

	func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
		download.delegate = self
	}

	func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
		// If we have JavaScript blocked, these will be empty.
		stringByEvaluatingJavaScript(from: "window.location.href") { [weak self] (finalUrl) in
			var finalUrl = finalUrl

			if finalUrl?.isEmpty ?? true {
				finalUrl = webView.url?.absoluteString
			}

			self?.url = URL(string: finalUrl ?? URL.start.absoluteString) ?? URL.start

			if !(self?.skipHistory ?? true) {
				while self?.history.count ?? 0 > Tab.historySize {
					self?.history.remove(at: 0)
				}

				if self?.history.isEmpty ?? true || self?.history.last?.url.absoluteString != finalUrl,
				   let cleanUrl = self?.url.clean
				{
					self?.history.append(HistoryViewController.Item(url: cleanUrl, title: self?.title))
				}
			}

			self?.skipHistory = false
		}
	}

	func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {
		handle(error: error, webView, navigation)
	}

	func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation?, withError error: Error) {
		handle(error: error, webView, navigation)
	}

	func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge,
				 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
	{
		handle(challenge: challenge, completionHandler)
	}

	func handle(challenge: URLAuthenticationChallenge, _ completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
		let space = challenge.protectionSpace

		switch space.authenticationMethod {
		case NSURLAuthenticationMethodServerTrust:
			if let serverTrust = space.serverTrust,
			   HostSettings.for(space.host).ignoreTlsErrors
			{
				completionHandler(.useCredential, URLCredential(trust: serverTrust))
			}
			else {
				completionHandler(.performDefaultHandling, nil)
			}

			if let trust = space.serverTrust {
				if url.host == space.host {
					DispatchQueue.global(qos: .userInitiated).async { [weak self] in
						self?.tlsCertificate = TlsCertificate.load(trust: trust)
					}
				}
			}

		case NSURLAuthenticationMethodHTTPBasic, NSURLAuthenticationMethodHTTPDigest:
			let storage = URLCredentialStorage.shared

			// If we have existing credentials for this realm, try them first.
			if challenge.previousFailureCount < 1,
				let credential = storage.credentials(for: space)?.first?.value
			{
				completionHandler(.useCredential, credential)
			}
			else {
				let alert = AlertHelper.build(
					message: (space.realm?.isEmpty ?? true) ? space.host : "\(space.host): \"\(space.realm!)\"",
					title: NSLocalizedString("Authentication Required", comment: ""),
					actions: [AlertHelper.cancelAction { _ in
						completionHandler(.rejectProtectionSpace, nil)
					}])

				AlertHelper.addTextField(alert, placeholder:
					NSLocalizedString("Username", comment: ""))

				AlertHelper.addPasswordField(alert, placeholder:
					NSLocalizedString("Password", comment: ""))

				alert.addAction(AlertHelper.defaultAction(NSLocalizedString("Log In", comment: "")) { _ in
					// We only want one set of credentials per protectionSpace.
					// In case we stored incorrect credentials on the previous
					// login attempt, purge stored credentials for the
					// protectionSpace before storing new ones.
					for c in storage.credentials(for: space) ?? [:] {
						storage.remove(c.value, for: space)
					}

					let textFields = alert.textFields

					let credential = URLCredential(user: textFields?.first?.text ?? "",
												   password: textFields?.last?.text ?? "",
												   persistence: .forSession)

					storage.set(credential, for: space)

					completionHandler(.useCredential, credential)
				})

				DispatchQueue.main.async { [weak self] in
					guard self?.tabDelegate?.present(alert, nil) ?? false else {
						return completionHandler(.rejectProtectionSpace, nil)
					}
				}
			}

		default:
			completionHandler(.performDefaultHandling, nil)
		}
	}

	func webView(_ webView: WKWebView, authenticationChallenge challenge: URLAuthenticationChallenge,
				 shouldAllowDeprecatedTLS decisionHandler: @escaping (Bool) -> Void)
	{
		let space = challenge.protectionSpace

		guard space.authenticationMethod == NSURLAuthenticationMethodServerTrust
		else {
			return decisionHandler(false)
		}

		if HostSettings.for(space.host).ignoreTlsErrors {
			return decisionHandler(true)
		}

		let msg = NSLocalizedString("The encryption method for this server is outdated.", comment: "")
			+ "\n\n"
			+ String(
				format: NSLocalizedString(
					"You might be connecting to a server that is pretending to be \"%@\" which could put your confidential information at risk.",
					comment: "Placeholder is server domain"),
				space.host)

		let alert = AlertHelper.build(message: msg, actions: [
			AlertHelper.defaultAction() { _ in
				decisionHandler(false)
			},
			AlertHelper.destructiveAction(NSLocalizedString("Ignore for this host", comment: "")) { _ in
				let hs = HostSettings.for(space.host)
				hs.ignoreTlsErrors = true
				hs.save().store()

				decisionHandler(true)
			}
		])

		guard tabDelegate?.present(alert, nil) ?? false else {
			return decisionHandler(false)
		}
	}


	// MARK: Private Methods

	/**
	 TLS testing site: https://badssl.com/
	 */
	private func handle(error: Error, _ webView: WKWebView, _ navigation: WKNavigation?) {
		var failedUrl = url

		if let url = webView.url {
			self.url = url
			self.progress = 1
		}

		let error = error as NSError

		if error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
			return
		}

		// "The operation couldn't be completed. (Cocoa error 3072.)" - useless
		if error.domain == NSCocoaErrorDomain && error.code == NSUserCancelledError {
			return
		}

		// "Frame load interrupted" - not very helpful.
		if error.domain == "WebKitErrorDomain" && error.code == 102 {
			return
		}

		var isTLSError = false
		var msg = error.localizedDescription

		// https://opensource.apple.com/source/libsecurity_ssl/libsecurity_ssl-36800/lib/SecureTransport.h
		if error.domain == NSOSStatusErrorDomain {
			switch (error.code) {
			case Int(errSSLProtocol): /* -9800 */
				msg = NSLocalizedString("TLS protocol error", comment: "")
				isTLSError = true

			case Int(errSSLNegotiation): /* -9801 */
				msg = NSLocalizedString("TLS handshake failed", comment: "")
				isTLSError = true

			case Int(errSSLXCertChainInvalid): /* -9807 */
				msg = NSLocalizedString("TLS certificate chain verification error (self-signed certificate?)", comment: "")
				isTLSError = true

			case -1202:
				isTLSError = true

			default:
				break
			}
		}

		if error.domain == NSURLErrorDomain && error.code == -1202 {
			isTLSError = true
		}

		if !isTLSError {
			msg += "\n(code: \(error.code), domain: \(error.domain))"
		}

		// Get the URL of the *failed* request from the error, in case that one has a different opinion.
		if let u = error.userInfo[NSURLErrorFailingURLErrorKey] as? String,
		   let u = URL(string: u)
		{
			failedUrl = u
		}

		msg += "\n\n\(failedUrl.absoluteString)"

		Log.error(for: Self.self, "[Tab \(index)] showing error dialog: \(msg) (\(error)")

		let alert = AlertHelper.build(message: msg)

		if isTLSError, let host = failedUrl.host {
			alert.addAction(AlertHelper.destructiveAction(
				NSLocalizedString("Ignore for this host", comment: ""),
				handler: { _ in
					let hs = HostSettings.for(host)
					hs.ignoreTlsErrors = true
					hs.save().store()

					// Retry the failed request.
					self.load(failedUrl)
				}))
		}

		tabDelegate?.present(alert, nil)

		self.webView(webView, didFinish: navigation)
	}
}
