#  Navigation Content

`NavigationContent` aims to solve the problem that different parts of the app want access to and modify the contents of the `UINavigationItem` depending on context, which can easily create a complex network of possibilities and combination that are hard/impossible to cover - let alone in a clean way.

`NavigationContent` therefore acts as an independant broker of interests, by allowing different parts of the app to add and remove their content, providing an `Area` where the content should appear, a `Priority` with which the content should appear - and a `Position` of the content within its `Area`.

`NavigationContent` will first determine the currently highest `Priority` in an `Area`, then pick all `NavigationContentItem`s whose `.visibleInPriorities` property contains that `Priority`, then sorts them by `Position` - and finally applies them to the `UINavigationItem`.

By default `.visibleInPriorities` only contains the priority provided during `NavigationContentItem`s initialization, but by adding additional priorities, its visibility can be extended. F.ex. a "toggle toolbar" item can be added with `standard` priority (to not elevate the minimum priority, which would drive out other items), but also appear in higher priorities by adding them to its `.visibleInPriorities`. 
