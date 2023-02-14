# Known issues

## WARNING

This release of version 12 is an alpha preview release and not yet ready for production or regular use.
It should only be used with dedicated test servers, test data - and test devices.

## App
- in the new browsing experience, some features are not yet available:
	- a grid view
	- breadcrumb title
- spaces do not yet show a member count or provide access to a list of members
- subscription of spaces can't be turned on/off yet
- handling of detached drives with user data in them (see OCVault.detachedDrives)
- [x] clicking a file in favorite view doesn't open the viewer (due to lack of context.query - the viewer clases need to be updated to use data sources rather than queries)
- support for OC10 sharing is incomplete:
	- lack of actions for accepted shares
	- federated shares are not yet included in "Shared with me" view
- spaces support for Shortcuts

Missing:
- [x] quick access
- [x] proper iPhone support
- [ ] static login/branded login UI
- [x] state restoration
- [ ] full inline progress reporting when account databases are updated on first login
- [ ] progress reporting in active connections
- [x] migration from the Legacy app clarified: the feature was removed
- [x] iPadOS: opening an account in a new window
	- [x] by context menu (openAccountInWindow)
	- [x] by drag and drop (see ServerListTableViewController: UITableViewDragDelegate)
- [x] account auto connect (also account.auto-connect in ServerListTableViewController) -> no longer necessary, handled by state restoration
- [x] opening private links (display(itemWithID…:…))
- [x] account issue handling
- [x] functional share extension
- [ ] full themeing/branding support
- [ ] reinstate Key Commands

Jesus:
- [ ] Presentation view after installing is missing
- [x] The icon to hide/show the sidebar is missing in portrait mode. -> resolved by BrowserNavigation replacement of UINavigationController
- [x] Adding an oCIS account with existing custom spaces makes the app freezes and then crashes
- [x] If an space is browsed and new space image is added in the web client, app crashes
- [x] "Open in new window" option does not work. It does nothing after clicking
- [x] I miss the option to "Select All" and "Deselect All" in multiselection
- [x] "Copy" and "Move" operations show empty folder picker. No way to consolidate.
- [ ] "Cut"/"Paste" only working in space scope
- [ ] Upper bar (time, hour, battery level, and so on) is black under dark themes, not visible (fixable?)

Matthias:
- [x] Selecting an OC10 account's root folder twice results in an empty list -> not reproducible in latest builds

Michael:
- [x] Account deletion by swipe doesn't work
- [x] Crash searching for accounts to share with
- [x] Certificate warning when an account refers to a mix of hostnames
- [ ] UI rendering picking an account for photo uploads on iPhone: prompt full length, button super-compressed.

## File Provider
- dragging an entire space on top of another starts a full copy of the space, which eventually fails halfway through

## SDK
- pre-population of accounts using infinite PROPFIND is not supported

# Evolution roadmap
- [x] collection views
	- [x] support sidebars / hierarchies, including expanded state, with dynamic updates from data sources
	- [x] ItemListCell: replace manual composition of info line below name with SegmentView
		- [x] allows to show different content there, f.ex. Space and Folder in search

- [x] location picker replaces folder picker
	- [x] supports picking
		- [x] accounts
		- [x] spaces
		- [x] folders
	- [x] returns an OCLocation
	- allow passing "quick locations" to present on top in a group
	- track and re-offer last-picked / recent locations (via account's KVS)
	- quick access to personal and other spaces
	- integrate favorites as group
	- [x] use for preferences and share extension

- improved bookmark setup / editing
	- browsing UI for ALL certificates stored in a bookmark's store, not just the primary certificate

- account list
	- allow grouping accounts (i.e. Home / Work)
	- [x] replace simple list with modern CollectionViewController-based UI

- available offline
	- allow creating available offline item policies from smart searches - or directly from the search UI

- make sync smarter, f.ex.:
	- a file that is updated locally multiple times only should be uploaded once, not once for every update
	- a file or folder that is scheduled for upload / creation - and then deleted, should not be uploaded then deleted
	- a file scheduled for upload in a folder that is then deleted should not be uploaded then deleted

- make sync more resilient
	- more rigid dependency tracking -> stuck sync actions waiting for a request to return should no longer be possible as a result
	- allow users to manually reschedule sync actions (=> maybe only after implementing cross-process progress reporting)

- progress reporting sync across processes
	- app -> FP
	- FP -> app
	- possibly use dedicated OC KVS + OCProgress for that

- support for versions

- photo uploads
	- needs better error reporting / handling
		- photos vanished from photos between upload request and when it is its turn
			- report to user, drop silently, retry (how often/long?)?
		- other errors
			- report to user, drop silently, retry (how often/long?)?

- [x] more expressive "Empty folder" message display, based on new .message item type
