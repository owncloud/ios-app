# Appendix: Troubleshooting

## Log Files

Effectively debugging software requires as much relevant information as can be
obtained. To assist the ownCloud support personnel, please try to provide as
many relevant logs as possible. Log output can help with tracking down
problems and, if you report a bug, log output can help to resolve an issue more
quickly.

### Capturing App Debug Logs

The ownCloud iOS app has a builtin logging feature:  
`Settings > Logging`

1. Reset logfile
2. Enable logfile
3. Perform the steps to reproduce the error
4. Go back to the settings and share the logfile.

![ios-app-settings-logging](https://user-images.githubusercontent.com/214010/52530933-01881b80-2d0e-11e9-8ff9-ae96a4a51832.png)

#### Record the screen

In iOS 11 or later, you can additionally create a screen recording to better illustrate an error:  
https://support.apple.com/en-us/HT207935

### Locating iPhone & iPad app crash logs

In the worst case when the app isn't responding or crashing, iOS saves a crashlog on the device.

Here you can find it on iOS 12:  
`Settings > Privacy > Analytics > Analytics Data`

The list entries are sorted alphabetically with the app name and date and time. Tap the name to open and export with the button on the upper right.

### ownCloud server Log File

The ownCloud server also maintains an ownCloud specific log file. This log file
must be enabled through the ownCloud Administration page. On that page, you can
adjust the log level. We recommend that when setting the log file level that
you set it to a verbose level like `Debug` or `Info`.
  
You can view the server log file using the web interface or you can open it
directly from the file system in the ownCloud server data directory.

You can find more information about ownCloud server logging at
https://doc.owncloud.com/server/10.0/admin_manual/configuration/server/logging_configuration.html.

### Webserver Log Files

It can be helpful to view your webserver's error log file to isolate any
ownCloud-related problems. For Apache on Linux, the error logs are typically
located in the `/var/log/apache2` directory. Some helpful files include the
following:

- `error_log` -- Maintains errors associated with PHP code. 
- `access_log` -- Typically records all requests handled by the server; very
  useful as a debugging tool because the log line contains information specific
  to each request and its result.
  
You can find more information about Apache logging at
http://httpd.apache.org/docs/current/logs.html.

## Tools

### mitmproxy

mitmproxy is an interactive man-in-the-middle proxy for HTTP and HTTPS with a console interface. At ownCloud we use it a lot to investigate every detail of HTTP requests and responses:  
https://mitmproxy.org/
