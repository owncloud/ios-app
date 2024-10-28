#  Account Setup and Authentication

This document gives you an overview over the flow and internals when setting up a new account using `BookmarkComposer`. Where other components and configuration options are involved, a reference is given to the respective code part.

## Terminology

Variables are written in the form `$varName`. Where they occur in HTTP requests and responses, they should be replaced with their actual value.

MDM configuration and `Branding.plist` parameter names are written in the form `category.parameter-name`. The reference for these parameters is available on [doc.owncloud.com](https://doc.owncloud.com/ios-app/next/appendices/mdm.html).

## URL Overview

The following table contains all URLs that can be requested during Account Setup:

Endpoint 		 | Phase                                 | Method             | URL                                                                                  | Comments
-------------------------|---------------------------------------|--------------------|--------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------
WebFinger		 | Server Instance Lookup                | `GET`              | `$serverURL/.well-known/webfinger?resource=acct:user@example.com&rel=http%3A%2F%2Fwebfinger.owncloud%2Frel%2Fserver-instance` | Only used if `server-locator.use` is set.
WebFinger 		 | OpenID Connect Discovery              | `GET`              | `$serverURL/.well-known/webfinger?resource=$serverURL`                               | Used to parametrize Auth Method Discovery.
Status                   | Server Compatibility                  | `GET`              | `$serverURL/status.php`                                                              | Used to check if $serverURL points to a server running compatible software.
WebDAV			 | Auth Method Discovery                 | `PROPFIND`         | `$serverURL/remote.php/dav/files`                                                    | Used by Basic Auth, OAuth2 and OIDC - skipped if `$skipWWWAuthenticateChecks` is `true`.
OAuth2 Token             | Auth Method Discovery                 | `GET`              | `$serverURL/index.php/apps/oauth2/api/v1/token`                                      | Used by OAuth2.
OpenID Configuration     | Auth Method Discovery, Authentication | `GET`              | `$serverURL/.well-known/openid-configuration` (or `$alternateIDPBaseURL` if set)     | Used by OIDC.
Capabilities             | Authentication, Server Info Retrieval | `GET`              | `$serverURL/ocs/v2.php/cloud/capabilities`                                           | Used by Basic Auth to check validity of username/password.
OAuth2 Authorization     | Authentication                        | `GET`              | `$serverURL/index.php/apps/oauth2/authorize?$oauth2Parameters`                       | Used by OAuth2, sent by a webview.
OAuth2 Token             | Authentication                        | `POST`             | `$serverURL/index.php/apps/oauth2/api/v1/token`                                      | Used by OAuth2 for token retrieval and refresh.
User Endpoint            | Authentication, Server Info Retrieval | `GET`              | `$serverURL/ocs/v2.php/cloud/user`                                                   | Used by OAuth2 and OIDC to obtain the User ID.
OIDC Authorization       | Authentication                        | `GET`              | `authorization_endpoint` from OpenID Configuration                                   | Used by OIDC.
OIDC Token               | Authentication                        | `POST`             | `token_endpoint` from OpenID Configuration                                           | Used by OIDC.
WebFinger                | Authenticated Server Discovery        | `GET`              | `$serverURL/.well-known/webfinger?resource=acct:me@$serverURLHostname` (`$webFingerAccountLookupURL`) | Used to discover server instances for an authenticated user.
Graph API Drive List     | Server Info Retrieval                 | `GET`              | `$serverURL/graph/v1.0/me/drives`                                                    | Used during the final step of retrieving information about the server.

## Server URL normalization and parsing (`BookmarkComposer.enterURL()`)

The URL of a server can be provided by the user (via `BookmarkSetupStepEnterURLViewController`) or via Branding / MDM configuration (via `branding.profile-url`).

The URL string is then inspected and processed in the following order by the SDK's `NSURL+OCURLNormalization`:
1) whitespace and newline characters are removed from the beginning and end of the URL string
2) trailing occurences of `/index.php` are removed
3) search for `/index.php/apps/` and removal of anything before its start
4) check for existance of schemes, prepending `https://` in case none was provided in the URL string
5) look for and extract provided username and password (f.ex. `https://user:pass@hostname/`) into `$username` and `$password` to make them available to authentication methods lateron
6) ensure root URLs end with a slash (`/`) - f.ex. `https://demo.owncloud.com``/`

The resulting URL is saved in `$serverURL`.

## Server location and authentication method probing (`BookmarkComposer.enterURL()`)

