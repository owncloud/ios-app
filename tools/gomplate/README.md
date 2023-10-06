# Create Branding.plist from JSON

Prerequisite:

```
brew install gomplate
```

Create `ownCloud/Resources/Theming/Branding.json`


```
{
    "ios_branding.organization-name_text": "Example Cloud",
    "ios_branding.profile-bookmark-name_text": "Example Cloud",
    "ios_branding.theme-definitions$[0].darkBrandColor_color": "#5BB75B",
    "ios_branding.theme-definitions$[0].lightBrandColor_color": "#000000",
    "ios_branding.send-feedback-address_text": "mail@example.com",
    "ios_branding.profile-url_text": "https://demo.owncloud.com",
    "ios_branding.navigation.style_select": "colored",
    "ios_branding.profile-help-url_text": "",
    "ios_branding.profile-help-button-label_text": "",
    "ios_branding.profile-open-help-message_text": "",
    "ios_branding.style_select": "light",
}
```

Then execute `gomplate` to create your `ownCloud/Resources/Theming/Branding.plist`

```
gomplate --file ./tools/gomplate/Branding.plist.tmpl \
--context config=./ownCloud/Resources/Theming/Branding.json \
--out ./ownCloud/Resources/Theming/Branding.plist
```
