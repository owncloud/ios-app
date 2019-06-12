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

| Name            | Type    | Mapping Name | Value  |
| --------------- | ------- | ------------ | ------ |
| darkBrandColor  | UIColor |              | 1D293B |
| lightBrandColor | UIColor |              | 468CC8 |

### Brand color collection

| Name             | Type                                                         |
| ---------------- | ------------------------------------------------------------ |
| darkBrandColors  | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |
| lightBrandColors | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |



#### darkBrandColors

| Name                      | Type                                                         | Mapping Name | Value               |
| ------------------------- | ------------------------------------------------------------ | ------------ | ------------------- |
| backgroundColor           | UIColor                                                      |              | 1D293B              |
| labelColor                | UIColor                                                      |              | UIColor.white       |
| secondaryLabelColor       | UIColor                                                      |              | UIColor.lightGray   |
| symbolColor               | UIColor                                                      |              | UIColor.white       |
| tintColor                 | UIColor                                                      |              | 468CC8.lighter(0.2) |
| filledColorPairCollection | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) | -            |                     |

##### darkBrandColors.filledColorPairCollection

| Name        | Type                                              | Mapping Name | Value |
| ----------- | ------------------------------------------------- | ------------ | ----- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |

darkBrandColors.filledColorPairCollection.normal

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

darkBrandColors.filledColorPairCollection.highlighted

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

darkBrandColors.filledColorPairCollection.disabled

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

#### lightBrandColors

| Name                      | Type                                                         | Mapping Name | Value               |
| ------------------------- | ------------------------------------------------------------ | ------------ | ------------------- |
| backgroundColor           | UIColor                                                      |              | 1D293B              |
| labelColor                | UIColor                                                      |              | UIColor.white       |
| secondaryLabelColor       | UIColor                                                      |              | UIColor.lightGray   |
| symbolColor               | UIColor                                                      |              | UIColor.white       |
| tintColor                 | UIColor                                                      |              | 468CC8.lighter(0.2) |
| filledColorPairCollection | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) | -            |                     |

##### lightBrandColors,filledColorPairCollection

| Name        | Type                                              |
| ----------- | ------------------------------------------------- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |

lightBrandColors.filledColorPairCollection.normal

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

lightBrandColors.filledColorPairCollection.highlighted

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

lightBrandColors.filledColorPairCollection.disabled

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

#### 

### Label colors

| Name             | Type    | Mapping Name | Value            |
| ---------------- | ------- | ------------ | ---------------- |
| informativeColor | UIColor |              | UIColor.darkGray |
| successColor     | UIColor |              | 27AE60           |
| warningColor     | UIColor |              | F2994A           |
| errorColor       | UIColor |              | EB5757           |



### Button / Fill color collections

| Name              | Type                                                         |
| ----------------- | ------------------------------------------------------------ |
| approvalColors    | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) |
| neutralColors     | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) |
| destructiveColors | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) |



#### approvalColors

| Name        | Type                                              | Mapping Name | Value |
| ----------- | ------------------------------------------------- | ------------ | ----- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |

##### approvalColors.normal

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

##### approvalColors.highlighted

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

##### approvalColors.disabled

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |



#### neutralColors

| Name        | Type                                              | Mapping Name | Value |
| ----------- | ------------------------------------------------- | ------------ | ----- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |

##### neutralColors.normal

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

##### neutralColors.highlighted

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

##### neutralColors.disabled

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |



#### destructiveColors

| Name        | Type                                              | Mapping Name | Value |
| ----------- | ------------------------------------------------- | ------------ | ----- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |

##### destructiveColors.normal

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

##### destructiveColors.highlighted

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

##### destructiveColors.disabled

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

#### 

### Tint Color

| Name      | Type    | Mapping Name | Value           |
| --------- | ------- | ------------ | --------------- |
| tintColor | UIColor |              | lightBrandColor |



### Favorite Color

| Name                  | Type    | Mapping Name | Value  |
| --------------------- | ------- | ------------ | ------ |
| favoriteEnabledColor  | UIColor |              | FFCC00 |
| favoriteDisabledColor | UIColor |              | 7C7C7C |

------



# Color Themes

All customizable theme color values are defined in these available themes:

### Dark

[Dark color scheme](./Dark-scheme.md)

### Light

[Light color scheme](./Light-scheme.md)

### Classic

[Classic color scheme](./Classic-scheme.md)

