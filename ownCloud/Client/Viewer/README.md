#  Viewer architectures notes

A short summary of how the different parts of the viewer subsystem works:


### `DisplayViewController`

Root class of all viewers, providing a framework for their implementation:
- tracking of the viewed `OCItem` via its own `OCQuery`, triggering updates when the item changes
- management of (initial) file downloads, showing download status and errors as needed
	- automatically add a temporary `OCClaim` to the item to block removal while viewing, but to also trigger `OCItemPolicyProcessorVersionUpdates` to keep the file updated
	- allow customization of the `OCClaim` via `generateClaim(for:)` to achieve a different updating behaviour (i.e. block keeping the file updated, but also its removal)
- provide access to a file in two ways:
	- for streaming (indicated by `requiresLocalCopyForPreview` being `false`)
		- authentication headers (`httpAuthHeaders`)
		- direct URL on the server  (`itemDirectURL`)
	- as local file
		- local file URL (`itemDirectURL`)
- tell the class when the content is ready to be displayed or should be updated by calling `renderItem(completion:)`
	- subclasses should display contents from `itemDirectURL`, using additional information from `item` only as needed
- provide contents for the navigation bar through
	- the file name in `displayTitle` (is used to update `navigationItem.title` when appropriate)
	- available action triggers in `displayBarButtonItems` (is used to update `navigationItem.rightBarButtonItems` when appropriate)
	- changes to these two are KVO-observed and will trigger the respective UI updates if the `DisplayViewController` is currently the active one

### `DisplayHostViewController`

Presents one or more items to the user in swipeable pages. Core functionality:
- instantiates and provides the `DisplayViewController`s for the items in the page view controller
- keeps track of changes in the active `DisplayViewController` to coordinate UI updates, especially in the navigation bar, and keep them consistent with dynamic changes from users paging through items
- observes a new or existing`OCQuery` (typically from a file list view controller) for changes to automatically determine and update the list of items to present
- handling of special cases like files being deleted from the server while being viewed, maintaining a natural pagination order regardless

### `DisplayExtension`

`DisplayExtension`s plug into the `OCExtension` system and are used to:
- find the best matching viewer for a file
- create an instance of the respective  `DisplayViewController` subclass
