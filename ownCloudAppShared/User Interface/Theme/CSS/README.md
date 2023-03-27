# Theme CSS

`ThemeCSS` aims to bring CSS-style styling to view trees, by letting `UIView`s and `UIViewController`s provide no, one or multiple selectors that are also added to all sub views and sub view controllers.

Using these selectors, a `ThemeCSS` object then can search for and return the best-matching value for a specific property.

Classes adopting `ThemeCSSAutoSelector` can "inject" their own class-specific selector automatically, f.ex. `label` for `UILabel`, `cell` for `UICollectionReusableView` etc. 

The best matching record for a sequence of selectors is determined following CSS specifity (https://developer.mozilla.org/en-US/docs/Web/CSS/Specificity). 
