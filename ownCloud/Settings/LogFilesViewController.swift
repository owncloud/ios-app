//
//  LogFilesViewController.swift
//  ownCloud
//
//  Created by Michael Neuwert on 15.05.2019.
//  Copyright © 2019 ownCloud GmbH. All rights reserved.
//

/*
* Copyright (C) 2018, ownCloud GmbH.
*
* This code is covered by the GNU Public License Version 3.
*
* For distribution utilizing Apple mechanisms please see https://owncloud.org/contribute/iOS-license-exception/
* You should have received a copy of this license along with this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.en.html>.
*
*/

import UIKit
import CoreServices

import ownCloudSDK
import ownCloudApp
import ownCloudAppShared

class LogFileTableViewCell : ThemeTableViewCell {

	static let identifier = "LogFileTableViewCell"

	var shareAction : ((_ cell:UITableViewCell) -> Void)?

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

		let image = UIImage(named: "open-in")
		let shareButton = UIButton(type: .system)
		shareButton.setImage(image, for: .normal)
		shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
		shareButton.frame = CGRect(origin: CGPoint(x:0.0, y:0.0), size: image!.size)
		shareButton.accessibilityLabel = "Share".localized
		self.accessoryView = shareButton
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Actions
	@objc func shareButtonTapped() {
		shareAction?(self)
	}
}

extension OCLogFileRecord {
	func truncatedName() -> String? {
		if let nameRange: Range<String.Index> = name.range(of: #".*\.log"#, options: .regularExpression) {
			return "\(name[nameRange])"
		}
		return nil
	}
}

class LogFilesViewController : UITableViewController, UITableViewDragDelegate, Themeable {

	var logRecords = [OCLogFileRecord]()

	lazy var byteCounterFormatter: ByteCountFormatter = {
		let fmtr = ByteCountFormatter()
		fmtr.allowsNonnumericFormatting = true
		return fmtr
	}()

	lazy var dateFormatter: DateFormatter = {
		let fmtr = DateFormatter()
		fmtr.dateStyle = .medium
		fmtr.timeStyle = .medium
		return fmtr
	}()

	override init(style: UITableView.Style) {
		super.init(style: style)
		NotificationCenter.default.addObserver(self, selector: #selector(handleLogRotationNotification), name:NSNotification.Name.OCLogFileWriterLogRecordsChanged, object: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		fatalError("not implemented")
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		Theme.shared.register(client: self, applyImmediately: true)
		self.tableView.register(LogFileTableViewCell.self, forCellReuseIdentifier: LogFileTableViewCell.identifier)
		self.tableView.dragDelegate = self
		self.tableView.dragInteractionEnabled = true
		self.title = "Log Files".localized
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.populateLogFileList()

		let removeAllButtonItem = UIBarButtonItem(title: "Delete all".localized, style: .done, target: self, action: #selector(removeAllLogs))
		let flexibleSpaceButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

		self.toolbarItems = [flexibleSpaceButtonItem, removeAllButtonItem, flexibleSpaceButtonItem]
		self.navigationController?.setToolbarHidden(false, animated: false)
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.navigationController?.setToolbarHidden(true, animated: false)
	}

	deinit {
		NotificationCenter.default.removeObserver(self)
		Theme.shared.unregister(client: self)
	}

	// MARK: - Theme support

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		self.tableView.applyThemeCollection(collection)

		if event == .update {
			self.tableView.reloadData()
		}
	}

	// MARK: - Table view data source / delegate

	override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return logRecords.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: LogFileTableViewCell.identifier, for: indexPath) as? LogFileTableViewCell
		let logRecord = self.logRecords[indexPath.row]
		cell?.textLabel?.text = logRecord.truncatedName()
		if let date = logRecord.creationDate {
			cell?.detailTextLabel?.text = "\(self.dateFormatter.string(from: date)), \(self.byteCounterFormatter.string(fromByteCount: logRecord.size))"
		}

		cell?.shareAction = { [weak self] (cell) in
			if let indexPath = self?.tableView.indexPath(for: cell) {
				self?.shareLogRecord(at: indexPath, sender: cell)
			}
		}