This invokes the SDK's `-[OCConnection prepareForSetupWithOptions:]` to determine the final server location (URL), the available authentication methods - and which one should be used.

This SDK method performs the following steps:

### Plain HTTP check

Checks if `$serverURL` uses plain `http` and, if it does, warn the user and ask for confirmation before proceeding. This behavior can be changed via `connection.plain-http-policy`.

### Server Instance lookup (optional)

If a server locator module is provided via `server-locator.use`, an existing or entered username (via `BookmarkComposer.enterUsername()` or `BookmarkSetupStepEnterUsernameViewController`) is used to determine the URL of the server the user's account is hosted on.

If the `web-finger` server locator (implemented in the SDK as `OCServerLocatorWebFinger`) has been configured, the client sends a request to the `$serverURL`:

```
GET /.well-known/webfinger?resource=acct:user@example.com&rel=http%3A%2F%2Fwebfinger.owncloud%2Frel%2Fserver-instance HTTP/1.1
```

If the user is known on the server, it responds with a JSON body containing the URL of the server to use in the next steps:

```json
{
	"links" : {
		{
			"rel" : "http://webfinger.owncloud/rel/server-instance",
			"href" : "https://otherserver.example.com/"
		}
	}
}
```

The example shows only the part used by the `OCServerLocatorWebFinger`. Actual responses may (and typically do) contain additional content.

The first entry's `href` whose `rel` is `http://webfinger.owncloud/rel/server-instance` is henceforth used as new `$serverURL`.

