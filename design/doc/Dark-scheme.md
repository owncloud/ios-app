# Dark Color Scheme Guide

[TOC]



## Bars

| Name                | Type                                                         | Sample | Value |
| ------------------- | ------------------------------------------------------------ | ------ | ----- |
| navigationBarColors | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |        |       |
| toolbarColors       | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |        |       |
| statusBarStyle      | UIStatusBarStyle                                             |        |       |
| barStyle            | UIBarStyle                                                   |        |       |



## Progress

| Name           | Type                                              | Sample | Value |
| -------------- | ------------------------------------------------- | ------ | ----- |
| progressColors | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |        |       |



## Icon colors

| Name            | Type    | Sample | Value |
| --------------- | ------- | ------ | ----- |
| folderFillColor | UIColor |        |       |
| fileFillColor   | UIColor |        |       |
| logoFillColor   | UIColor |        |       |
| iconFillColor   | UIColor |        |       |
| symbolFillColor | UIColor |        |       |



## Table view

| Name                      | Type                                                         | Sample | Value                                            |
| ------------------------- | ------------------------------------------------------------ | ------ | ------------------------------------------------ |
| tableBackgroundColor      | UIColor                                                      |        | navigationBarColors.backgroundColor!.darker(0.1) |
| tableGroupBackgroundColor | UIColor                                                      |        | navigationBarColors.backgroundColor!.darker(0.3) |
| tableSeparatorColor       | UIColor                                                      |        | UIColor.darkGray                                 |
| tableRowBorderColor       | UIColor                                                      |        | UIColor.white.withAlphaComponent(0.1)            |
| tableRowColors            | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |        |                                                  |
| tableRowHighlightColors   | [ThemeColorCollection](./Colorscheme.md#ThemeColorCollection) |        |                                                  |



### TableView.tableRowColors

| Name                      | Type                                                         | Sample | Value                                   |
| ------------------------- | ------------------------------------------------------------ | ------ | --------------------------------------- |
| backgroundColor           | UIColor                                                      |        | tableBackgroundColor                    |
| labelColor                | UIColor                                                      |        | navigationBarColors.labelColor          |
| secondaryLabelColor       | UIColor                                                      |        | navigationBarColors.secondaryLabelColor |
| symbolColor               | UIColor                                                      |        | 468CC8                                  |
| tintColor                 | UIColor                                                      |        | navigationBarColors.tintColor           |
| filledColorPairCollection | [ThemeColorPairCollection](./Colorscheme.md#ThemeColorPairCollection) |        |                                         |



#### TableView.tableRowColor.filledColorPairCollection

| Name        | Type                                              | Sample | Value         |
| ----------- | ------------------------------------------------- | ------ | ------------- |
| normal      | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |        | UIColor.white |
| highlighted | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |        |               |
| disabled    | [ThemeColorPair](./Colorscheme.md#ThemeColorPair) |        |               |



##### TableView.tableRowColor.filledColorPairCollection.normal

| Name       | Type    | Sample | Value |
| ---------- | ------- | ------ | ----- |
| foreground | UIColor |        |       |
| background | UIColor |        |       |



##### TableView.tableRowColor.filledColorPairCollection.highlighted

| Name       | Type    | Sample | Value |
| ---------- | ------- | ------ | ----- |
| foreground | UIColor |        |       |
| background | UIColor |        |       |



##### TableView.tableRowColor.filledColorPairCollection.disabled

| Name       | Type    | Sample | Value |
| ---------- | ------- | ------ | ----- |
| foreground | UIColor |        |       |
| background | UIColor |        |       |

