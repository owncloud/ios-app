//
//  FileTagsManagementViewController.swift
//  ownCloud
//
//  Copyright © 2025 ownCloud GmbH. All rights reserved.
//

import UIKit
import SnapKit
import Foundation
import ownCloudSDK
import ownCloudAppShared

// MARK: - Left-aligned flow (chips)

private final class LeftAlignedCollectionViewFlowLayout: UICollectionViewFlowLayout {
	override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		guard let original = super.layoutAttributesForElements(in: rect) else { return nil }
		let attrs = original.map { $0.copy() as! UICollectionViewLayoutAttributes }
		var left = sectionInset.left
		var lineTop: CGFloat = -1
		for attr in attrs where attr.representedElementCategory == .cell {
			if lineTop < 0 || abs(attr.frame.minY - lineTop) > 1 {
				left = sectionInset.left
				lineTop = attr.frame.minY
			}
			var f = attr.frame
			f.origin.x = left
			attr.frame = f
			left += f.width + minimumInteritemSpacing
		}
		return attrs
	}

	override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
		true
	}
}

// MARK: - Chip items

private enum ChipDisplayItem {
	case tag(OCSystemTag)
	case showMore(hiddenCount: Int)
	case showLess
}

// MARK: - Chip cell

private final class FileTagChipCell: UICollectionViewCell {
	static let reuseId = "FileTagChipCell"

	let titleLabel = UILabel()
	let removeButton = UIButton(type: .system)

	var onRemove: (() -> Void)?

	override init(frame: CGRect) {
		super.init(frame: frame)
		contentView.layer.cornerRadius = 16
		contentView.clipsToBounds = true

		titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
		titleLabel.lineBreakMode = .byTruncatingTail

		removeButton.setTitle("✕", for: .normal)
		removeButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
		removeButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)

		let stack = UIStackView(arrangedSubviews: [titleLabel, removeButton])
		stack.axis = .horizontal
		stack.spacing = 6
		stack.alignment = .center

		contentView.addSubview(stack)
		stack.snp.makeConstraints { make in
			make.leading.equalToSuperview().offset(10)
			make.trailing.equalToSuperview().offset(-8)
			make.top.bottom.equalToSuperview().inset(6)
		}
		removeButton.snp.makeConstraints { make in
			make.width.height.equalTo(28)
		}
	}

	required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

	override func prepareForReuse() {
		super.prepareForReuse()
		onRemove = nil
		setShowsRemoveButton(true)
	}

	@objc private func removeTapped() {
		onRemove?()
	}

	func setShowsRemoveButton(_ shows: Bool) {
		removeButton.isHidden = !shows
		removeButton.isUserInteractionEnabled = shows
	}

	func apply(themeCollection: ThemeCollection, isDark: Bool) {
		let secondaryText = HCColor.Content.textSecondary(isDark)
		contentView.backgroundColor = HCColor.Interaction.primaryTransparentNormal20(isDark)
		titleLabel.textColor = secondaryText
		removeButton.tintColor = secondaryText
		removeButton.setTitleColor(secondaryText, for: .normal)
	}
}

// MARK: - Dropdown rows

private enum DropdownRow {
	case hint(String)
	case tag(OCSystemTag)
	case addNew(String)
	case error(String)
}

private final class TagDropdownTableViewCell: UITableViewCell {
	static let reuseId = "TagDropdownTableViewCell"

	private let errorIconView = UIImageView()
	private let titleLabel = UILabel()
	private let contentStack: UIStackView = {
		let stack = UIStackView()
		stack.axis = .horizontal
		stack.spacing = 8
		stack.alignment = .center
		return stack
	}()

	var showsBottomSeparator = true {
		didSet { setNeedsLayout() }
	}

	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		backgroundColor = .clear
		contentView.backgroundColor = .clear
		backgroundConfiguration = UIBackgroundConfiguration.clear()