For security reasons, [Authenticated Instance Discovery](https://doc.owncloud.com/ocis/next/deployment/services/s-list/webfinger.html#authenticated-instance-discovery) should be used instead of Server Instance Lookup whereever possible.

### Perform OpenID Connect Discovery

The SDK first checks, if OpenID Connect is an allowed Authentication Method (which is the case if `connection.allowed-authentication-methods` contains `com.owncloud.openid-connect`) - which it is by default. If it is not allowed, this step is skipped.

During [OpenID Connect Discovery](https://doc.owncloud.com/ocis/next/deployment/services/s-list/webfinger.html#openid-connect-discovery), a `GET` request is sent to `$serverURL/.well-known/webfinger?resource=$serverURL`.

If the server responds with an error status code, the SDK proceeds to the next step.

If the server responds with a success status code and a JSON body, the SDK checks that `subject` is identical to `$serverURL` and then looks for a `http://openid.net/specs/connect/1.0/issuer` `rel`ation in the `links` section.

If that relation exists, it derives the following variable values for later usage:
- `$alternateIDPBaseURL`: the aforementioned value for `href`.
- `$authenticationRefererURL`: is set to `$serverURL`.
- `$webFingerAccountLookupURL`: is set to `$serverURL/.well-known/webfinger?resource=acct:me@$serverURLHostname` (f.ex. `https://demo.owncloud.com/.well-known/webfinger?resource=acct:me@demo.owncloud.com`)

Example response:
```json
{
	"subject": "$serverURL",
	"links": [
		{
			"rel": "http://openid.net/specs/connect/1.0/issuer",
			"href": "https://idp.example.com/"
		}
	]
}
```

The SDK then proceeds to the next step.

### Query `status.php`

A `GET` request is sent to `$serverURL/status.php`.

If the response comes back with an error status, the user is informed that a connection is not possible.

If the response comes back with a `301 Moved Permanently` status, the SDK follows [this logic](https://github.com/owncloud/administration/blob/master/redirectServer/Readme.md) to determine a new URL for `$serverURL` based on the `Location`, asks the user for confirmation, uses the determined new URL as `$serverURL` if the user agrees and restarts this step with the new URL.

If the response comes back with a success status, it typically looks like this:
```
{
    "installed": true,
    "maintenance": false,
    "needsDbUpgrade": false,
    "version": "10.11.0.0",
    "versionstring": "10.11.0",
    "edition": "Community",
    "productname": "Infinite Scale",
    "product": "Infinite Scale",
    "productversion": "6.6.1"
}
```

The SDK then looks at the following keys:
- `version`: is compared to `connection.minimum-server-version` and an error is presented to the user if the value is lower.
- `productname`: is compared to known incompatible versions and an error is presented to the user if one is recognized.

If no errors occur or have been detected, the SDK then proceeds to the next step.

### Probe authentication methods

Next, the SDK prepares the parameters that are then provided to the Authentication Methods to perform auto detection of available authentication methods:

Variable                     | Value / Origin
-----------------------------|--------------------------------------------------------------------------------
`$alternateIDPBaseURL`       | Not set by default; set only after and by successful OpenID Connect Discovery.
`$authenticationRefererURL`  | Not set by default; set only after and by successful OpenID Connect Discovery.
`$webFingerAccountLookupURL` | Not set by default; set only after and by successful OpenID Connect Discovery.
`$skipWWWAuthenticateChecks` | Defaults to `false`, set to `true` if OpenID Connect Discovery was successful. Can be overriden by setting a value for `authentication.skip-www-authenticate-checks`.
`$wellKnown`                 | Defaults to `.well-known`, can be overridden with `connection.well-known`

The SDK in `-[OCConnection requestSupportedAuthenticationMethodsWithOptions:completionHandler:]` then performs several steps to perform the actual auto detection:

#### Collect requests from the Authentication Methods (Auth Discovery)

Each Authentication Method is asked to provide a list of URLs they need to inspect to determine if the authentication mechanism they implement is supported by the server. To allow maximum flexibility, these URLs are returned from the Authentication Methods in the form of completely parametrized HTTP requests (via `-[OCAuthenticationMethod detectionRequestsForConnection:options:]`).

The SDK combines all returned requests into one list, eliminates duplicate requests and subsequently carries them out.

#### Pass responses to Authentication Methods as starting point for further evaluation

The responses are then passed back to the Authentication Methods for inspection via `-[OCAuthenticationMethod detectAuthenticationMethodSupportForConnection:withServerResponses:options:completionHandler:]`. Based on the responses, the Authentication Methods can perform additional requests and finally inform the SDK whether their respective mechanism is available on the server.

#### Requests and responses by Authentication Method

Endpoint 		 | Method             | URL                                                                                  | Configuration                                  | Usage
-------------------------|--------------------|--------------------------------------------------------------------------------------|------------------------------------------------|----------------------------
WebDAV			 | `PROPFIND`         | `$serverURL/remote.php/dav/files`                                                    | `connection.endpoint-webdav`                   | Basic Auth, OAuth2, (OIDC) - skipped if `$skipWWWAuthenticateChecks` is `true`.
OAuth2 Token Endpoint    | `GET`              | `$serverURL/index.php/apps/oauth2/api/v1/token`                                      | `authentication-oauth2.oa2-token-endpoint`     | OAuth2
OpenID Configuration     | `GET`              | `$serverURL/.well-known/openid-configuration` (or `$alternateIDPBaseURL` if set)     | `connection.well-known`                        | OIDC

##### WebDAV endpoint

For historic reasons (ownCloud 10), the availability of Basic Auth and OAuth2 is determined by the response to an unauthenticated `PROPFIND` request to the WebDAV endpoint. 

This request is skipped if `$skipWWWAuthenticateChecks` is `true`, which is the case when OpenID Connect Discovery was successful or `authentication.skip-www-authenticate-checks` was set to true.

The response's `Www-Authenticate` HTTP header contains a single or multiple (comma-seperated) values:
- `Basic` indicates Basic Auth _is_ available
- `Bearer` indicates OAuth2 and OIDC _may be_ available

##### OAuth2 Token Endpoint

To determine if OAuth2 is available, a `GET` request is sent to the OAuth2 Token Endpoint. If the response comes back with a redirection or `404 Not Found` status code, OAuth2 is considered to be _not_ available.

##### OpenID Configuration

To determine OIDC availability and further parametrization, a `GET` request is sent to the OpenID Configuration endpoint, which is computed from `$serverURL` and `$wellKnown` - or was determined earlier through OpenID Connect Discovery.

If `$authenticationRefererURL` has a value, it is send in the `Referer` header.

Here's an example of a typical request:
```
GET /.well-known/openid-configuration HTTP/1.1
Host: idp.example.com
Referer: https://cloud.example.com/
```

If the response comes back with a success status, its `Content-Type` indicates JSON and its body is valid JSON, OIDC is considered to be supported.

#### Determine Authentication Method to use

All Authentication Method that indicated server support back to the SDK are 
- put in a list
- filtered through `connection.allowed-authentication-method` (if provided) 
- ordered in the order of `connection.preferred-authentication-methods` (by default: `com.owncloud.openid-connect`, `com.owncloud.oauth2`, `com.owncloud.basicauth`)

The first (and thereby "most preferred") Authentication Method in that list is then picked and returned back and used for the next steps.

## Performing Authentication (`BookmarkComposer.authenticate()`)

At this stage, the SDK's `-[OCConnection generateAuthenticationDataWithMethod:options:completionHandler:]` is called by `BookmarkComposer` to perform the actual authentication.

The `OCConnection` method itself calls the respective `-generateBookmarkAuthenticationDataWithConnection:options:completionHandler:` method of the picked Authentication Method, which then performs different actions:

### Basic Auth

This Authentication Method precomputes a HTTP `Authorization` header value based on the username and password that was passed to `BookmarkComposer.authenticate()` and subsequently uses it for all authenticated requests.

To test the validity of the provided username and password, it sends an authenticated `GET` request to the capabilities endpoint at `$serverURL/ocs/v2.php/cloud/capabilities`.

Depending on the response's status code, the response is handled differently:
- success status: the Authentication Method checks the returned data in the body is valid JSON and that `ocs.data` exists in it. It then indicates authentication was successful.
- redirection status: the Authentication Method returns an `OCErrorAuthorizationRedirect` error with redirection target as alternative Server URL.

For all other statuses or failed checks, the Authentication Method returns an `OCErrorAuthorizationFailed` error.

### OAuth2

#### Requesting Authorization

This Authentication Method first composes the following parameters as HTTP query string `$oauth2Parameters`:

Query parameter         | Contents                | Status   | Comment
------------------------|-------------------------|----------|----------------------------------------------------------------------------------
`response_type`         | `code`                  | required | Required by standard.
`client_id`             | configured value        | required | The value of `authentication-oauth2.oa2-client-id` (default: `mxd5OQDk6es5LzOzRvidJNfXLUZS2oN3oUFeXPP8LpPrhx3UroJFduGEYIBOxkY1`).
`redirect_uri`          | configured value        | required | The value of `authentication-oauth2.oa2-redirect-uri` (default: `oc://ios.owncloud.com`).
`state`                 | random UUID             | optional | A pre-filled UUID. See [the specification](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-v2-1-00#section-4.1.1.3) for details.
`user`                  | `$username`             | optional | Filled with pre-provided username (supported by the ownCloud 10 OAuth2 implementation).

It then uses `$serverURL` and the configured OAuth2 Authorization Endpoint path (`authentication-oauth2.oa2-authorization-endpoint`) to compose the `$authorizationURL`:

```
$serverURL/index.php/apps/oauth2/authorize?$oauth2Parameters
````

The `$authorizationURL` is then opened in a webview to present the server's login page and allow the user to log in. On success, the login page eventually opens the custom scheme `redirect_uri` and returns an Authorization Code as parameter:

```
oc://ios.owncloud.com?state=…&code=$authCode&grant_type=authorization_code
```

If `state` is returned, the Authentication Method checks if its value is identical to the value it included in the `$authorizationURL`.
If `code` is returned, the Authentication Method stores it as `$authCode` and proceeds.

#### Requesting the Token

The Token Request URL is based on `$serverURL`, the `authentication-oauth2.oa2-token-endpoint` path and the following parameters:

Parameter         | Contents                | Status      | Comment
------------------|-------------------------|-------------|----------------------------------------------------------------------------------
`grant_type`      | `authorization_code`    | required    | Required by standard.
`code`            | `$authCode`             | required    | Required by standard.
`redirect_uri`    | configured value        | required    | The value of `authentication-oauth2.oa2-redirect-uri` (default: `oc://ios.owncloud.com`).
`client_id`       | configured value        | conditional | The value of `authentication-oauth2.oa2-client-id` (default: `mxd5OQDk6es5LzOzRvidJNfXLUZS2oN3oUFeXPP8LpPrhx3UroJFduGEYIBOxkY1`).
`client_secret`   | configured value        | conditional | The value of `authentication-oauth2.oa2-client-secret` (default: `KFeFWWEZO9TkisIQzR3fo7hfiMXlOpaqP8CFuTbSHzV1TUuGECglPxpiVKJfOXIx`).

As per [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749#section-2.3.1) the Client ID and Client Secret should be sent as Basic Auth encoded username + password pair in the `Authorization` header of the request. Where this is not supported or possible, these values should be provided as query parameters instead by setting `authentication-oauth2.post-client-id-and-secret` to `true`.

The Token Request will typically look like this:
```
POST /index.php/apps/oauth2/api/v1/token HTTP/1.1
Content-Type: application/x-www-form-urlencoded
Authorization: Basic base64($clientID + ":" + $clientSecret)

grant_type=authorization_code&code=as798da897sd9
```

Upon success, the server responds with JSON data similar to this:
```json
{
	"access_token": "eyJhzI1NiIsImtpZ5IiwidHlwCI6InByaXZhdGUtbGciOiJQUa2VIjoiSldUIn0…",
	"refresh_token": "eyJhzI1NiIsImtpZ5IiwidHlwCI6InByaXZhdGUtbGciOiJQUa2VIjoiSldUIn1…",
	"expires_in": 300,
	"user_id": "admin"
}
```

The Authentication Method uses the returned `access_token` to compose an `Authorization` header that will be used to make authenticated requests from then on:

```
Authorization: Bearer $accessToken
```

The Authentication Method then checks if the response included a `user_id`:
- if `user_id` is included, that `user_id` is used.
- if `user_id` is missing, the SDK sends an authenticated request to the user endpoint `$serverURL/ocs/v2.php/cloud/user` to obtain it.

Finally, if no errors occured to this point, the Authentication Method indicates the authentication was successful.

### OpenID Connect (OIDC)

OpenID Connect (OIDC) is based on OAuth2, but extends it with a server-side configuration and addition parameters to the Authorization URL and Token requests.

#### Retrieval of OpenID Configuration

To retrieve the OpenID Configuration, the SDK sends a request to `$serverURL/.well-known/openid-configuration` (or `$alternateIDPBaseURL` if set), using `$authenticationRefererURL` as value for the `Referer` header if it is set.

Here's an example of a typical request:
```
GET /.well-known/openid-configuration HTTP/1.1
Host: idp.example.com
Referer: https://cloud.example.com/
```

If the server responds with a success status and a JSON body, the Authentication Method looks for parameters:

Parameter                               | Stored as                            | Description
----------------------------------------|--------------------------------------|---------------------
`registration_endpoint`                 | `$clientRegistrationEndpointURL`     | Client Registration Endpoint 
`authorization_endpoint`                | `$authorizationEndpointURL`          | URL of the authorization endpoint
`token_endpoint`                        | `$tokenEndpointURL`                  | URL of the token endpoint
`token_endpoint_auth_methods_supported` | `$tokenEndpointSupportedAuthMethods` | List of auth methods supported by the token endpoint to send `$clientID` and `$clientSecret`

#### Dynamic Client Registration (DCR)

If the OpenID Configuration includes a `registration_endpoint`, the SDK performs a [Dynamic Client Registration](https://openid.net/specs/openid-connect-registration-1_0.html) and henceforth uses the Client ID and Client Secret obtained through it.

#### Requesting Authorization

Next, the Authentication Method composes the `$authorizationURL` based on the `$authorizationEndpointURL` retrieved from OpenID Configuration and the following query parameters:

Parameter               | Contents                | Status   | Comment
------------------------|-------------------------|----------|----------------------------------------------------------------------------------
`response_type`         | `code`                  | required | Same as OAuth2.
`client_id`             | configured value        | required | Client ID obtained through DCR (if any). Otherwise same as OAuth2. 
`redirect_uri`          | configured value        | required | The value of `authentication-oauth2.oidc-redirect-uri` (default: `oc://ios.owncloud.com`).
`state`                 | random UUID             | optional | Same as OAuth2.
`user`                  | `$username`             | optional | Same as OAuth2.
`login_hint`            | `$username`             | optional | Filled with pre-provided username ([specification](https://openid.net/specs/openid-connect-core-1_0.html#AuthRequest)).
`scope`                 | configured value        | required | The value of `authentication-oauth2.oidc-scope` (default: `openid offline_access email profile`).
`prompt`                | configured value        | required | The value of `authentication-oauth2.oidc-prompt` (default: `select_account consent`).
`code_challenge`        | PKCE challenge          | optional | Used by default. See RFC 7636 for details.
`code_challenge_method` | PKCE challenge method   | optional | Used by default. See RFC 7636 for details.

The `$authorizationURL` is then opened in a webview to present the server's login page and allow the user to log in. On success, the login page eventually opens the custom scheme `redirect_uri` and returns an Authorization Code as parameter:

```
oc://ios.owncloud.com?state=…&code=$authCode&scope=offline_access%20email%20profile%20openid&grant_type=authorization_code
```

If `state` is returned, the Authentication Method checks if its value is identical to the value it included in the `$authorizationURL`.
If `code` is returned, the Authentication Method stores it as `$authCode` and proceeds.

#### Requesting the Token

The Token Request URL is based on the `$tokenEndpointURL` retrieved from OpenID Configuration and the following query parameters:

Parameter         | Contents                | Status      | Comment
------------------|-------------------------|-------------|----------------------------------------------------------------------------------
`grant_type`      | `authorization_code`    | required    | Same as OAuth2.
`code`            | `$authCode`             | required    | Same as OAuth2.
`redirect_uri`    | configured value        | required    | Same as OAuth2.
`client_id`       | configured value        | conditional | Sent if the OpenID Configuration's `token_endpoint_auth_methods_supported` includes `client_secret_post` but not `client_secret_basic`.
`client_secret`   | configured value        | conditional | Sent if the OpenID Configuration's `token_endpoint_auth_methods_supported` includes `client_secret_post` but not `client_secret_basic`.
`code_verifier`   | PKCE code verifier      | optional    | Used by default. See RFC 7636 for details.

If `$tokenEndpointSupportedAuthMethods` contains `client_secret_basic`, the Client ID and Client Secret are sent as Basic Auth `Authorization` header (as per [RFC 6749](https://datatracker.ietf.org/doc/html/rfc6749#section-2.3.1)).
If `$tokenEndpointSupportedAuthMethods` instead only contains `client_secret_post`, the Client ID and Client Secret are included as parameters.

The Token Request will typically look like this:
```
POST /konnect/v1/token HTTP/1.1
Content-Type: application/x-www-form-urlencoded
Authorization: Basic base64($clientID + ":" + $clientSecret)

code=as798da897sd9&code_verifier=2E1DsnplwtT7O7tFCq5xB6yYQ…&redirect_uri=oc://ios.owncloud.com&grant_type=authorization_code
```

Upon success, the server responds with JSON data similar to this:
```json
{
	"access_token": "eyJhzI1NiIsImtpZ5IiwidHlwCI6InByaXZhdGUtbGciOiJQUa2VIjoiSldUIn0…",
	"refresh_token": "eyJhzI1NiIsImtpZ5IiwidHlwCI6InByaXZhdGUtbGciOiJQUa2VIjoiSldUIn1…",
	"expires_in": 300,
	"user_id": "admin"
}
```

The Authentication Method uses the returned `access_token` to compose an `Authorization` header that will be used to make authenticated requests from then on:

```
Authorization: Bearer $accessToken
```

The Authentication Method then checks if the response included a `user_id`:
- if `user_id` is included, that `user_id` is used.
- if `user_id` is missing and `$webFingerAccountLookupURL` is not set, the SDK sends an authenticated request to the user endpoint `$serverURL/ocs/v2.php/cloud/user` to obtain it.

Finally, if no errors occured to this point, the Authentication Method indicates the authentication was successful.

## Server Choice / Authenticated Instance Discovery (`BookmarkComposer.chooseServer()`)

If `$webFingerAccountLookupURL` is set, the Bookmark Composer uses the SDK's `-[OCConnection retrieveAvailableInstancesWithOptions:authenticationMethodIdentifier:authenticationData:completionHandler:]` to obtain a list of servers for the user to choose from.

To obtain the list, the SDK performs an [Authenticated Instance Discovery](https://doc.owncloud.com/ocis/next/deployment/services/s-list/webfinger.html#authenticated-instance-discovery) by sending an authenticated `GET` request to `$webFingerAccountLookupURL`.

If the server responds with a success status and returns valid JSON, the SDK looks for `http://webfinger.owncloud/rel/server-instance` `rel`ations and creates an `OCServerInstance` object for each of them, including the provided `titles`.

Example:
```json
{
    "subject": "acct:einstein@drive.ocis.test",
    "links": [
        {
            "rel": "http://openid.net/specs/connect/1.0/issuer",
            "href": "https://sso.example.org/cas/oidc/"
        },
        {
            "rel": "http://webfinger.owncloud/rel/server-instance",
            "href": "https://abc.drive.example.org",
            "titles": {
                "en": "oCIS Instance"
            }
        }
    ]
}
```

If the server returns only a single server instance, it is automatically picked. If more than one server instance is returned, the user may be offered to choose a server in the future.

Once a server instance is chosen, it's `href` value is used as new `$serverURL`.

## Retrieve Server Information (`BookmarkComposer.retrieveServerConfiguration()`)

Finally, the Bookmark Composer verifies the result of the Setup and Authentication flow by connecting to the newly added server, in which course requests are sent to:
- the status endpoint
- the capabilities endpoint
- the user endpoint
- the drives list (for instances indicating drive support in the capabilities) from the endpoint at `$serverURL/graph/v1.0/me/drives`.

If any issues occur, the user is notified. If none occur, the account is now set up.
