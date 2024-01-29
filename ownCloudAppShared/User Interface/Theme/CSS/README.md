# Theme CSS

## Overview

`ThemeCSS` brings CSS-style styling to the `UIViewController`/`UIView` (henceforth summarized as "elements") tree, by allowing to attach CSS-style selectors to them via new `cssSelector` and `cssSelectors` properties.

After an element has settled in its place in the view tree, traversing the tree from an element to the tree's root element allows building a *Selector Path*, which can then be used to find the *most specific* value for a styling property.

## Implementation

### `ThemeCSSAutoSelector`
The `ThemeCSSAutoSelector` protocol is used to add class-specific selectors to commonly used, system-provided view classes automatically, f.ex. `label` for `UILabel`, or `cell` for `UICollectionReusableView`.

### `Theme` registration
To receive notifications on Theme changes and to perform initial styling, elements opt into themeing by registering with `Theme`, with an initial themeing taking place at the time of registration.

To ensure the full, applicable *Selector Path* can be built correctly, themeing should only occur once a view has arrived in its final place in the view structure.

This is typically the case when `UIView.didMoveToWindow()` or `UIViewController.viewWillAppear(_:)` are called respectively. Appropriate registration code could therefore look like this:

#### Example for `UIView`
```swift
private var _themeRegistered = false
public override func didMoveToWindow() {
	super.didMoveToWindow()

	if window != nil, !_themeRegistered {
		_themeRegistered = true
		Theme.shared.register(client: self)
	}
}
```

#### Example for `UIViewController`
```swift
private var _themeRegistered = false
open override func viewWillAppear(_ animated: Bool) {
	super.viewWillAppear(animated)
	if !_themeRegistered {
		_themeRegistered = true
		Theme.shared.register(client: self, applyImmediately: true)
	}
}
```

### Using CSS selectors

#### Assigning selectors to elements
A single selector can be assigned to an element via the `cssSelector` property, like f.ex.

```swift
tokenView.cssSelector = .token
```

If more than one selector should be assigned to an alement, the `cssSelectors` property can be used, like f.ex.

```swift
tableView.cssSelector = [.collection, .tableView]
```

#### Defining new selectors
New selectors can be defined by using extensions, like f.ex.

```swift
extension ThemeCSSSelector {
	static let releaseNotes = ThemeCSSSelector(rawValue: "releaseNotes")
}
```

#### Defining property values
Property values are encapsulated in `ThemeCSSRecord`s, which consist of
- `selectors`: an array of `ThemeCSSSelector`s that is later matched with the *Selector Path* of elements
- `property`: the property for which a value is defined (most commonly `.stroke` and `.fill`)
- `value`:  the value of the property, which can take virtually any type
- `important`: if true, the record receives an extra boost to its matching score

Example of how to add styling records to a `ThemeCSS` instance:
```swift
css.add(records: [
	ThemeCSSRecord(selectors: [.account],				property: .fill,   value: accountCellSet.backgroundColor),
	ThemeCSSRecord(selectors: [.account, .title],			property: .stroke, value: accountCellSet.labelColor),
	ThemeCSSRecord(selectors: [.account, .description],		property: .stroke, value: accountCellSet.secondaryLabelColor),
	ThemeCSSRecord(selectors: [.account, .disconnect],		property: .stroke, value: accountCellSet.tintColor),
	ThemeCSSRecord(selectors: [.account, .disconnect],		property: .fill,   value: accountCellSet.labelColor),
])
```

It is also possible to pass a `nil` value, to "remove" a value for a certain *Selector Path*.

### Retrieving property values
There are several ways to retrieve values:

#### Directly from an element
Using the `getThemeCSSColor(_ property: ThemeCSSProperty, selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil) -> UIColor?` method:
```swift
let fillColor = view.getThemeCSSColor(.fill)
```

This method is a convenience way for typed access to the `ThemeCSS` instance of `Theme.shared.activeCollection`.

#### Typed, from the `ThemeCSS` instance
Using its typed `getPROPERTY(_ property: ThemeCSSProperty, selectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject?) -> VALUE?` family of methods:
```swift
let fillColor = collection.css.getColor(.fill, for: view)
```

This family of methods also carries out conversion from other types, where appropriate:

Method name    			| Allowed types
--------------------------------|--------------
getColor     			| `UIColor`, `String` (in hex `RRGGBB` or `#RRGGBB` notations, f.ex. `abcdef` or `#abcdef`)
getInteger   			| `Int`
getCGFloat   			| `CGFloat`
getBool      			| `Boolean`, `String` (`true` and `false`)
getUserInterfaceStyle		| `UIUserInterfaceStyle`, `Int`, `String` (`unspecified`, `light`, `dark`)
getStatusBarStyle		| `UIStatusBarStyle`, `Int`, `String` (`default`, `lightContent`, `darkContent`, `white`, `black`)
getBarStyle			| `UIBarStyle`, `Int`, `String` (`default`, `black`)
getKeyboardAppearance		| `UIKeyboardAppearance`, `Int`, `String` (`default`, `light`, `dark`)
getActivityIndicatorStyle 	| `UIActivityIndicatorView.Style`, `Int`, `String` (`medium`, `large`)
getBlurEffectStyle		| `UIBlurEffect.Style`, `Int`, `String` (`regular`, `light`,  `dark`)

