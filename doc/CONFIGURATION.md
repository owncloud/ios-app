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
	
## Feedback

- **Section ID**: `feedback`

- **Variables**:
	- app-store-link : Points to the app's link in the app store.
		- type: String
		- default: `https://itunes.apple.com/app/id1359583808?mt=8`
	- feedback-email : Email to send the feedback mail.
		- type: String
		- default: `ios-app@owncloud.com`
	- recommend-to-friend-enabled : Option to send en email with the App Store link.
		- type: Bool
		- default: `true`
	- send-feedback-enabled : Send an email to feedback-email with some feedback.
		- type: Bool
		-default: `true`
		
## Bookmarks

- **Section ID**: `bookmark`

- **Variables**:
	- `default-url`: Set a default server URL.
		- type: String
		- default: `""`
	- `url-editable`: Being able to edit the server URL in the URL TextField.
		- type: Bool
		- default: `true`

