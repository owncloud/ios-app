#  Navigation Revocation

The Navigation Revocation set of classes address a problem occuring in split views, where:
- the selection in the (left) sidebar changes the content in the (right) main view
- the selected item goes away while its contents is still shown on the right


## Mechanics

When pushing content to the content part a `NavigationRevocationAction` is
- created
- registered with the `NavigationRevocationManager` (which holds only a weak reference) and
- strongly referenced by the view controller presenting the content.

Now, if content disappears from the sidebar, a matching `NavigationRevocationEvent` is sent to the `NavigationRevocationManager`, which subsequently shares it with all `NavigationRevocationAction`s.

`NavigationRevocationAction`s listening for that event can then apply their action to ensure the user is presented appropriate content.

If subsequently the view controller that held the only strong reference to the `NavigationRevocationAction` is deallocated, its registration also automatically disappears from `NavigationRevocationManager`, so that the action will not respond to subsequent events.

This pattern ensures that only relevant `NavigationRevocationAction`s are around at any given time.


## Trigger

Events are triggered by either manually being sent to the `NavigationRevocationManager` - or by a `NavigationRevocationTrigger` that can be triggered by
- deallocation of another object
- disappearance of a reference from a data source

It's also possible to set `NavigationRevocationTrigger`s for an `NavigationRevocationAction`, so that the action then holds a strong reference to the triggers - and is run once once the first trigger is triggered. The triggers will be removed together with the action when the action is deallocated.


## Test Cases
- disconnect from a server whose content is currently shown
- deactivation of a space whose content is currently shown