		return cell!
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		let cell = tableView.cellForRow(at: indexPath)
		if let cell = cell {
			self.shareLogRecord(at: indexPath, sender: cell)
		}
	}

	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

		return [
			UITableViewRowAction(style: .destructive, title: "Delete".localized, handler: { [weak self] (_, indexPath) in
				self?.removeLogRecord(at: indexPath)
			})
		]
	}

	// MARK: - Table view drag & drop support
    	func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
		if DisplaySettings.shared.preventDraggingFiles {
			return [UIDragItem]()
		}
		
		var logURL : URL?
		var logName : String?
		
		provideLogURL(at: indexPath, makeNamedCopy: false) { (url, name, completionHandler) in
			logURL = url
			logName = name

			// Since we use false for makeNamedCopy, this should be safe
			completionHandler?()
		}
		
		if let logURL = logURL {
			let itemProvider = NSItemProvider()
			itemProvider.registerFileRepresentation(forTypeIdentifier: kUTTypeUTF8PlainText as String, fileOptions: [], visibility: .all, loadHandler: { (completionHandler) -> Progress? in
				completionHandler(logURL, true, nil)
				return nil
			})
			itemProvider.suggestedName = logName

			let dragItem = UIDragItem(itemProvider: itemProvider)
			
			return [dragItem]
		}
		
		return [UIDragItem]()
	}


	// MARK: - Private Helpers

	private func populateLogFileList() {
		guard let logFileWriter = OCLogger.shared.writer(withIdentifier: .writerFile) as? OCLogFileWriter else { return }
		OnMainThread {
			self.logRecords = logFileWriter.logRecords().sorted(by: { (record1, record2) in
				if let date1 = record1.creationDate, let date2 = record2.creationDate {
					return date1 > date2
				}
				return false
			})
			self.tableView.reloadData()
		}
	}
	
	private func provideLogURL(at indexPath: IndexPath, makeNamedCopy: Bool, completionHandler: (_ fileURL: URL?, _ name: String?, _ doneBlock: (()->Void)?) -> Void) {
		let logRecord = self.logRecords[indexPath.row]

		// Create a file name for sharing with format ownCloud_<date>_<time>.log.txt
		var time = ""
		if let creationDate = logRecord.creationDate {
			let delimiteresRegex = try? NSRegularExpression(pattern: "[/ ,:]", options: .caseInsensitive)
			let timestamp = self.dateFormatter.string(from: creationDate)
			time = delimiteresRegex?.stringByReplacingMatches(in: timestamp, options: .withoutAnchoringBounds, range: NSRange(location: 0, length: timestamp.count), withTemplate: "_") ?? ""

		}
		let shareableFileName = "ownCloud_" + time + ".log.txt"
		
		if makeNamedCopy {
			let shareableLogURL = FileManager.default.temporaryDirectory.appendingPathComponent(shareableFileName)

			do {
				if FileManager.default.fileExists(atPath: shareableLogURL.path) {
					try FileManager.default.removeItem(at: shareableLogURL)
				}

				try FileManager.default.copyItem(atPath: logRecord.url.path, toPath: shareableLogURL.path)
			} catch {
			}
		
			completionHandler(shareableLogURL, shareableFileName, {
				do {
					try FileManager.default.removeItem(at: shareableLogURL)
				} catch {
				}
			})
		} else {
			completionHandler(logRecord.url, shareableFileName, nil)
		}
	}

	private func shareLogRecord(at indexPath:IndexPath, sender: UITableViewCell) {
		provideLogURL(at: indexPath, makeNamedCopy: true) { (shareableLogURL, fileName, completionHandler) in
			guard let shareableLogURL = shareableLogURL else {
				completionHandler?()
				return
			}

			let shareViewController = UIActivityViewController(activityItems: [shareableLogURL], applicationActivities:nil)

			shareViewController.completionWithItemsHandler = { (_, _, _, _) in
				completionHandler?()
			}

			if UIDevice.current.isIpad {
				shareViewController.popoverPresentationController?.sourceView = sender
				shareViewController.popoverPresentationController?.sourceRect = sender.frame
			}

			self.present(shareViewController, animated: true, completion: nil)
		}
	}

	private func removeLogRecord(at indexPath:IndexPath) {

		let record = self.logRecords[indexPath.row]

		OCLogger.shared.pauseWriters(intermittentBlock: {
			if let logFileWriter = OCLogger.shared.writer(withIdentifier: .writerFile) as? OCLogFileWriter {
				logFileWriter.deleteLogRecord(record)
				OnMainThread {
					self.logRecords.remove(at: indexPath.row)
					self.tableView.deleteRows(at: [indexPath], with: .automatic)
					self.populateLogFileList()
				}
			}
		})
	}

	@objc private func removeAllLogs() {
		let alert = ThemedAlertController(with: "Delete all log files?".localized,
									  message: "This action can't be undone.".localized,
									  destructiveLabel: "Delete all".localized,
									  preferredStyle: .alert,
									  destructiveAction: {
			OCLogger.shared.pauseWriters(intermittentBlock: {
				if let logFileWriter = OCLogger.shared.writer(withIdentifier: .writerFile) as? OCLogFileWriter {
					logFileWriter.cleanUpLogs(true)
				}
			})
		})

		self.present(alert, animated: true, completion: nil)
	}

	@objc private func handleLogRotationNotification() {
		self.populateLogFileList()
	}
}
