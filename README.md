
# WebsiteFailedLogins #

This PowerShell module was created to identify the following scenarios affecting IIS hosted websites.

1. Brute Force Login Attempts - excessive failed logins from a single IP address and often targeting a single account.
2. Password Spraying Attempts - excessive failed logins from a single IP address using a single password across multiple user accounts.
3. Distributed Login Attempts - either of the above techniques being sourced from multiple IP addresses.

It leverages Microsoft Logparser and a configuration file to parse the target website's IIS logs. When a threshold is met or exceeded an alert is generated via standard out, email, and/or written to a Windows Event Log. No changes are needed on the webserver. This module can even run on a separate system where there's access to the IIS logs.

Detailed information available at: https://github.com/phbits/WebsiteFailedLogins/wiki


## Prerequisites ##

The following are prerequisites needing to be addressed to run this module.


### Logparser ###

WebsiteFailedLogins only needs access to a folder containing `Logparser.exe` and `Logparser.dll`. A full installation is unnecessary but will still work.

Place these two files in an accessible folder and update the configuration file with this folder path. The user running this module must have sufficient permission to launch Logparser.exe.

Download URL: https://www.microsoft.com/en-us/download/details.aspx?id=24659


### IIS Logging ###

IIS must log using the W3C format and include the following fields.

- `date`
- `time`
- `c-ip`
- `s-sitename`
- `cs-method`
- `cs-uri-stem`
- `sc-status`

Logparser will perform a recursive search so specify the parent folder in the configuration file.

While Logparser is very fast, the amount of logs it must parse will be the greatest impact on performance. See the following link for details: https://github.com/phbits/WebsiteFailedLogins/wiki/Performance


## Permissions ##

Permissions required to run this module are as follows.


### Administrator ###

Only necessary if using WinEvent as an Alert Method where alerts are written to the Application Event Log.

Administrator permission is needed to register a new Source in the Application Event Log. Once the source is registered, Administrator permission is no longer needed. The command to register WebsiteFailedLogins as a source is as follows.

```powershell
New-EventLog -LogName Application -Source WebsiteFailedLogins
```


### Standard User ###

A standard user has enough permission to run this module as long as the following are met.

1. Read access to IIS log files.
2. Exec permission of Logparser.exe



# Configuration File Settings #

