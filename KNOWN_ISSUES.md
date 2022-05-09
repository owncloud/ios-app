#  Known issues in version 12.0 alpha 1

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
- photo/media uploads from the app are broken
- inactived state of spaces is not yet represented in the UI
- "Empty folder" not shown for empty folders

## File Provider
- the list of spaces doesn't update dynamically
- the list of spaces may contain spaces of unsupported types
- not all actions are working correctly, especially in the root folder of spaces
- OCCores may not be managed correctly under all circumstances, causing undefined behaviour
- file uploads are broken

## SDK
- local storage consumed by spaces that are then deleted or inactivated is not reclaimed
