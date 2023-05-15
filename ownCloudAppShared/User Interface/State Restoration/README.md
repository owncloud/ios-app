#  State Restoration

App State is captured as a set of actions that can be serialized into an `NSUserActivity`, be deserialized later - and then applied.

The smallest unit is the `AppStateAction`.

The actual implementation resides in `perform(in:completion:)`, whereas `run(in:completion:)` is invoked when running an action. Both take a `ClientContext` and a completion handler, which takes both an `Error` and a `ClientContext`.

## Children

An `AppStateAction` can have children, allowing to establish dependencies and time actions.

An `AppStateAction` with children first invokes `perform(in:completion:)` and - if it returned without error - runs the children.

When running the children, it uses the returned `ClientContext` and waits until all children have called their completion handler before calling its own completion handler.


## Composition

To allow simpler composition, subclasses provide an extension for `AppStateAction` that allows their easy creation.


# NSUserActivity Save & Restore

`NSUserActivity`s can be created from `AppStateAction`s - and be restored later. This allows state restoration as well as easy, flexible and extensible construction of new `UIScene`s.