#### Raw, from the `ThemeCSS` instance
Using the `get(_ property: ThemeCSSProperty, selectors additionalSelectors: [ThemeCSSSelector]? = nil, state stateSelectors: [ThemeCSSSelector]? = nil, for object: AnyObject?) -> ThemeCSSRecord?` method, it is possible to retrieve the best matching `ThemeCSSRecord` for the property:
```swift
let record = collection.css.get(.fill, for: view)
let fillColor = record.value as? UIColor
```

### "Virtual" properties and states
While most elements only have a foreground (`.stroke`) and background (`.fill`) color, some elements require greater flexibility - or should look different depending on their state.

This is where additional selectors come in. All methods described above therefore allow passing additional 
- `selectors` for sub elements, which are appended to the end of the *Selector Path* for an element
- `state` for state information, which are inserted *before* the last selector in the *Selector Path* (already including additional selectors)

#### Example for sub elements
A text field needs a color for placeholder text that's different from the color for typed text:
```swift
let placeholderColor = css.getColor(.stroke, selectors: [.placeholder], for: textField)
```

If the *Selector Path* for `textField` is `.modal .textField`, adding the `.placeholder` selector now requests the `.stroke` color for `.modal .textField .placeholder`.

#### Example for different states
A button should be able to use a different background color when pressed:
```swift
let backgroundColor = button.getThemeCSSColor(.fill, state: isPressed ? [.highlighted] : nil)
```

If the *Selector Path* for `button` is `.modal .button`, adding the `.highlighted` state selector now requests the `.stroke` color for `.modal .highlighted .textField`.

### How matching works
The best matching record to derive property values from is determined through the following rules:
- a record is only considered if:
  - *all* of the record's Selectors are also contained in the *Selector Path*
  - the record's property matches the requested property
- records whose last element is identical to that of the *Selector Path* are preferred (+100)
- the specifity - and therefore weight - of selectors increases (+10) from the beginning to the end of the *Selector Path* (in `.sidebar .cell .label .account`, `.label` is weighted higher than `.cell` - at 30 vs 20)
- records with the `important` property are preferred (+1000)
- if two or more records reach the same score, the one that was last added to the `ThemeCSS` instance will be used (allows override, f.e.x. through `Branding.plist`)

## Debugging selectors and matching
If a view doesn't use the expected values for the respective properties, this can different reasons:
- themeing is performed at a time where the final *Selector Path* can't be built. Debug by setting a breakpoint and check if the element hierarchy has been correctly established at that point.
- a record other than the expected one is determined as most specific. This can be fixed by adding a more specific record, or changing the request.

To make debugging straightforward, you can use `cssDescription` and `cssDescription(extraSelectors: [String]? = nil, stateSelectors: [String]? = nil)` in the debugger, which will output the applicable records and values for the `.stroke`, `.fill` and `.cornerRadius` properties.

### Usage in practice

Combining this with view debugging turns this into a fast, flexible debugging tool:
- enter *Debug View Hierarchy* in Xcode (button that shows a stack of rectangles in the bottom bar)
- right-click the element you'd like to inspect and pick use *Reveal in Debug Navigator* from the popup menu
- right-click the revealed element in the sidebar and pick *Copy* from the popup menu
- type `po [PASTEHERE cssDescription]` behind `(lldb)` into the Debug Console, whereby you replace `PASTEHERE` with the clipboard contents, of course

Example:
```
(lldb) po [((UIView *)0x11bcf9150) cssDescription]
Selectors: all.splitView.content.collection.cell.sortBar
Matching:
- stroke: collection.cell -> UIExtendedSRGBColorSpace 0.305882 0.521569 0.784314 1
- fill: collection.cell -> UIExtendedGrayColorSpace 1 1
- cornerRadius: -
```

A way to change the value of the `stroke` property, then, would be to add a more specific record, f.ex. for `collection.cell.sortBar` - or possibly for `sortBar` directly (the last selector is weighted much higher).

## Adding styling via branding
Depending on how a client is branded, different options are used to add CSS records to f.ex. the `Branding.plist`.

In all cases, the additional CSS records follow this format:

```
selector1.selector2….property: value
```

See *Debugging selectors and matching* > *Usage in practice* above for how to determine the selectors of a view on screen.

### Branding on top of default themes 
If `branding.theme-definitions` is **not** used, the app provides themes for light mode and dark mode to branded clients, with support for light customization through branding:
Option | Description
--|--
`branding.theme-colors`| Values to use in system-color-based themes for branded clients. Mutually exclusive with theme-definitions.
`branding.theme-css-records` | CSS records to add to the CSS space of system-color-based themes for branded clients. Mutually exclusive with theme-definitions.

