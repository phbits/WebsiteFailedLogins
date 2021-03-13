 @{

RootModule = 'WebsiteFailedLogins.psm1'

ModuleVersion = '2.0'

GUID = '12e3c270-ef13-42bb-bea3-40b8cf44a49f'

Author = 'phbits'

CompanyName = 'phbits'

Description = @'
This PowerShell module was created to identify the following scenarios affecting IIS hosted websites.

1. Brute Force Login Attempts - excessive failed logins from a single IP address and often targeting a single account.
2. Password Spraying Attempts - excessive failed logins from a single IP address using a single password across multiple user accounts.
3. Distributed Login Attempts - either of the above techniques being sourced from multiple IP addresses.

It leverages Microsoft Logparser and a configuration file to parse the target website's IIS logs. When a threshold is met or exceeded an alert is generated via standard out, email, and/or written to a Windows Event Log. No changes are needed on the webserver. This module can even run on a separate system where there's access to the IIS logs.

Checkout the wiki for details: https://github.com/phbits/WebsiteFailedLogins/wiki
'@

NestedModules = @(
                    'Resources\WebsiteFailedLogins.alert.psm1',
                    'Resources\WebsiteFailedLogins.config.psm1',
                    'Resources\WebsiteFailedLogins.logins.psm1',
                    'Resources\WebsiteFailedLogins.lp.psm1'
                )

FunctionsToExport = @(
                        'Invoke-WebsiteFailedLogins',
                        'Get-WebsiteFailedLoginsReadme',
                        'Copy-WebsiteFailedLoginsReadme',
                        'Get-WebsiteFailedLoginsDefaultConfiguration',
                        'Copy-WebsiteFailedLoginsDefaultConfiguration'
                    )

FileList = @(
                'LICENSE',
                'README.md',
                'WebsiteFailedLogins.psd1',
                'WebsiteFailedLogins.psm1',
                'Resources\WebsiteFailedLogins_default.ini',
                'Resources\WebsiteFailedLogins.alert.psm1',
                'Resources\WebsiteFailedLogins.config.psm1',
                'Resources\WebsiteFailedLogins.logins.psm1',
                'Resources\WebsiteFailedLogins.lp.psm1'
            )

PrivateData = @{

    PSData = @{

        Tags = 'IIS','Logparser','W3SVC','Logs','FailedLogin','BruteForce','PasswordSpray','Detection','IDS'

        ProjectUri = 'https://github.com/phbits/WebsiteFailedLogins'

        LicenseUri = 'https://github.com/phbits/WebsiteFailedLogins/blob/main/LICENSE'

        ReleaseNotes = @'
## [2.0.0.0] - 2021-03-13

### Added

- WinEvent and Smtp alert data can now be formatted in text, json, or xml.
- FriendlyName setting available in configuration ini to better describe website.
- Added configuration validation checks.
- Detailed documentation at: https://github.com/phbits/WebsiteFailedLogins/wiki

### Changed

- Performs just one Logparser query when launching Invoke-WebsiteFailedLogins.
- Returned data is a hashtable object.
- Placed related functions into separate module files.
- Improved configuration validation.
- Improved Alert logic.
- System.Diagnostics.Process wrapper runs Logparser script.
- Standardized all timestamps to UTC.
- Updated function documentation and README.

### Removed

- Usage of global variables for sharing configuration settings.

## [1.0.0.0] - 2019-01-30

### Changed

- Initial release
    - Tested on Windows Server 2016
'@

    } # End of PSData hashtable

} # End of PrivateData hashtable

HelpInfoURI = 'https://github.com/phbits/WebsiteFailedLogins/wiki'

}