		errorIconView.contentMode = .scaleAspectFit
		errorIconView.setContentHuggingPriority(.required, for: .horizontal)
		errorIconView.snp.makeConstraints { $0.width.height.equalTo(24) }

		titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

		contentStack.addArrangedSubview(errorIconView)
		contentStack.addArrangedSubview(titleLabel)
		contentView.addSubview(contentStack)
		contentStack.snp.makeConstraints { make in
			make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12))
		}
		errorIconView.isHidden = true
	}

	required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

	override func prepareForReuse() {
		super.prepareForReuse()
		errorIconView.isHidden = true
		selectionStyle = .default
		isUserInteractionEnabled = true
	}

	override func layoutSubviews() {
		super.layoutSubviews()
		if showsBottomSeparator {
			separatorInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
		} else {
			separatorInset = UIEdgeInsets(top: 0, left: .greatestFiniteMagnitude, bottom: 0, right: 0)
		}
	}

	func configure(row: DropdownRow, isLast: Bool, isDark: Bool) {
		showsBottomSeparator = !isLast
		errorIconView.isHidden = true
		titleLabel.font = .systemFont(ofSize: 16)
		titleLabel.lineBreakMode = .byTruncatingTail

		switch row {
			case .hint(let text):
				titleLabel.text = text
				titleLabel.textColor = HCColor.Content.textPrimary(isDark)
				titleLabel.numberOfLines = 0
				titleLabel.lineBreakMode = .byWordWrapping
				selectionStyle = .none
				isUserInteractionEnabled = false
			case .error(let text):
				let errorColor = HCColor.Symbolic.error(isDark)
				errorIconView.isHidden = false
				errorIconView.image = HCIcon.errorIcon?.withRenderingMode(.alwaysTemplate)
				errorIconView.tintColor = errorColor
				titleLabel.text = text
				titleLabel.textColor = errorColor
				titleLabel.numberOfLines = 0
				titleLabel.lineBreakMode = .byWordWrapping
				selectionStyle = .none
				isUserInteractionEnabled = false
			case .tag(let tag):
				titleLabel.text = tag.displayName
				titleLabel.textColor = HCColor.Content.textPrimary(isDark)
				titleLabel.numberOfLines = 1
				selectionStyle = .default
				isUserInteractionEnabled = true
			case .addNew(let name):
				titleLabel.text = String(format: HCL10n.TagManage.addTagFormat, name)
				titleLabel.textColor = HCColor.Content.textPrimary(isDark)
				titleLabel.numberOfLines = 1
				selectionStyle = .default
				isUserInteractionEnabled = true
		}
	}
}

final class FileTagsManagementViewController: UIViewController, Themeable {
	private let item: OCItem
	private let core: OCCore

	private let fileHeaderContainer = UIView()
	private let tagsBodyContainer = UIView()

	private let thumbnailView = ResourceViewHost()
	private let nameLabel = UILabel()
	private let tagSelectField = HCTagSelectFieldView(frame: .zero)

	private let chipsContainer = UIView()
	private let chipsCollectionView: UICollectionView
	private let emptyTagsMessageView: ComposedMessageView

	private var themeRegistered = false
	private var loadingOverlay: UIActivityIndicatorView?

	private var allSystemTags: [OCSystemTag] = []
	private var assignedTags: [OCSystemTag] = []
	private var dropdownRows: [DropdownRow] = []

	private var chipsExpanded = false
	private var chipsHeightConstraint: Constraint?
	private var displayedChipItems: [ChipDisplayItem] = []
	private var hiddenTagCount = 0
	private var canCollapseChips = false
	private let chipLineHeight: CGFloat = 36
	private let chipLineSpacing: CGFloat = 8
	private let headerThumbnailSize = CGSize(width: 120, height: 120)
	private var maxCollapsedChipsHeight: CGFloat { chipLineHeight * 4 + chipLineSpacing * 3 }

