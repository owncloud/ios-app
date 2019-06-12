# Dark Color Scheme Guide

[TOC]



## Bars

| Name                                | Type                                                         | Mapping Name | Value             |
| ----------------------------------- | ------------------------------------------------------------ | ------------ | ----------------- |
| navigationBarColors                 | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |              |                   |
| toolbarColors                       | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |              |                   |
| statusBarStyle                      | UIStatusBar.Style                                            |              | **.lightContent** |
| barStyle                            | UIBar.Style                                                  |              | **.black**        |
| activityIndicatorViewStyle          | UIActivityIndicatorView.Style                                |              | **.white**        |
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
| background | UIColor |              | **468cc8** |



## Icon colors

| Name            | Type    | Mapping Name | Value      |
| --------------- | ------- | ------------ | ---------- |
| folderFillColor | UIColor |              | **468cc8** |
| fileFillColor   | UIColor |              | **468cc8** |
| logoFillColor   | UIColor |              | **ffffff** |
| iconFillColor   | UIColor |              | **6ba3d3** |
| symbolFillColor | UIColor |              | **468cc8** |



## Table view

| Name                      | Type                                                         | Mapping Name | Value      |
| ------------------------- | ------------------------------------------------------------ | ------------ | ---------- |
| tableBackgroundColor      | UIColor                                                      |              | **1a2435** |
| tableGroupBackgroundColor | UIColor                                                      |              | **141c29** |
| tableSeparatorColor       | UIColor                                                      |              | **555555** |
| tableRowBorderColor       | UIColor                                                      |              | **ffffff** |
| tableRowColors            | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |              |            |
| tableRowHighlightColors   | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |              |            |



### TableView.tableRowColors

| Name                      | Type                                                         | Mapping Name | Value      |
| ------------------------- | ------------------------------------------------------------ | ------------ | ---------- |
| backgroundColor           | UIColor                                                      |              | **1a2435** |
| labelColor                | UIColor                                                      |              | **ffffff** |
| secondaryLabelColor       | UIColor                                                      |              | **aaaaaa** |
| symbolColor               | UIColor                                                      |              | **468cc8** |
| tintColor                 | UIColor                                                      |              | **6ba3d3** |
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
| backgroundColor           | UIColor                                                      |              | **3870a0** |
| labelColor                | UIColor                                                      |              | **ffffff** |
| secondaryLabelColor       | UIColor                                                      |              | **ffffff** |
| symbolColor               | UIColor                                                      |              | **1d293b** |
| tintColor                 | UIColor                                                      |              | **ffffff** |
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

