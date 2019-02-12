## AppConfig how to

### Managed App Config
Starting with iOS7, Apple has added support for managed application configuration. MDM server can push configuration to the app. The app can the access the configuration using NSUserDefaults class. The configuration is basically a key-value dictionary provided as .plist file.

### AppConfig XML Schema
The XML format developed by AppConfig community, makes it easy for developers to define and deploy app configuration. It is not only defining the configuration variables with default value but also provides a configuration UI description which can be interpreted by the tool which generates a plist file. Moreover, specfile XML is consistently supported by major EMM vendors.

### Example: Deployment with Mobile Iron
1. Open AppConfig Generator: https://appconfig.jamfresearch.com
2. Upload a specfile.xml
3. Change configuration options
4. Download generated plist file (ManagedAppConfig)
5. Open Mobile Iron Core
6. Navigate to "Policies and Configs" -> "Add New" -> "Apple" -> "iOS/tvOS" -> "Managed App Config"
7. Upload generated plist and specify name, bundle ID and description

### References
- <https://www.appconfig.org>
- <https://developer.apple.com/business/documentation/MDM-Protocol-Reference.pdf>

