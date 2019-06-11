#Color Scheme Guide

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

| Name        | Type           |
| ----------- | -------------- |
| normal      | ThemeColorPair |
| highlighted | ThemeColorPair |
| disabled    | ThemeColorPair |



### ThemeColorCollection

Used in for tableRowColors, tableRowHighlightColors, navigationBarColors, toolbarColors, darkBrandColors, lightBrandColors

| Name                      | Type                                                  | Sample | Value |
| ------------------------- | ----------------------------------------------------- | ------ | ----- |
| backgroundColor           | UIColor                                               |        |       |
| labelColor                | UIColor                                               |        |       |
| secondaryLabelColor       | UIColor                                               |        |       |
| symbolColor               | UIColor                                               |        |       |
| tintColor                 | UIColor                                               |        |       |
| filledColorPairCollection | [ThemeColorPairCollection](#ThemeColorPairCollection) |        |       |

### 

## Colors and Color Collections (ThemeCollection)

This colors and color collections are not branded and always the same, regardless of which theme style is selected. All these values can be customized via branding themes, but this needs code changes.

### Brand colors

| Name            | Type    | Sample | Value  |
| --------------- | ------- | ------ | ------ |
| darkBrandColor  | UIColor |        | 1D293B |
| lightBrandColor | UIColor |        | 468CC8 |

### Brand color collection

| Name             | Type                 | Sample | Value |
| ---------------- | -------------------- | ------ | ----- |
| darkBrandColors  | ThemeColorCollection |        |       |
| lightBrandColors | ThemeColorCollection |        |       |



#### darkBrandColors

| Name                      | Type                     | Sample | Value               |
| ------------------------- | ------------------------ | ------ | ------------------- |
| backgroundColor           | UIColor                  |        | 1D293B              |
| labelColor                | UIColor                  |        | UIColor.white       |
| secondaryLabelColor       | UIColor                  |        | UIColor.lightGray   |
| symbolColor               | UIColor                  |        | UIColor.white       |
| tintColor                 | UIColor                  |        | 468CC8.lighter(0.2) |
| filledColorPairCollection | ThemeColorPairCollection |        |                     |

##### filledColorPairCollection

| Name        | Type           | Sample | Value |
| ----------- | -------------- | ------ | ----- |
| normal      | ThemeColorPair |        |       |
| highlighted | ThemeColorPair |        |       |
| disabled    | ThemeColorPair |        |       |



#### lightBrandColors

| Name                      | Type                     | Sample | Value               |
| ------------------------- | ------------------------ | ------ | ------------------- |
| backgroundColor           | UIColor                  |        | 1D293B              |
| labelColor                | UIColor                  |        | UIColor.white       |
| secondaryLabelColor       | UIColor                  |        | UIColor.lightGray   |
| symbolColor               | UIColor                  |        | UIColor.white       |
| tintColor                 | UIColor                  |        | 468CC8.lighter(0.2) |
| filledColorPairCollection | ThemeColorPairCollection |        |                     |

##### filledColorPairCollection

| Name        | Type           | Sample | Value |
| ----------- | -------------- | ------ | ----- |
| normal      | ThemeColorPair |        |       |
| highlighted | ThemeColorPair |        |       |
| disabled    | ThemeColorPair |        |       |



### Label colors

| Name             | Type    | Sample | Value            |
| ---------------- | ------- | ------ | ---------------- |
| informativeColor | UIColor |        | UIColor.darkGray |
| successColor     | UIColor |        | 27AE60           |
| warningColor     | UIColor |        | F2994A           |
| errorColor       | UIColor |        | EB5757           |



### Button / Fill color collections

| Name              | Type                     | Sample | Value |
| ----------------- | ------------------------ | ------ | ----- |
| approvalColors    | ThemeColorPairCollection |        |       |
| neutralColors     | ThemeColorPairCollection |        |       |
| destructiveColors | ThemeColorPairCollection |        |       |



### Tint Color

| Name      | Type    | Sample | Value |
| --------- | ------- | ------ | ----- |
| tintColor | UIColor |        |       |



------



## Color Themes

All customizable theme color values are defined in these available themes:

### Dark

[Dark color scheme](./Dark-scheme.md)

### Light

[Dark color scheme](./Light-scheme.md)

### Classic

[Dark color scheme](./Classic-scheme.md)

