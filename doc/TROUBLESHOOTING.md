# Appendix: Troubleshooting

## Log Files

Effectively debugging software requires as much relevant information as can be
obtained. To assist the ownCloud support personnel, please try to provide as
many relevant logs as possible. Log output can help with tracking down
problems and, if you report a bug, log output can help to resolve an issue more
quickly.

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