WebsiteFailedlogins uses a configuration file. Each setting is described in detail below. See the [wiki](https://github.com/phbits/WebsiteFailedLogins/wiki) for even more information.

There are two functions in this module used for working with the default configuration file.

- `Get-WebsiteFailedLoginsDefaultConfiguration` - returns the content of the default configuration file to standard out.
- `Copy-WebsiteFailedLoginsDefaultConfiguration` - copies the default configuration file to the destination folder.


## [Website] Sitename ##

The sitename of a website is logged in the IIS log field `s-sitename`. This value is used to identify the target website since multiple host headers and/or IP addresses can be bound to it.

The PowerShell cmdlet `Get-IISSite` will show the ID for each website. That ID can be appended to W3SVC to create the sitename.

> EXAMPLE: website with `ID=1` would have `sitename=w3svc1`


## [Website] Authentication ##

There are three options for choosing authentication.

1. Basic - This method of authentication occurs in the browser via request/response headers and will generate an HTTP 401 response when authentication fails. Authentication credentials are included in every request as base64 encoded values.
2. Windows - Like basic authentication, this technique occurs in the browser via request/response headers and generates an HTTP 401 when authentication fails. NTLM is used almost exclusively since Kerberos requires additional server-side configurations and KDC accessibility.
3. Forms - Authentication is handled solely by the website/application. Thus, requiring additional configuration settings to be specified (i.e. `UrlPath`) since not all implementations respond to failed authentication with an HTTP 401.

   **WARNING**: Forms authentication must use an HTTP POST (`cs-method`) when submitting login credentials.


## [Website] HttpResponse ##

When a failed login occurs, the HTTP response code (IIS log field `sc-status`) must be specified here. For Basic and Windows authentication it will most likely be 401. Forms should also be 401 though it could be different based on implementation.


## [Website] UrlPath ##

Only necessary if `Authentication = Forms`. Specify the URL path (IIS log field `cs-uri-stem`) where credentials are submitted for authentication.

Since implementations of Forms Authentication can vary, specifying the URL path helps identify failed logins when HTTP response codes are nonstandard.

**WARNING**: Forms authentication must use an HTTP POST (`cs-method`) when submitting login credentials.


## [Website] LogPath ##

Folder containing the IIS logs for the target website. For best performance archive old logs so they no longer reside in this directory. Logparser will recursively check every log file in the specified folder and will incur a significant performance hit if there are gigabytes upon gigabytes of logs.


## [Website] FailedLoginsPerIP ##

The number of failed logins from a single IP address having occurred since the `StartTime` that will trigger an alert.


## [Website] TotalFailedLogins ##

The total number of failed logins having occurred since the `StartTime` that will trigger an alert. This technique is useful for identifying failed logins where multiple IP addresses operate at a threshold below what is set for `FailedLoginsPerIP`.


## [Website] StartTime ##

Number of seconds from when the script is launched to establish the `StartTime`. Any requests from that point forward will be included.

Since IIS logs use UTC, all time in this module is also in UTC.

> EXAMPLE: if this value is set to `1800` (30 minutes), `StartTime` will be calculated using:
>
>	`(Get-Date).ToUniversalTime().AddSeconds(-1800)`


## [Logparser] Path ##

WebsiteFailedLogins only needs access to `Logparser.exe` and `Logparser.dll`. A full installation is unnecessary but will still work.

Place these two files in an accessible folder and update the configuration file with this folder path.

Download URL: https://www.microsoft.com/en-us/download/details.aspx?id=24659


## [Alert] Method ##

Standard out will always be used even if no value is specified. Choosing both Smtp and WinEvent will enable both methods or just include one.

- Smtp - Send an email based on the `[SMTP]` settings.
- WinEvent - Write an event based on the `[WinEvent]` settings.
- None - Only use standard out.


## [Alert] DataType ##

Alert data can be provided in different formats making it easier to work with.

- text - Similar to printing out each line of an array, this option just provides text.
- xml - Alert data can be deserialized into an object using: [System.Management.Automation.PSSerializer]::Deserialize()
- json - The ConvertFrom-Json cmdlet can be used to easily work with the data.


## [Smtp] To ##

Recipient email address for the alert.


## [Smtp] From ##

Sender's email address for the alert.


## [Smtp] Subject ##

Email subject for the alert.


## [Smtp] Server ##

DNS name or IP address of SMTP server.

> NOTE: this script is hard-coded to use `TLS1.2` when communicating with this server.


## [Smtp] Port ##

SMTP server port to connect to.


## [Smtp] CredentialXml ##

Optional setting. XML file containing PSCredential for SMTP authentication. Leave blank if no credentials are to be used.

To create this file run the following command using the account that will be launching this module.

```powershell
Get-Credential | Export-Clixml -Path <CredentialXmlPath>
```

Ensure NTFS permissions on the PSCredential xml file are tuned to only allow access to SYSTEM, any backup accounts, and the user running this module. The Export-Clixml cmdlet encrypts credential objects by using the Windows Data Protection API. The encryption ensures that only your user account on only that computer can decrypt the contents of the credential object. The exported CLIXML file can't be used on a different computer or by a different user. For more information: [Export-Clixml: Example 3: Encrypt an exported credential object on Windows](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/export-clixml?view=powershell-7.1#example-3--encrypt-an-exported-credential-object-on-windows)


## [WinEvent] LogName ##

The target event log to write an event to.


## [WinEvent] EntryType ##

Available options are: Error, FailureAudit, Information, SuccessAudit, Warning


## [WinEvent] Source ##

Name of the application that generated this event.

By default, WebsiteFailedLogins will not be registered. Doing so requires Administrative permission and can be achieved via the following command.

```powershell
New-EventLog -LogName Application -Source WebsiteFailedLogins
```


## [WinEvent] FailedLoginsPerIPEventId ##

Event Id used when writing an alert for an IP address that meets/exceeds the threshold `FailedLoginsPerIP`.


## [WinEvent] TotalFailedLoginsEventId ##

Event Id used when writing an alert for when the total website failed logins meet/exceed the threshold `TotalFailedLogins`.



# Scheduling #

This module should be launched via Task Scheduler on a reoccurring schedule. Consider using a shorter reoccurrence time then what is set for `StartTime` as this will provide overlap.

> EXAMPLE: suppose this module is launched every 900 seconds (15 minutes) with StartTime=1800 (30 minutes).

The shortest reoccurrence one should use with this module is 5 minutes. If a shorter window is necessary, consider implementing a real-time monitor via ModSecurity or similar Web Application Firewall (WAF).

The greatest performance impact on this module is providing Logparser gigabytes upon gigabytes of logs since they will all be checked. Practice good log maintenance by placing older logs in an archive. Doing so will greatly improve performance.

Once the configuration file has been finalized and no longer produces errors, consider running `Invoke-WebsiteFailedLogins` with the `-RunningConfig` switch. Doing so will exclude nearly all validation checks against the configuration file making it run significantly faster.



# Returned Data #

Invoke-WebsiteFailedLogins returns an object containing the configuration and all results. This allows wrappers to launch the module and do any desired tasks. See [Taking Action](https://github.com/phbits/WebsiteFailedLogins/wiki/Taking-Action) for more information.

The following object is returned by `Invoke-WebsiteFailedLogins`.

```powershell
[Hashtable] WebsiteFailedLogins
{
	<key 'FailedLoginsPerIP'><value [hashtable]>
		<key '<ClientIP>'><value [hashtable]>
			<key 'ClientIP'>		<value [string]>
			<key 'FailedLogins'>	<value [string]>
			<key 'Sitename'>		<value [string]>
			<key 'IISLogPath'>		<value [string]>
			<key 'Authentication'>	<value [string]>
			<key 'HttpResponse'>	<value [string]>
			<key 'UrlPath'>			<value [string]>
			<key 'Start'>			<value [string]>
			<key 'End~'>			<value [string]>
	<key 'TotalFailedLogins'><value [hashtable]>
		<key 'TotalFailedLogins'>	<value [string]>
		<key 'Sitename'>			<value [string]>
		<key 'IISLogPath'>			<value [string]>
		<key 'Authentication'>		<value [string]>
		<key 'HttpResponse'>		<value [string]>
		<key 'UrlPath'>				<value [string]>
		<key 'Start'>				<value [string]>
		<key 'End~'>				<value [string]>
	<key 'HasError'><value [boolean]> # indicates if an error occurred.
	<key 'HasResults'><value [boolean]> # indicates if there are results.
	<key 'Configuration'><value [hashtable]> # configuration from ini file
		<key [string]><value [hashtable]>
	<key 'ErrorMessages'><value [object[]]> # array of error messages.
}
```


# Taking Action #

This module will only generate an alert and return any results. This is because taking action has many nuances as described here: https://github.com/phbits/WebsiteFailedLogins/wiki/Taking-Action



# Potential Issues #

The following are potential issues one should be aware of when implementing this module.


## Basic or Windows Authentication ##

1. Identifying failed logins when Basic or Windows authentication is used requires checking the HTTP response code only. A user is not redirected to a logon page such is the case when using Forms authentication. Thus, a client can initiate the logon process by requesting any resource within the website/application. If this same website/application has a resource secured to a smaller subset of users, an already authenticated user could trigger an alert by attempting to access the more secure resource they don't have permission to view.

> EXAMPLE: suppose a website requires an authenticated user. This same website has a folder '/Management' which has stricter permissions; only accessible by those in the Management group. A non-management authenticated user will get an HTTP 401 when requesting a resource in that directory. Repeated requests to '/Management', for an image or similar resource, could trigger an alert.

2. Another scenario is an HTTP client that doesn't recognize the authentication header. Thereby making request after request resulting in an HTTP 401 and the `cs-username` being logged as `NULL`.


# Investigating Results #

The following aims to help with investigating alerts.


## Per IP Entries ##

When a ClientIP has met or exceeded the `FailedLoginsPerIP` threshold, a great first step is to extract all requests from that IP address having occurred between the Start and End timestamps.


### Alert Raised ###

Suppose this alert was identified by WebsiteFailedLogins.

```ini
ClientIP = 10.1.1.10
FailedLogins = 100
Sitename = W3SVC2
IISLogPath = D:\inetpub\logs\LogFiles\W3SVC2
Authentication = Windows
HttpResponse = 401
Start = 2019-01-01T18:30:00Z
End~ = 2019-01-01T19:00:10Z
```


### Identify Requests ###

1. Update the following Logparser query with settings from the alert.

Save it as `ClientIPRequests.sql`.

```sql
-- Start ClientIPRequests.sql --
SELECT *
INTO ResultsFile.csv
FROM 'D:\inetpub\logs\LogFiles\W3SVC2\*'
WHERE s-sitename LIKE 'W3SVC2'
	AND c-ip LIKE '10.1.1.10'
	AND TO_TIMESTAMP(date,time)
		BETWEEN TIMESTAMP('2019-01-01 18:30:00', 'yyyy-MM-dd HH:mm:ss')
		AND TIMESTAMP('2019-01-01 19:00:10', 'yyyy-MM-dd HH:mm:ss')
-- End ClientIPRequests.sql --
```

2. Run the query using the following command.

```
logparser.exe -recurse:-1 -i:IISW3C -o:CSV file:ClientIPRequests.sql
```

3. Review the results in `ResultsFile.csv`. See Additional Information section below for things to look for.

> NOTE: IIS logs date/time in UTC while the Logparser query converts it to local time using the function `TO_LOCALTIME`.


## Total Failed Requests ##

When the total number of failed logins are unusually high, this can be an indicator of distributed brute force or distributed password spraying. The first step is to identify the IP addresses involved and their failed login count.


### Alert Raised ###

Suppose the following was identified by WebsiteFailedLogins.

```ini
TotalFailedLogins = 100
Sitename = W3SVC2
IISLogPath = D:\inetpub\logs\LogFiles\W3SVC2
Authentication = Windows
HttpResponse = 401
Start = 2019-01-01T18:30:00Z
End~ = 2019-01-01T19:00:10Z
```


### Identify Involved Client IP(s) ###

1. Update the following Logparser query with settings from the alert based on the authentication being used.

Save it as `PerIPFailedLogins.sql`.

###### Windows or Basic Authentication ######

```sql
-- Start PerIPFailedLogins.sql --
SELECT DISTINCT c-ip as ClientIP, Count(*) AS FailedLoginCount
INTO DATAGRID
FROM 'D:\inetpub\logs\LogFiles\W3SVC2\*'
WHERE s-sitename LIKE 'W3SVC2'
	AND sc-status = 401
	AND TO_TIMESTAMP(date,time)
		BETWEEN TIMESTAMP('2019-01-01 18:30:00', 'yyyy-MM-dd HH:mm:ss')
		AND TIMESTAMP('2019-01-01 19:00:10', 'yyyy-MM-dd HH:mm:ss')
GROUP BY ClientIP
ORDER BY FailedLoginCount DESC
-- End PerIPFailedLogins.sql --
```

###### Forms Authentication ######

```sql
-- Start PerIPFailedLogins.sql --
SELECT DISTINCT c-ip as ClientIP, Count(*) AS FailedLoginCount
INTO DATAGRID
FROM D:\inetpub\logs\LogFiles\W3SVC2\*
WHERE s-sitename LIKE 'W3SVC2'
	AND sc-status = 401
	AND cs-uri-stem LIKE '/login.aspx'
	AND cs-method LIKE 'POST'
	AND TO_TIMESTAMP(date,time)
		BETWEEN TIMESTAMP('2019-01-01 18:30:00', 'yyyy-MM-dd HH:mm:ss')
		AND TIMESTAMP('2019-01-01 19:00:10', 'yyyy-MM-dd HH:mm:ss')
GROUP BY ClientIP
ORDER BY FailedLoginCount DESC
-- End PerIPFailedLogins.sql --
```

2. Run the query using the following command. The Logparser Datagrid window should pop up with the results.

```
logparser.exe -recurse:-1 -i:IISW3C file:PerIPFailedLogins.sql
```

3. Having identified the involved IP addresses, use the above technique for 'Per IP Entries' to review requests from each Client IP address.


## Additional Information ##

The following may help with the investigation.

 * `cs(User-Agent)` - some automated scanners will use the same User-Agent string which appears in the IIS Log Field `cs(User-Agent)`. While easily spoofed it can be a quick indicator of unnecessary traffic since legitimate requests will rarely make any changes to this setting.
 * `cs-username` - identify if a single user is being targeted or if multiple users are being targeted. This will indicate password spraying (single password to many users) vs. brute forcing (many passwords to a single account). IIS log field `cs-username` is used for logging the client provided username.
 * Reverse DNS - legit vulnerability scanners may trigger these settings. A reverse DNS lookup will often provide this identification by returning something like vulnscan.security.domain.com.
 * Basic/Windows Authentication - if using either of these authentication methods, take a closer look at the IIS log fields `sc-substatus` and `sc-win32-status` as they'll provide more context as to why an HTTP 401 was returned. Note that initial requests will not contain credentials resulting in `NULL` being logged by IIS in the `cs-username` field and is a function of how Basic/Windows authentication is initiated.
 * Whois - check whois to get more information about the IP address. Is it part of a research department? Perhaps a temporary virtual machine on a cloud hosting provider? etc.
 * IP Reputation - check IP reputation services such as those provided by SANS to identify whether other attacks have been reported from this IP address.
 * Cross-Check Logs - consider performing a cross-check of other internal logs for indications of abuse from the IP address. A good place to start would be perimeter flow data.
