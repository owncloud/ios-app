# Classic Color Scheme Guide

[TOC]



## Bars

| Name                                | Type                                                         | Mapping Name | Value             |
| ----------------------------------- | ------------------------------------------------------------ | ------------ | ----------------- |
| navigationBarColors                 | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |              |                   |
| toolbarColors                       | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |              |                   |
| statusBarStyle                      | UIStatusBar.Style                                            |              | **.lightContent** |
| barStyle                            | UIBar.Style                                                  |              | **.black**        |
| activityIndicatorViewStyle          | UIActivityIndicatorView.Style                                |              | **.gray**         |
| searchBarActivityIndicatorViewStyle | UIActivityIndicatorView.Style                                |              | **.white**        |

### Bars.navigationBarColors

| Name                      | Type                                                         | Mapping Name | Value      |
| ------------------------- | ------------------------------------------------------------ | ------------ | ---------- |
| backgroundColor           | UIColor                                                      |              | **1d293b** |
| labelColor                | UIColor                                                      |              | **ffffff** |
| secondaryLabelColor       | UIColor                                                      |              | **aaaaaa** |
| symbolColor               | UIColor                                                      |              | **ffffff** |
| tintColor                 | UIColor                                                      |              | **6ba3d3** |
| filledColorPairCollection | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) | -            |            |

#### Bars.navigationBarColors.filledColorPairCollection

| Name        | Type                                              |
| ----------- | ------------------------------------------------- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |

##### Bars.navigationBarColors.filledColorPairCollection.normal

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **1d293b** |

##### Bars.navigationBarColors.filledColorPairCollection.highlighted

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **555e6c** |

##### Bars.navigationBarColors.filledColorPairCollection.disabled

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **555e6c** |

### Bars.toolbarColors

| Name                      | Type                                                         | Mapping Name | Value      |
| ------------------------- | ------------------------------------------------------------ | ------------ | ---------- |
| backgroundColor           | UIColor                                                      |              | **1d293b** |
| labelColor                | UIColor                                                      |              | **ffffff** |
| secondaryLabelColor       | UIColor                                                      |              | **aaaaaa** |
| symbolColor               | UIColor                                                      |              | **ffffff** |
| tintColor                 | UIColor                                                      |              | **6ba3d3** |
| filledColorPairCollection | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) | -            |            |

#### Bars.toolbarColors.filledColorPairCollection

| Name        | Type                                              |
| ----------- | ------------------------------------------------- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |

##### Bars.toolbarColors.filledColorPairCollection.normal

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **1d293b** |

##### Bars.toolbarColors.filledColorPairCollection.highlighted

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **555e6c** |

##### Bars.toolbarColors.filledColorPairCollection.disabled

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **555e6c** |

## Progress

| Name           | Type                                              |
| -------------- | ------------------------------------------------- |
| progressColors | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |

### Progress.progressColors

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **468cc8** |
| background | UIColor |              | **aaaaaa** |



## Icon colors

| Name            | Type    | Mapping Name | Value      |
| --------------- | ------- | ------------ | ---------- |
| folderFillColor | UIColor |              | **1d293b** |
| fileFillColor   | UIColor |              | **1d293b** |
| logoFillColor   | UIColor |              | **aaaaaa** |
| iconFillColor   | UIColor |              | **1d293b** |
| symbolFillColor | UIColor |              | **1d293b** |



## Table view

| Name                      | Type                                                         | Mapping Name | Value      |
| ------------------------- | ------------------------------------------------------------ | ------------ | ---------- |
| tableBackgroundColor      | UIColor                                                      |              | **ffffff** |
| tableGroupBackgroundColor | UIColor                                                      |              | **efeff4** |
| tableSeparatorColor       | UIColor                                                      |              | -          |
| tableRowBorderColor       | UIColor                                                      |              | **000000** |
| tableRowColors            | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |              |            |
| tableRowHighlightColors   | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |              |            |



### TableView.tableRowColors

| Name                      | Type                                                         | Mapping Name | Value      |
| ------------------------- | ------------------------------------------------------------ | ------------ | ---------- |
| backgroundColor           | UIColor                                                      |              | **ffffff** |
| labelColor                | UIColor                                                      |              | **000000** |
| secondaryLabelColor       | UIColor                                                      |              | **7f7f7f** |
| symbolColor               | UIColor                                                      |              | **1d293b** |
| tintColor                 | UIColor                                                      |              | -          |
| filledColorPairCollection | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) |              |            |



#### TableView.tableRowColor.filledColorPairCollection

| Name        | Type                                              |
| ----------- | ------------------------------------------------- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |



##### TableView.tableRowColor.filledColorPairCollection.normal

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **468cc8** |



##### TableView.tableRowColor.filledColorPairCollection.highlighted

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **74a8d5** |



##### TableView.tableRowColor.filledColorPairCollection.disabled

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **74a8d5** |



### TableView.tableRowHighlightColors

| Name                      | Type                                                         | Mapping Name | Value      |
| ------------------------- | ------------------------------------------------------------ | ------------ | ---------- |
| backgroundColor           | UIColor                                                      |              | -          |
| labelColor                | UIColor                                                      |              | **000000** |
| secondaryLabelColor       | UIColor                                                      |              | **7f7f7f** |
| symbolColor               | UIColor                                                      |              | **1d293b** |
| tintColor                 | UIColor                                                      |              | -          |
| filledColorPairCollection | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) |              |            |



#### TableView.tableRowHighlightColors.filledColorPairCollection

| Name        | Type                                              |
| ----------- | ------------------------------------------------- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |



##### TableView.tableRowHighlightColors.filledColorPairCollection.normal

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **468cc8** |



##### TableView.tableRowHighlightColors.filledColorPairCollection.highlighted

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **74a8d5** |



##### TableView.tableRowHighlightColors.filledColorPairCollection.disabled

| Name       | Type    | Mapping Name | Value      |
| ---------- | ------- | ------------ | ---------- |
| foreground | UIColor |              | **ffffff** |
| background | UIColor |              | **74a8d5** |

