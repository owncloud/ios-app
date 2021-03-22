# Configuration

## Introduction

The ownCloud iOS App provides a flexible mechanism for configuration. While it currently only returns the default values defined by the classes itself, MDM and branding support can be added in the future with relatively little effort.

This document provides an overview over the available sections and variables.

## App

- **Section ID**: `app`

- **Variables**:
	- `show-beta-warning`: Controls whether a warning should be shown on the first run of a beta version.
		- type: Bool
		- default: `true`
	- `is-beta-build`: Controls if the app is built for beta or release purposes.
		- type: Bool
		- default: `false`
	- `app-store-link` : Points to the app's link in the app store.
		- type: String
		- default: `https://itunes.apple.com/app/id1359583808?mt=8`
	- `feedback-email` : Email to send the feedback mail.
		- type: String
		- default: `ios-app@owncloud.com`
	- `recommend-to-friend-enabled` : Option to send en email with the App Store link.
		- type: Bool
		- default: `true`
	- `send-feedback-enabled`: Send an email to feedback-email with some feedback.
		- type: Bool
		- default: `true`
		
## Bookmarks

- **Section ID**: `bookmark`

- **Variables**:
	- `default-url`: Set a default server URL.
		- type: String
		- default: `""`
	- `url-editable`: Being able to edit the server URL in the URL TextField.
		- type: Bool
		- default: `true`


## Diagnostics

- **Section ID**: `diagnostics`

- **Variables**:
	- `enabled`: Controls whether additional diagnostic options and information is available throughout the user interface.
		- type: Bool
		- default: `false`

## Display Settings

- **Section ID**: `display`

- **Variables**:
	- `show-hidden-files`: Controls whether hidden files (i.e. files starting with `.` ) should also be shown
		- type: Bool
		- default: `false`
	- `sort-folders-first`: Controls whether folders are shown at the top
		- type: Bool
		- default: `false`
	- `prevent-dragging-files`: Controls whether drag and drop should be prevented for items inside the app 
		- type: Bool
		- default: `false`

## File Provider

- **Section ID**: `file-provider`

- **Variables**:
	- `skip-local-error-checks` : If TRUE, skips some local error checks in the FileProvider to easily provoke errors. (for testing only) 
		- type: Bool
		- default: `false`

## Shortcuts

- **Section ID**: `shortcuts`

- **Variables**:
	- `enabled`: Controls whether Shortcuts support is enabled
		- type: Bool
		- default: `true`
