# Color Scheme Guide

[TOC]



------



## Color Types

The following types representing a structures for a collection of colors.

### ThemeColorPair

Used for  *Button / Fill color collections* like: approvalColors, neutralColors, destructiveColors

| Name       | Type    |
| ---------- | ------- |
| foreground | UIColor |
| background | UIColor |



### ThemeColorPairCollection

Used for  *Button / Fill color collections* like: approvalColors, neutralColors, destructiveColors

| Name        | Type                                              |
| ----------- | ------------------------------------------------- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |



### ThemeColorCollection

Used in for tableRowColors, tableRowHighlightColors, navigationBarColors, toolbarColors, darkBrandColors, lightBrandColors

| Name                      | Type                                                  |
| ------------------------- | ----------------------------------------------------- |
| backgroundColor           | UIColor                                               |
| labelColor                | UIColor                                               |
| secondaryLabelColor       | UIColor                                               |
| symbolColor               | UIColor                                               |
| tintColor                 | UIColor                                               |
| filledColorPairCollection | [ThemeColorPairCollection](#ThemeColorPairCollection) |

### 

## Colors and Color Collections (ThemeCollection)

This colors and color collections are not branded and always the same, regardless of which theme style is selected. All these values can be customized via branding themes, but this needs code changes.

### Brand colors

| Name            | Type    | Mapping Name | Value      |
| --------------- | ------- | ------------ | ---------- |
| darkBrandColor  | UIColor |              | **1d293b** |
| lightBrandColor | UIColor |              | **468cc8** |

### Brand color collection

| Name             | Type                                                         |
| ---------------- | ------------------------------------------------------------ |
| darkBrandColors  | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |
| lightBrandColors | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |



#### darkBrandColors

| Name                      | Type                                                         | Mapping Name | Value      |
| ------------------------- | ------------------------------------------------------------ | ------------ | ---------- |
| backgroundColor           | UIColor                                                      |              | **1d293b** |
| labelColor                | UIColor                                                      |              | **ffffff** |
| secondaryLabelColor       | UIColor                                                      |              | **aaaaaa** |
| symbolColor               | UIColor                                                      |              | **ffffff** |
| tintColor                 | UIColor                                                      |              | **6ba3d3** |
| filledColorPairCollection | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) | -            |            |

##### darkBrandColors.filledColorPairCollection

| Name        | Type                                              |
| ----------- | ------------------------------------------------- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |

darkBrandColors.filledColorPairCollection.normal

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **1d293b** |

darkBrandColors.filledColorPairCollection.highlighted

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **555e6c** |

darkBrandColors.filledColorPairCollection.disabled

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **555e6c** |

#### lightBrandColors

| Name                      | Type                                                         | Mapping Name | Value      |
| ------------------------- | ------------------------------------------------------------ | ------------ | ---------- |
| backgroundColor           | UIColor                                                      |              | **468cc8** |
| labelColor                | UIColor                                                      |              | **ffffff** |
| secondaryLabelColor       | UIColor                                                      |              | **aaaaaa** |
| symbolColor               | UIColor                                                      |              | **ffffff** |
| tintColor                 | UIColor                                                      |              | **ffffff** |
| filledColorPairCollection | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) | -            |            |

##### lightBrandColors,filledColorPairCollection

| Name        | Type                                              |
| ----------- | ------------------------------------------------- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |

lightBrandColors.filledColorPairCollection.normal

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **468cc8** |

lightBrandColors.filledColorPairCollection.highlighted

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **74a8d5** |

lightBrandColors.filledColorPairCollection.disabled

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **74a8d5** |

#### 

### Label colors

| Name             | Type    | Mapping Name | Value      |
| ---------------- | ------- | ------------ | ---------- |
| informativeColor | UIColor |              | **555555** |
| successColor     | UIColor |              | **27ae60** |
| warningColor     | UIColor |              | **f2994a** |
| errorColor       | UIColor |              | **eb5757** |



### Button / Fill color collections

| Name              | Type                                                         |
| ----------------- | ------------------------------------------------------------ |
| approvalColors    | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) |
| neutralColors     | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) |
| destructiveColors | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) |



#### approvalColors

| Name        | Type                                              |
| ----------- | ------------------------------------------------- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |

##### approvalColors.normal

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **1ac763** |

##### approvalColors.highlighted

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **53d58a** |

##### approvalColors.disabled

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **53d58a** |



#### neutralColors

| Name        | Type                                              |
| ----------- | ------------------------------------------------- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |

##### neutralColors.normal

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **468cc8** |

##### neutralColors.highlighted

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **74a8d5** |

##### neutralColors.disabled

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **74a8d5** |



#### destructiveColors

| Name        | Type                                              |
| ----------- | ------------------------------------------------- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |

##### destructiveColors.normal

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **ff0000** |

##### destructiveColors.highlighted

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **ff3f3f** |

##### destructiveColors.disabled

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **ff3f3f** |

#### 

### Tint Color

| Name      | Type    | Mapping Name | Value      |
| --------- | ------- | ------------ | ---------- |
| tintColor | UIColor |              | **468cc8** |



### Favorite Color

| Name                  | Type    | Mapping Name | Value      |
| --------------------- | ------- | ------------ | ---------- |
| favoriteEnabledColor  | UIColor |              | **ffcc00** |
| favoriteDisabledColor | UIColor |              | **7c7c7c** |

------



# Color Themes

All customizable theme color values are defined in these available themes:

### Dark

[Dark color scheme](./Dark-scheme.md)

### Light

[Light color scheme](./Light-scheme.md)

### Classic

[Classic color scheme](./Classic-scheme.md)

