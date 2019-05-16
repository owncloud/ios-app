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
import ownCloudSDK

class LogFileTableViewCell : ThemeTableViewCell {

	static let identifier = "LogFileTableViewCell"

	var shareAction : ((_ cell:UITableViewCell) -> Void)?

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)

		let shareButton = UIButton(type: .system)
		shareButton.setImage(UIImage(named: "open-in"), for: .normal)
		shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
		shareButton.frame = CGRect(origin: CGPoint(x:0.0, y:0.0), size: shareButton.imageView!.image!.size)
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

class LogFilesViewController : UITableViewController, Themeable {

	struct LogEntry {
		var name:String?
		var size:Int64?
		var creationDate:Date?

		func truncatedName() -> String? {
			if let name = name {
				if let nameRange: Range<String.Index> = name.range(of: #".*\.log"#, options: .regularExpression) {
					return "\(name[nameRange])"
				}
			}
			return nil
		}
	}

	var logFileEntries = [LogEntry]()

	lazy var byteCounterFormatter: ByteCountFormatter = {
		let fmtr = ByteCountFormatter()
		fmtr.allowsNonnumericFormatting = true
		return fmtr
	}()

	lazy var dateFormatter: DateFormatter = {
		let fmtr = DateFormatter()
		fmtr.dateStyle = .short
		fmtr.timeStyle = .medium
		return fmtr
	}()

	override func viewDidLoad() {
		super.viewDidLoad()
		Theme.shared.register(client: self, applyImmediately: true)
		self.tableView.register(LogFileTableViewCell.self, forCellReuseIdentifier: LogFileTableViewCell.identifier)
		self.title = "Log Files".localized
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		OCLogger.shared.pause()
		self.populateLogFileList()

		let removeAllButtonItem = UIBarButtonItem(title: "Delete all".localized, style: .done, target: self, action: #selector(removeAllLogs))
		let flexibleSpaceButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

		self.toolbarItems = [flexibleSpaceButtonItem, removeAllButtonItem, flexibleSpaceButtonItem]
		self.navigationController?.setToolbarHidden(false, animated: false)
	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.navigationController?.setToolbarHidden(true, animated: false)
		OCLogger.shared.resume()
	}

	deinit {
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
		return logFileEntries.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: LogFileTableViewCell.identifier, for: indexPath) as? LogFileTableViewCell
		let logEntry = self.logFileEntries[indexPath.row]
		cell?.textLabel?.text = logEntry.truncatedName()
		if let date = logEntry.creationDate, let size = logEntry.size {
			cell?.detailTextLabel?.text = "\(self.dateFormatter.string(from: date)), \(self.byteCounterFormatter.string(fromByteCount: size))"
		}

		cell?.shareAction = { [weak self] (cell) in
			if let indexPath = self?.tableView.indexPath(for: cell) {
				if let name = self?.logFileEntries[indexPath.row].name {
					self?.shareLog(with: name)
				}
			}
		}

		return cell!
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
	}

	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

		return [
			UITableViewRowAction(style: .destructive, title: "Delete".localized, handler: { [weak self] (_, indexPath) in
				let logEntry = self?.logFileEntries[indexPath.row]
				if let name = logEntry?.name {
					self?.removeLog(with: name, indexPath: indexPath)
				}
			})
		]
	}

	// MARK: - Private Helpers

	private func populateLogFileList() {
		guard let logFileWriter = OCLogger.shared.writer(withIdentifier: .writerFile) as? OCLogFileWriter else { return }
		guard let appGroupLogsURL = OCAppIdentity.shared.appGroupLogsContainerURL else { return }
		guard let logFiles = logFileWriter.logFiles() else { return }

		for fileName in logFiles {
			if let name = fileName as? String {
				let logURL = appGroupLogsURL.appendingPathComponent(name)

				var fileSize:Int64?
				var creationDate:Date?

				if let attributes = try? FileManager.default.attributesOfItem(atPath: logURL.path) {
					creationDate = attributes[FileAttributeKey.creationDate] as? Date
					fileSize = (attributes[FileAttributeKey.size] as? NSNumber)?.int64Value
				}

				let logEntry = LogEntry(name: name, size: fileSize, creationDate: creationDate)
				self.logFileEntries.append(logEntry)
			}
		}

		self.tableView.reloadData()
	}

	private func shareLog(with fileName:String) {
		guard let appGroupLogsURL = OCAppIdentity.shared.appGroupLogsContainerURL else { return }
		let shareableFileName = fileName + ".txt"
		let shareableLogURL = FileManager.default.temporaryDirectory.appendingPathComponent(shareableFileName)
		let logURL = appGroupLogsURL.appendingPathComponent(fileName)

		do {
			if FileManager.default.fileExists(atPath: shareableLogURL.path) {
				try FileManager.default.removeItem(at: shareableLogURL)
			}

			try FileManager.default.copyItem(at: logURL, to: shareableLogURL)
		} catch {
		}

		let shareViewController = UIActivityViewController(activityItems: [shareableLogURL], applicationActivities:nil)
		shareViewController.completionWithItemsHandler = { (_, _, _, _) in
			do {
				try FileManager.default.removeItem(at: shareableLogURL)
			} catch {
			}
		}

		if UIDevice.current.isIpad() {
			shareViewController.popoverPresentationController?.sourceView = self.view
		}
		self.present(shareViewController, animated: true, completion: nil)
	}

	private func removeLog(with fileName:String, indexPath:IndexPath) {
		guard let appGroupLogsURL = OCAppIdentity.shared.appGroupLogsContainerURL else { return }
		let logURL = appGroupLogsURL.appendingPathComponent(fileName)
		do {
			try FileManager.default.removeItem(at: logURL)
			self.logFileEntries.remove(at: indexPath.row)
			self.tableView.deleteRows(at: [indexPath], with: .automatic)
		} catch {
		}
	}

	@objc private func removeAllLogs() {
		let alert = UIAlertController(with: "Delete all log files?".localized,
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
}