Both options can be used together.

#### Using `branding.theme-css-records`
Example for a `Branding.plist` filling the logo in the sidebar's navigation bar with red and the account pill with green:

```xml
<key>branding.theme-css-records</key>
<array>
	<string>sidebar.navigationBar.logo.stroke: #ff0000</string>
	<string>sidebar.account.fill: #00ff00</string>
</array>
```

Example in flat notation:
```xml
<key>branding.theme-css-records$[0]</key>
<string>sidebar.navigationBar.logo.stroke: #ff0000</string>
<key>branding.theme-css-records$[1]</key>
<string>sidebar.account.fill: #00ff00</string>
```

#### Using `branding.theme-colors`
For commonly branded elements, the app supports the following aliases to be used in key-value pairs in `branding.theme-colors`:

Alias | Value
--|--
`tint-color` | Color to use as tint/accent color for controls (in hex notation). Replaces `branding.theme-tint-color`.
`branding-background-color` | Color to use as background color for brand views (in hex notation).
`setup-status-bar-style` | The status bar style in the setup wizard, affecting the status bar text color. Can be either `default`, `black` or `white`.
`file-icon-color` | Color to fill file icons with (in hex notation).
`folder-icon-color` | Color to fill folder icons with (in hex notation).

Each alias can be expanded to one or more CSS addresses internally, so that the values set here can be assigned to the right elements - even after major UI changes or refactoring.

Example:
```xml
<key>branding.theme-colors</key>
<dict>
	<key>tint-color</key>
	<string>#ff0000</string>
	<key>branding-background-color</key>
	<string>#0ff0f0</string>
	<key>setup-status-bar-style</key>
	<string>black</string>
	<key>folder-icon-color</key>
	<string>#00ff00</string>
	<key>file-icon-color</key>
	<string>#0000ff</string>
</dict>
````

Example in flat notation:
```xml
<key>branding.theme-colors$tint-color</key>
<string>#ff0000</string>
<key>branding.theme-colors$branding-background-color</key>
<string>#0ff0f0</string>
<key>branding.theme-colors$setup-status-bar-style</key>
<string>black</string>
<key>branding.theme-colors$folder-icon-color</key>
<string>#00ff00</string>
<key>branding.theme-colors$file-icon-color</key>
<string>#0000ff</string>
````

### Branding with fully custom themes
For clients branded with fully custom themes via `branding.theme-definitions`, an array of additional CSS records can be added for each theme definition.

Example for a `Branding.plist` filling the logo in the sidebar's navigation bar with red and the account pill with green:

```xml
<key>branding.theme-definitions$[0].cssRecords</key>
<array>
	<string>sidebar.navigationBar.logo.stroke: #ff0000</string>
	<string>sidebar.account.fill: #00ff00</string>
</array>
```

Example in flat notation:
```xml
<key>branding.theme-definitions$[0].cssRecords[0]</key>
<string>sidebar.navigationBar.logo.stroke: #ff0000</string>
<key>branding.theme-definitions$[0].cssRecords[1]</key>
<string>sidebar.account.fill: #00ff00</string>
```

### Reference
#### Selectors
These selectors are used to differentiate beteween different areas:

Selector     | Description
-------------|---------------
`all`        | Matches all elements
`sidebar`    | All elements in the sidebar part of the splitview.
`content`    | All elements in the content part of the splitview.
`modal`      | All modal and standalone views, including views in app extensions.

#### Properties
Property | Type   | Description / Values
---------|--------|------------
`stroke` | color  | Color used for f.ex. text and tinting. In hex string notation. Use `none` for no color.
`fill`   | color  | Color used for f.ex. background fill. In hex string notation. Use `none` for no color.
`cornerRadius` | float | Corner radius (not widely used)
`style` | `UIUserInterfaceStyle` | `unspecified`, `light`, `dark`
`barStyle` | `UIBarStyle` | `default`, `black`
`statusBarStyle` | `UIStatusBarStyle` | `default`, `lightContent`, `darkContent`, `black`, `white`
`blurEffectStyle` | `UIBlurEffect.Style` | `regular`, `light`,  `dark`
`keyboardAppearance` | `UIKeyboardAppearance` | `default`, `light`, `dark`
`activityIndicatorStyle` |  `UIActivityIndicatorView.Style` | `medium`, `large`

#### Icon color CSS selectors
Icon colors are now also configured via CSS selectors:

TVG/Legacy Color  | CSS selector string
------------------|------------------------------------
`folderFillColor` | `vectorImage.folderColor.fill`
`fileFillColor`   | `vectorImage.fileColor.fill`
`logoFillColor`   | `vectorImage.logoColor.fill`
`iconFillColor`   | `vectorImage.iconColor.fill`
`symbolFillColor` | `vectorImage.symbolColor.fill`