	init(item: OCItem, core: OCCore) {
		self.item = item
		self.core = core
		let layout = LeftAlignedCollectionViewFlowLayout()
		layout.scrollDirection = .vertical
		layout.minimumInteritemSpacing = 8
		layout.minimumLineSpacing = 8
		layout.estimatedItemSize = .zero
		layout.sectionInset = .zero
		self.chipsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
		self.emptyTagsMessageView = Self.makeEmptyTagsMessageView()
		super.init(nibName: nil, bundle: nil)
	}

	private static func makeEmptyTagsMessageView() -> ComposedMessageView {
		return ComposedMessageView(elements: [
			.image(OCSymbol.icon(forSymbolName: "tag") ?? UIImage(), size: CGSize(width: 48, height: 48), alignment: .centered),
			.spacing(8),
			.subtitle(HCL10n.TagManage.emptyFileMessage, alignment: .centered)
		])
	}

	required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

	deinit {
		if themeRegistered {
			Theme.shared.unregister(client: self)
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		view.backgroundColor = .systemGroupedBackground

		nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
		nameLabel.numberOfLines = 0
		nameLabel.textAlignment = .natural
		nameLabel.text = item.name
		nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
		nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

		thumbnailView.contentMode = .scaleAspectFit
		thumbnailView.setContentHuggingPriority(.required, for: .horizontal)
		thumbnailView.setContentCompressionResistancePriority(.required, for: .horizontal)
		let request = OCResourceRequestItemThumbnail.request(for: item, maximumSize: headerThumbnailSize, scale: 0, waitForConnectivity: true, changeHandler: nil)
		thumbnailView.request = request
		core.vault.resourceManager?.start(request)

		tagSelectField.textFieldView.placeholder = HCL10n.TagManage.selectTagPlaceholder
		tagSelectField.textFieldView.title = ""
		tagSelectField.textFieldView.leftIcon = HCIcon.tagIcon
		tagSelectField.textFieldView.showsCardBackground = true
		tagSelectField.dropdownHostView = view
		tagSelectField.optionsTableView.dataSource = self
		tagSelectField.optionsTableView.delegate = self
		tagSelectField.optionsTableView.register(TagDropdownTableViewCell.self, forCellReuseIdentifier: TagDropdownTableViewCell.reuseId)
		tagSelectField.onEditingBegan = { [weak self] in
			self?.refreshTagDropdown()
		}
		tagSelectField.onSearchTextChanged = { [weak self] in
			self?.refreshTagDropdown()
		}

		chipsCollectionView.backgroundColor = .clear
		chipsCollectionView.isScrollEnabled = true
		chipsCollectionView.alwaysBounceVertical = false
		chipsCollectionView.register(FileTagChipCell.self, forCellWithReuseIdentifier: FileTagChipCell.reuseId)
		chipsCollectionView.dataSource = self
		chipsCollectionView.delegate = self

		let fileHeaderRow = UIStackView(arrangedSubviews: [thumbnailView, nameLabel])
		fileHeaderRow.axis = .horizontal
		fileHeaderRow.spacing = 8
		fileHeaderRow.alignment = .center
		thumbnailView.snp.makeConstraints { make in
			make.size.equalTo(headerThumbnailSize)
		}

		fileHeaderContainer.addSubview(fileHeaderRow)
		fileHeaderRow.snp.makeConstraints { make in
			make.top.equalToSuperview().offset(8)
			make.bottom.equalToSuperview().offset(-8)
			make.leading.equalToSuperview().offset(35)
			make.trailing.equalToSuperview().offset(-16)
		}

		chipsContainer.addSubview(chipsCollectionView)
		chipsCollectionView.snp.makeConstraints { make in
			make.edges.equalToSuperview()
			chipsHeightConstraint = make.height.equalTo(0).constraint
		}

		tagsBodyContainer.addSubview(emptyTagsMessageView)
		tagsBodyContainer.addSubview(chipsContainer)
		emptyTagsMessageView.snp.makeConstraints { make in
			make.center.equalToSuperview()
			make.leading.greaterThanOrEqualToSuperview().offset(20)
			make.trailing.lessThanOrEqualToSuperview().offset(-20)
		}

		view.addSubview(fileHeaderContainer)
		view.addSubview(tagSelectField)
		view.addSubview(tagsBodyContainer)

		fileHeaderContainer.snp.makeConstraints { make in
			make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
			make.leading.trailing.equalToSuperview()
		}
		tagSelectField.snp.makeConstraints { make in
			make.top.equalTo(fileHeaderContainer.snp.bottom).offset(20)
			make.leading.equalToSuperview().offset(16)
			make.trailing.equalToSuperview().offset(-16)
		}
		tagsBodyContainer.snp.makeConstraints { make in
			make.top.equalTo(tagSelectField.snp.bottom)
			make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
		}
		chipsContainer.snp.makeConstraints { make in
			make.top.equalToSuperview()
			make.leading.equalToSuperview().offset(20)
			make.trailing.equalToSuperview().offset(-20)
			make.bottom.lessThanOrEqualToSuperview()
		}

		showLoading(true)
		reloadAllTagData()

		Theme.shared.register(client: self, applyImmediately: true)
		themeRegistered = true
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		if !assignedTags.isEmpty {
			updateChipsUI()
		}
	}

	func applyThemeCollection(theme: Theme, collection: ThemeCollection, event: ThemeEvent) {
		let isDark = collection.isDark
		let appBackground = HCColor.Structure.appBackground(isDark)
		view.backgroundColor = appBackground
		tagsBodyContainer.backgroundColor = appBackground
		fileHeaderContainer.backgroundColor = HCColor.Structure.cardBackground(isDark)
		nameLabel.textColor = HCColor.Content.textPrimary(isDark)
		emptyTagsMessageView.applyThemeCollection(theme: theme, collection: collection, event: event)
		tagSelectField.textFieldView.leftIconTintColor = HCColor.Interaction.primarySolidNormal(isDark)
		tagSelectField.textFieldView.clearButton.setImage(collection.isDark ? HCIcon.clearDark : HCIcon.clearLight, for: .normal)
		chipsCollectionView.reloadData()
	}

	@objc func dismissAnimated() {
		dismiss(animated: true)
	}

	private func showLoading(_ show: Bool) {
		if show {
			if loadingOverlay == nil {
				let v = UIActivityIndicatorView(style: .medium)
				v.hidesWhenStopped = true
				view.addSubview(v)
				v.snp.makeConstraints { $0.center.equalToSuperview() }
				loadingOverlay = v
			}
			loadingOverlay?.startAnimating()
			tagSelectField.textFieldView.textField.isEnabled = false
		} else {
			loadingOverlay?.stopAnimating()
			tagSelectField.textFieldView.textField.isEnabled = true
		}
	}

	private func reloadAllTagData() {
		guard let fileID = item.fileID else {
			showLoading(false)
			return
		}
		let connection = core.connection
		showLoading(true)
		let group = DispatchGroup()
		var sysErr: Error?
		var fileErr: Error?
		var sysTags: [OCSystemTag]?
		var fileTags: [OCSystemTag]?

		group.enter()
		connection.retrieveSystemTags { error, tags in
			if let error { sysErr = error }
			sysTags = tags
			group.leave()
		}

		group.enter()
		connection.retrieveTagsForFile(withID: fileID) { error, tags in
			if let error { fileErr = error }
			fileTags = tags
			group.leave()
		}

		group.notify(queue: .main) { [weak self] in
			guard let self else { return }
			self.showLoading(false)
			if let e = sysErr ?? fileErr {
				self.presentAlert(title: HCL10n.TagManage.loadingError, message: e.localizedDescription)
			}
			if sysErr == nil, let tags = sysTags {
				self.allSystemTags = tags.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
			}
			if fileErr == nil, let tags = fileTags {
				self.assignedTags = tags.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
			}
			self.updateChipsUI()
			self.refreshTagDropdown()
		}
	}

	private func assignedIdSet() -> Set<String> {
		Set(assignedTags.map(\.identifier))
	}

	private func candidateTags(filteredBy query: String) -> [OCSystemTag] {
		let assigned = assignedIdSet()
		let base = allSystemTags.filter { tag in
			!assigned.contains(tag.identifier)
		}
		let q = query.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
		guard !q.isEmpty else { return base }
		return base.filter { ($0.displayName as String).range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
	}

	private func rebuildDropdownRows() {
		let q = tagSelectField.textFieldView.textField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""

		if let err = TagNameValidation.validationError(for: q), !q.isEmpty {
			dropdownRows = [.error(err)]
			return
		}

		if allSystemTags.isEmpty {
			dropdownRows = q.isEmpty
				? [.hint(HCL10n.TagManage.noTagsAvailableHint)]
				: [.addNew(q)]
			return
		}

		let candidates = candidateTags(filteredBy: q)
		if q.isEmpty, candidates.isEmpty {
			dropdownRows = [.hint(HCL10n.TagManage.noTagsAvailableHint)]
			return
		}

		var rows: [DropdownRow] = []
		for t in candidates {
			rows.append(.tag(t))
		}

		if !q.isEmpty {
			let exact = candidates.contains { $0.displayName.compare(q, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }
			if !exact {
				rows.append(.addNew(q))
			}
		}

		dropdownRows = rows
	}

	private func refreshTagDropdown() {
		rebuildDropdownRows()
		tagSelectField.reloadOptions()
		if tagSelectField.textFieldView.textField.isFirstResponder {
			tagSelectField.expandDropdownIfNeeded()
		}
	}

	private func chipWidth(forTitle title: String, showsRemove: Bool) -> CGFloat {
		let font = UIFont.systemFont(ofSize: 14, weight: .medium)
		let textWidth = (title as NSString).size(withAttributes: [.font: font]).width
		if showsRemove {
			return ceil(10 + textWidth + 6 + 28 + 8)
		}
		return ceil(10 + textWidth + 10)
	}

	private func flowLayoutHeight(forWidths widths: [CGFloat], containerWidth: CGFloat) -> CGFloat {
		guard containerWidth > 0, !widths.isEmpty else { return 0 }
		var x: CGFloat = 0
		var y: CGFloat = 0
		var rowHeight: CGFloat = 0
		for width in widths {
			let itemWidth = min(width, containerWidth)
			if x > 0, x + chipLineSpacing + itemWidth > containerWidth + 0.5 {
				y += rowHeight + chipLineSpacing
				x = 0
				rowHeight = 0
			}
			if x > 0 {
				x += chipLineSpacing
			}
			x += itemWidth
			rowHeight = max(rowHeight, chipLineHeight)
		}
		return y + rowHeight
	}

	private func recomputeChipDisplay() {
		let containerWidth = chipsCollectionView.bounds.width
		guard containerWidth > 0 else {
			displayedChipItems = assignedTags.map { .tag($0) }
			canCollapseChips = false
			hiddenTagCount = 0
			return
		}

		let total = assignedTags.count
		guard total > 0 else {
			displayedChipItems = []
			canCollapseChips = false
			hiddenTagCount = 0
			return
		}

		let tagWidths = assignedTags.map { chipWidth(forTitle: $0.displayName, showsRemove: true) }
		let fullHeight = flowLayoutHeight(forWidths: tagWidths, containerWidth: containerWidth)
		canCollapseChips = fullHeight > maxCollapsedChipsHeight + 0.5

		if !canCollapseChips {
			displayedChipItems = assignedTags.map { .tag($0) }
			hiddenTagCount = 0
			return
		}

		if chipsExpanded {
			var items = assignedTags.map { ChipDisplayItem.tag($0) }
			items.append(.showLess)
			displayedChipItems = items
			hiddenTagCount = 0
			return
		}

		var visibleCount = total
		for candidate in stride(from: total, through: 0, by: -1) {
			let hidden = total - candidate
			var widths = Array(tagWidths.prefix(candidate))
			if hidden > 0 {
				let moreTitle = String(format: HCL10n.TagManage.showMoreFormat, hidden)
				widths.append(chipWidth(forTitle: moreTitle, showsRemove: false))
			}
			if flowLayoutHeight(forWidths: widths, containerWidth: containerWidth) <= maxCollapsedChipsHeight + 0.5 {
				visibleCount = candidate
				hiddenTagCount = hidden
				break
			}
		}

		var items: [ChipDisplayItem] = assignedTags.prefix(visibleCount).map { .tag($0) }
		if hiddenTagCount > 0 {
			items.append(.showMore(hiddenCount: hiddenTagCount))
		}
		displayedChipItems = items
	}

	private func updateChipsUI() {
		let has = !assignedTags.isEmpty
		emptyTagsMessageView.isHidden = has
		chipsContainer.isHidden = !has
		guard has else {
			chipsHeightConstraint?.update(offset: 0)
			displayedChipItems = []
			return
		}
		recomputeChipDisplay()
		chipsCollectionView.reloadData()
		chipsCollectionView.layoutIfNeeded()
		let contentHeight = chipsCollectionView.collectionViewLayout.collectionViewContentSize.height
		let height: CGFloat
		if canCollapseChips && !chipsExpanded {
			height = min(maxCollapsedChipsHeight, contentHeight)
		} else {
			height = contentHeight
		}
		let maxHeight = tagsBodyContainer.bounds.height
		if maxHeight > 0 {
			chipsHeightConstraint?.update(offset: min(height, maxHeight))
		} else {
			chipsHeightConstraint?.update(offset: height)
		}
	}

	private func presentAlert(title: String, message: String?) {
		let alert = ThemedAlertController(title: title, message: message, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: HCL10n.TagManage.errorOk, style: .default))
		present(alert, animated: true)
	}

	private func assignOnServer(_ tag: OCSystemTag) {
		guard let fileID = item.fileID else { return }
		showLoading(true)
		core.connection.assign(tag, toFileWithID: fileID) { [weak self] error in
			OnMainThread {
				self?.showLoading(false)
				if let error {
					self?.presentAlert(title: HCL10n.TagManage.assignFailed, message: error.localizedDescription)
					return
				}
				guard let self else { return }
				if !self.assignedTags.contains(where: { $0.identifier == tag.identifier }) {
					self.assignedTags.append(tag)
					self.assignedTags.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
				}
				self.tagSelectField.textFieldView.textField.text = ""
				self.tagSelectField.collapseDropdown()
				self.updateChipsUI()
				self.refreshTagDropdown()
			}
		}
	}

	private func createAndAssignOnServer(name: String) {
		guard let fileID = item.fileID else { return }
		showLoading(true)
		core.connection.createAndAssignTag(
			withName: name,
			userVisible: true,
			userAssignable: true,
			canAssign: true,
			userEditable: true,
			toFileWithID: fileID
		) { [weak self] error, newTag in
			OnMainThread {
				self?.showLoading(false)
				if let error {
					let ns = error as NSError
					if ns.isOCError(withCode: .itemAlreadyExists) {
						self?.reloadAllTagDataAfterConflict(wantedName: name)
						return
					}
					self?.presentAlert(title: HCL10n.TagManage.createError, message: error.localizedDescription)
					return
				}
				guard let self else { return }
				if let newTag {
					if !self.allSystemTags.contains(where: { $0.identifier == newTag.identifier }) {
						self.allSystemTags.append(newTag)
						self.allSystemTags.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
					}
					if !self.assignedTags.contains(where: { $0.identifier == newTag.identifier }) {
						self.assignedTags.append(newTag)
						self.assignedTags.sort { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
					}
				}
				self.tagSelectField.textFieldView.textField.text = ""
				self.tagSelectField.collapseDropdown()
				self.updateChipsUI()
				self.refreshTagDropdown()
			}
		}
	}

	private func reloadAllTagDataAfterConflict(wantedName: String) {
		guard item.fileID != nil else { return }
		let connection = core.connection
		showLoading(true)
		connection.retrieveSystemTags { [weak self] error, tags in
			OnMainThread {
				guard let self else { return }
				self.showLoading(false)
				if let error {
					self.presentAlert(title: HCL10n.TagManage.loadingError, message: error.localizedDescription)
					return
				}
				self.allSystemTags = (tags ?? []).sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
				if let existing = self.allSystemTags.first(where: { $0.displayName.compare(wantedName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame }) {
					self.assignOnServer(existing)
				} else {
					self.presentAlert(title: HCL10n.TagManage.alreadyExists, message: nil)
				}
			}
		}
	}

	private func unassignOnServer(_ tag: OCSystemTag) {
		guard let fileID = item.fileID else { return }
		showLoading(true)
		core.connection.unassignTag(tag, fromFileWithID: fileID) { [weak self] error in
			OnMainThread {
				self?.showLoading(false)
				if let error {
					self?.presentAlert(title: HCL10n.TagManage.removeFailed, message: error.localizedDescription)
					return
				}
				self?.assignedTags.removeAll { $0.identifier == tag.identifier }
				self?.updateChipsUI()
				self?.refreshTagDropdown()
			}
		}
	}
}

// MARK: - UITableView

extension FileTagsManagementViewController: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		dropdownRows.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: TagDropdownTableViewCell.reuseId, for: indexPath) as! TagDropdownTableViewCell
		let isDark = Theme.shared.activeCollection.isDark
		let isLast = indexPath.row == dropdownRows.count - 1
		cell.configure(row: dropdownRows[indexPath.row], isLast: isLast, isDark: isDark)
		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		switch dropdownRows[indexPath.row] {
			case .hint, .error:
				break
			case .tag(let t):
				assignOnServer(t)
			case .addNew(let name):
				createAndAssignOnServer(name: name)
		}
	}
}

// MARK: - UICollectionView

extension FileTagsManagementViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		displayedChipItems.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FileTagChipCell.reuseId, for: indexPath) as! FileTagChipCell
		let isDark = Theme.shared.activeCollection.isDark
		switch displayedChipItems[indexPath.item] {
			case .tag(let tag):
				cell.titleLabel.text = tag.displayName
				cell.setShowsRemoveButton(true)
				cell.onRemove = { [weak self] in
					self?.unassignOnServer(tag)
				}
			case .showMore(let hiddenCount):
				cell.titleLabel.text = String(format: HCL10n.TagManage.showMoreFormat, hiddenCount)
				cell.setShowsRemoveButton(false)
				cell.onRemove = nil
			case .showLess:
				cell.titleLabel.text = HCL10n.TagManage.showLess
				cell.setShowsRemoveButton(false)
				cell.onRemove = nil
		}
		cell.apply(themeCollection: Theme.shared.activeCollection, isDark: isDark)
		return cell
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let title: String
		let showsRemove: Bool
		switch displayedChipItems[indexPath.item] {
			case .tag(let tag):
				title = tag.displayName
				showsRemove = true
			case .showMore(let hiddenCount):
				title = String(format: HCL10n.TagManage.showMoreFormat, hiddenCount)
				showsRemove = false
			case .showLess:
				title = HCL10n.TagManage.showLess
				showsRemove = false
		}
		let width = chipWidth(forTitle: title, showsRemove: showsRemove)
		return CGSize(width: min(width, collectionView.bounds.width), height: chipLineHeight)
	}

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		switch displayedChipItems[indexPath.item] {
			case .showMore, .showLess:
				chipsExpanded.toggle()
				updateChipsUI()
			case .tag:
				break
		}
	}
}
