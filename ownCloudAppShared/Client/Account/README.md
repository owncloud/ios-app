# Account
The `Account` set of classes manage different aspects of an account and its connection.

## AccountConnection
The `AccountConnection` set of classes is used to manage a shared connection.

### AccountConnectionPool
The pool keeps record of existing `AccountConnection` instances and creates new ones as needed. For every `OCBookmark`, only one instance of `AccountConnection` is created.

### AccountConnection
The connection is responsible for connecting to and disconnecting from a server, keeping track of the OCCore and distributing access to it.

### AccountConnectionConsumer
An `AccountConnection` is consumed by `AccountConnectionConsumer`s. Consumers group everything that is linked to an OCCore, such as `OCMessagePresenter`s, `OCFileProviderServiceStandby` instances, delegates, error handlers, …
Consumers allow to cleanly plug and unplug consumers of the account connection in a single step, so that UI elements gain consistent access to events and more, regardless of whether they were the initial element to first use a connection - or not.

## AccountController
The `AccountController` set of classes provide easy access to everything needed to provide a rich representation of an account and its contents in the UI.

### AccountController

### AccountControllerSection
`AccountControllerSection` is a convenience wrapper for `AccountController`. It's content is derived from the `AccountController.accountSectionDataSource`.
