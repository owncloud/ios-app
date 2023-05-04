# Known issues

## WARNING

This release of version 12 is an alpha preview release and not yet ready for production or regular use.
It should only be used with dedicated test servers, test data - and test devices.

## App
- in the new browsing experience, some features are not yet available:
	- breadcrumb title
- spaces do not yet show a member count or provide access to a list of members
- subscription of spaces can't be turned on/off yet
- handling of detached drives with user data in them (see OCVault.detachedDrives)
- support for OC10 sharing is incomplete: federated shares support missing
- spaces support for Shortcuts

Missing:
- [ ] static login/branded login UI
- [ ] full inline progress reporting when account databases are updated on first login
- [ ] progress reporting in active connections
- [ ] reinstate Key Commands

Jesus:
- [ ] Presentation view after installing is missing
- [ ] "Cut"/"Paste" only working in space scope

Michael:
- [ ] UI rendering picking an account for photo uploads on iPhone: prompt full length, button super-compressed.

## File Provider
- dragging an entire space on top of another starts a full copy of the space, which eventually fails halfway through

## SDK
- pre-population of accounts using infinite PROPFIND is not supported

# Evolution roadmap
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

- show spinner while recreating a scene via "Open in new window"
