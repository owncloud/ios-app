# Dark Color Scheme Guide

[TOC]



## Bars

| Name                | Type                                                         | Mapping Name | Value |
| ------------------- | ------------------------------------------------------------ | ------------ | ----- |
| navigationBarColors | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |              |       |
| toolbarColors       | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |              |       |
| statusBarStyle      | UIStatusBarStyle                                             |              |       |
| barStyle            | UIBarStyle                                                   |              |       |

### Bars.navigationBarColors

| Name                      | Type                                                         | Mapping Name | Value |
| ------------------------- | ------------------------------------------------------------ | ------------ | ----- |
| backgroundColor           | UIColor                                                      |              |       |
| labelColor                | UIColor                                                      |              |       |
| secondaryLabelColor       | UIColor                                                      |              |       |
| symbolColor               | UIColor                                                      |              |       |
| tintColor                 | UIColor                                                      |              |       |
| filledColorPairCollection | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) | -            |       |

#### Bars.navigationBarColors.filledColorPairCollection

| Name        | Type                                              | Mapping Name | Value |
| ----------- | ------------------------------------------------- | ------------ | ----- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |

##### Bars.navigationBarColors.filledColorPairCollection.normal

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

##### Bars.navigationBarColors.filledColorPairCollection.highlighted

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

##### Bars.navigationBarColors.filledColorPairCollection.disabled

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

### Bars.toolbarColors

| Name                      | Type                                                         | Mapping Name | Value |
| ------------------------- | ------------------------------------------------------------ | ------------ | ----- |
| backgroundColor           | UIColor                                                      |              |       |
| labelColor                | UIColor                                                      |              |       |
| secondaryLabelColor       | UIColor                                                      |              |       |
| symbolColor               | UIColor                                                      |              |       |
| tintColor                 | UIColor                                                      |              |       |
| filledColorPairCollection | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) | -            |       |

#### Bars.toolbarColors.filledColorPairCollection

| Name        | Type                                              | Mapping Name | Value |
| ----------- | ------------------------------------------------- | ------------ | ----- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |

##### Bars.toolbarColors.filledColorPairCollection.normal

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

##### Bars.toolbarColors.filledColorPairCollection.highlighted

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

##### Bars.toolbarColors.filledColorPairCollection.disabled

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

#### 

## Progress

| Name           | Type                                              | Mapping Name | Value |
| -------------- | ------------------------------------------------- | ------------ | ----- |
| progressColors | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |              |       |

### Progress.progressColors

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |



## Icon colors

| Name            | Type    | Mapping Name | Value |
| --------------- | ------- | ------------ | ----- |
| folderFillColor | UIColor |              |       |
| fileFillColor   | UIColor |              |       |
| logoFillColor   | UIColor |              |       |
| iconFillColor   | UIColor |              |       |
| symbolFillColor | UIColor |              |       |



## Table view

| Name                      | Type                                                         | Mapping Name | Value                                            |
| ------------------------- | ------------------------------------------------------------ | ------------ | ------------------------------------------------ |
| tableBackgroundColor      | UIColor                                                      |              | navigationBarColors.backgroundColor!.darker(0.1) |
| tableGroupBackgroundColor | UIColor                                                      |              | navigationBarColors.backgroundColor!.darker(0.3) |
| tableSeparatorColor       | UIColor                                                      |              | UIColor.darkGray                                 |
| tableRowBorderColor       | UIColor                                                      |              | UIColor.white.withAlphaComponent(0.1)            |
| tableRowColors            | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |              |                                                  |
| tableRowHighlightColors   | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |              |                                                  |



### TableView.tableRowColors

| Name                      | Type                                                         | Mapping Name | Value                                   |
| ------------------------- | ------------------------------------------------------------ | ------------ | --------------------------------------- |
| backgroundColor           | UIColor                                                      |              | tableBackgroundColor                    |
| labelColor                | UIColor                                                      |              | navigationBarColors.labelColor          |
| secondaryLabelColor       | UIColor                                                      |              | navigationBarColors.secondaryLabelColor |
| symbolColor               | UIColor                                                      |              | 468CC8                                  |
| tintColor                 | UIColor                                                      |              | navigationBarColors.tintColor           |
| filledColorPairCollection | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) |              |                                         |



#### TableView.tableRowColor.filledColorPairCollection

| Name        | Type                                              |
| ----------- | ------------------------------------------------- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |



##### TableView.tableRowColor.filledColorPairCollection.normal

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |



##### TableView.tableRowColor.filledColorPairCollection.highlighted

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |



##### TableView.tableRowColor.filledColorPairCollection.disabled

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |



### TableView.tableRowHighlightColors

| Name                      | Type                                                         | Mapping Name | Value                                   |
| ------------------------- | ------------------------------------------------------------ | ------------ | --------------------------------------- |
| backgroundColor           | UIColor                                                      |              | tableBackgroundColor                    |
| labelColor                | UIColor                                                      |              | navigationBarColors.labelColor          |
| secondaryLabelColor       | UIColor                                                      |              | navigationBarColors.secondaryLabelColor |
| symbolColor               | UIColor                                                      |              | 468CC8                                  |
| tintColor                 | UIColor                                                      |              | navigationBarColors.tintColor           |
| filledColorPairCollection | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) |              |                                         |



#### TableView.tableRowHighlightColors.filledColorPairCollection

| Name        | Type                                              |
| ----------- | ------------------------------------------------- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |



##### TableView.tableRowHighlightColors.filledColorPairCollection.normal

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |



##### TableView.tableRowHighlightColors.filledColorPairCollection.highlighted

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |



##### TableView.tableRowHighlightColors.filledColorPairCollection.disabled

| Name       | Type    | Mapping Name | Value |
| ---------- | ------- | ------------ | ----- |
| foreground | UIColor |              |       |
| background | UIColor |              |       |

