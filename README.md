
# WebsiteFailedLogins #

This PowerShell module was created to identify the following scenarios affecting IIS hosted websites.

1. Brute Force Login Attempts - excessive failed logins from a single IP address and often targeting a single account.
2. Password Spraying Attempts - excessive failed logins from a single IP address using a single password across multiple user accounts.
3. Distributed Login Attempts - either of the above techniques being sourced from multiple IP addresses.

It leverages Microsoft Logparser and a configuration file to parse the target website's IIS logs. When a threshold is met or exceeded an alert is generated via standard out, email, and/or written to a Windows Event Log. No changes are needed on the webserver. This module can even run on a separate system where there's access to the IIS logs.

> Detailed information available at: https://github.com/phbits/WebsiteFailedLogins/wiki


## Prerequisites ##

Logparser and IIS log fields are the two prerequisites for this module.


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

Only necessary if using WinEvent as an Alert Method; where alerts are written to the Application Event Log.

Administrator permission is needed to register a new Source in the Application Event Log. Once the source is registered, Administrator permission is no longer needed. The command to register WebsiteFailedLogins as a source is as follows.

```powershell
New-EventLog -LogName Application -Source WebsiteFailedLogins
```


### Standard User ###

A standard user has enough permission to run this module as long as the following are met.

1. Read access to IIS log files.
2. Exec permission of Logparser.exe


# Configuration File Settings #

WebsiteFailedlogins uses a configuration file. Each setting is described in detail below.

Check out the [wiki](https://github.com/phbits/WebsiteFailedLogins/wiki) for even more information.

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

If none of these options work, a custom Logparser query maybe needed. Open an [Issue](https://github.com/phbits/WebsiteFailedLogins/issues) to find out.


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

Since IIS logs use UTC, all time in this module also uses UTC.

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

- text - Similar to the configuration file (ini) with one key/value pair on each line.
- xml - Alert data can be deserialized into an object using: [System.Management.Automation.PSSerializer]::Deserialize()
- json - The ConvertFrom-Json cmdlet can be used to deserialie the alert data.


## [Smtp] To ##

Recipient email address for the alert.


## [Smtp] From ##

Sender's email address for the alert.


## [Smtp] Subject ##

Email subject for the alert that will be appended to alert information.


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

By default, WebsiteFailedLogins will not be registered. Doing so requires Administrative permission and can be achieved via the following command. This should only be done on the system running WebsiteFailedLogins.

```powershell
New-EventLog -LogName Application -Source WebsiteFailedLogins
```


## [WinEvent] FailedLoginsPerIPEventId ##

Event Id used when writing an alert for an IP address that meets/exceeds the threshold `FailedLoginsPerIP`.


## [WinEvent] TotalFailedLoginsEventId ##

Event Id used when writing an alert for when the total website failed logins meet/exceed the threshold `TotalFailedLogins`.


# Scheduling #

There are two ways to launch WebsiteFailedLogins. The first is via Task Scheduler while the other technique is from a wrapper script that is launched via Task Scheduler. More information is available on the [wiki: How to Launch](https://github.com/phbits/WebsiteFailedLogins/wiki/How-to-Launch).

Consider using a shorter reoccurrence time then what is set for `StartTime` as this data overlap will provide better calculations.

> EXAMPLE: suppose this module is launched every 600 seconds (10 minutes) with StartTime=1800 (30 minutes).

The shortest reoccurrence one should use with this module is 5 minutes. If a shorter window is necessary, consider implementing a real-time monitor via ModSecurity or similar Web Application Firewall (WAF).

The greatest performance impact on this module is providing Logparser gigabytes upon gigabytes of logs since they will all be checked. Practice good log maintenance by placing older logs in an archive. Doing so will greatly improve performance. For more information read: [Wiki - Performance](https://github.com/phbits/WebsiteFailedLogins/wiki/Performance)

Once the configuration file has been finalized and no longer produces errors, consider running `Invoke-WebsiteFailedLogins` with the `-RunningConfig` switch. Doing so will exclude nearly all validation checks against the configuration file making it run significantly faster.


# Returned Data #

Invoke-WebsiteFailedLogins returns an object containing the configuration and all results. This allows wrappers to launch the module and do any desired tasks. See [Taking Action](https://github.com/phbits/WebsiteFailedLogins/wiki/Taking-Action) for more information.

The following object is returned by `Invoke-WebsiteFailedLogins`.

```powershell
[Hashtable] WebsiteFailedLogins
{
  <key 'FailedLoginsPerIP'><value [hashtable]>
    <key '<ClientIP>'><value [hashtable]> # The key is the actual ClientIP
      <key 'ClientIP'>       <value [string]>
      <key 'FailedLogins'>   <value [string]>
      <key 'Sitename'>       <value [string]>
      <key 'IISLogPath'>     <value [string]>
      <key 'Authentication'> <value [string]>
      <key 'HttpResponse'>   <value [string]>
      <key 'UrlPath'>        <value [string]>
      <key 'Start'>          <value [string]>
      <key 'End~'>           <value [string]>
  <key 'TotalFailedLogins'><value [hashtable]>
    <key 'TotalFailedLogins'> <value [string]>
    <key 'Sitename'>          <value [string]>
    <key 'IISLogPath'>        <value [string]>
    <key 'Authentication'>    <value [string]>
    <key 'HttpResponse'>      <value [string]>
    <key 'UrlPath'>           <value [string]>
    <key 'Start'>             <value [string]>
    <key 'End~'>              <value [string]>
  <key 'HasError'><value [boolean]> # indicates if an error occurred.
  <key 'HasResults'><value [boolean]> # indicates if there are results.
  <key 'Configuration'><value [hashtable]> # configuration from ini file
    <key [string]><value [hashtable]>
  <key 'ErrorMessages'><value [object[]]> # array of error messages.
}
```


# Taking Action #

This module will only generate an alert. This is because taking action has many nuances as described here: https://github.com/phbits/WebsiteFailedLogins/wiki/Taking-Action


# Investigating Results #

For detailed information about investigating alerts read:

https://github.com/phbits/WebsiteFailedLogins/wiki/Investigating-Alerts
