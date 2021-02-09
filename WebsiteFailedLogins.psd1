 @{

RootModule = 'WebsiteFailedLogins.psm1'

ModuleVersion = '1.0'

GUID = '12e3c270-ef13-42bb-bea3-40b8cf44a49f'

Author = 'phbits'

CompanyName = 'phbits'

Description = @'
This PowerShell module was created to identify the following scenarios affecting IIS hosted websites.

1. Brute Force Login Attempts - excessive failed logins from a single IP address and often targeting a single account.
2. Password Spraying Attempts - excessive failed logins from a single IP address using a single password across multiple user accounts.
3. Distributed Login Attempts - either of the above techniques being sourced from multiple IP addresses.

It leverages Microsoft Logparser and a configuration file to parse the target website's IIS logs. When a threshold is met or exceeded an alert is generated via standard out, email, and/or written to a Windows Event Log. No changes are needed on the webserver. This module can even run on a separate system where there's access to the IIS logs.
'@

FunctionsToExport = 'Invoke-WebsiteFailedLogins',
					'Get-WebsiteFailedLoginsReadme',
					'Copy-WebsiteFailedLoginsReadme',
					'Get-WebsiteFailedLoginsDefaultConfiguration',
					'Copy-WebsiteFailedLoginsDefaultConfiguration'

FileList = 'LICENSE',
           'README.md',
           'WebsiteFailedLogins.psd1',
           'WebsiteFailedLogins.psm1',
           'Resources\WebsiteFailedLogins.alert.psm1',
           'Resources\WebsiteFailedLogins.config.psm1',
           'Resources\WebsiteFailedLogins.ini',
           'Resources\WebsiteFailedLogins.logins.psm1',
           'Resources\WebsiteFailedLogins.lp.psm1'

PrivateData = @{

    PSData = @{

        Tags = 'IIS','Logparser','W3SVC','Logs','FailedLogin','BruteForce','PasswordSpray','Detection'

        ProjectUri = 'https://github.com/phbits/WebsiteFailedLogins'

        LicenseUri = 'https://github.com/phbits/WebsiteFailedLogins/blob/main/LICENSE'

        ReleaseNotes = 'Tested on Windows Server 2016'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}
