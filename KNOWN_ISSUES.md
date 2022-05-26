#  Known issues in version 12.0 alpha 2

## WARNING

This release of version 12 is an alpha preview release and not yet ready for production or regular use.
It should only be used with dedicated test servers, test data - and test devices.

## App
- in the new browsing experience, some features are not yet available:
	- row actions
	- drag and drop
	- search
	- sorting
	- a grid view
	- full themeing support
	- breadcrumb title
- spaces do not yet show a member count or provide access to a list of members
- subscription of spaces can't be turned on/off yet
- the root of spaces-based accounts is not yet shown as hierarchic sidebar
- support for sharing is widely untested and/or unavailable in the alpha
- inactived state of spaces is not yet represented in the UI
- "Empty folder" not shown for empty folders
- Copy & Paste allows copying a folder into a subfolder of its own / itself, leading to an infinite cycle
- handling of detached drives with user data in them (see OCVault.detachedDrives)

## File Provider
- dragging an entire space on top of another starts a full copy of the space, which eventually fails halfway through

## SDK
- local storage consumed by spaces that are then deleted or inactivated is not reclaimed
