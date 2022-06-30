#  Known issues in version 12.0 alpha 2

## WARNING

This release of version 12 is an alpha preview release and not yet ready for production or regular use.
It should only be used with dedicated test servers, test data - and test devices.

## App
- in the new browsing experience, some features are not yet available:
	- a grid view
	- breadcrumb title
	- item / folder / usage info at the bottom of lists
- spaces do not yet show a member count or provide access to a list of members
- subscription of spaces can't be turned on/off yet
- the root of spaces-based accounts is not yet shown as hierarchic sidebar
- support for sharing is widely untested and/or unavailable in the alpha
- inactivated state of spaces is not yet represented in the UI
- Copy & Paste allows copying a folder into a subfolder of its own / itself, leading to an infinite cycle
- handling of detached drives with user data in them (see OCVault.detachedDrives)
- sync actions that are actually complete are not always cleared from the Status tab until a logout/login
- dropping an item into its source/origin folder (same view controller) triggers a MOVE that fails

## File Provider
- dragging an entire space on top of another starts a full copy of the space, which eventually fails halfway through

## SDK
- local storage consumed by spaces that are then deleted or inactivated is not reclaimed
- pre-population of accounts using infinite PROPFIND is not supported

# Evolution roadmap
- collection views
	- support sidebars / hierarchies, including expanded state, with dynamic updates from data sources

- location picker replaces folder picker
	- supports picking
		- accounts
		- spaces
		- folders
	- returns an OCLocation
	- allow passing "quick locations" to present on top in a group
	- track and re-offer last-picked / recent locations (via account's KVS)
	- quick access to personal and other spaces
	- integrate favorites as group

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

- more expressive "Empty folder" message display, based on new .message item type
