 @{

# Script module or binary module file associated with this manifest.
RootModule = 'WebsiteFailedLogins.psm1'

# Version number of this module.
ModuleVersion = '1.0'

# ID used to uniquely identify this module
GUID = '12e3c270-ef13-42bb-bea3-40b8cf44a49f'

# Author of this module
Author = 'phbits'

# Company or vendor of this module
CompanyName = 'phbits'

# Description of the functionality provided by this module
Description = @'
This PowerShell module was created to identify the following scenarios affecting IIS hosted websites.

1. Brute Force Login Attempts - excessive failed logins from a single IP address and often targeting a single account.
2. Password Spraying Attempts - excessive failed logins from a single IP address using a single password across multiple user accounts.
3. Distributed Login Attempts - either of the above techniques being sourced from multiple IP addresses.

It leverages Microsoft Logparser and a configuration file to parse the target website's IIS logs. When a threshold is met or exceeded an alert is generated via standard out, email, and/or written to a Windows Event Log. No changes are needed on the webserver. This module can even run on a separate system where there's access to the IIS logs.
'@

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
# FunctionsToExport = @()
FunctionsToExport = 'Invoke-WebsiteFailedLogins',
					'Get-WebsiteFailedLoginsReadme',
					'Copy-WebsiteFailedLoginsReadme',
					'Get-WebsiteFailedLoginsDefaultConfiguration',
					'Copy-WebsiteFailedLoginsDefaultConfiguration'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = @()

# List of all files packaged with this module
FileList = 'README.md','WebsiteFailedLogins.ini'

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'IIS','Logparser','W3SVC','Logs','FailedLogin','BruteForce','PasswordSpray','Detection'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/phbits/WebsiteFailedLogins'

        # ReleaseNotes of this module
        ReleaseNotes = 'Tested on Windows Server 2016'

    } # End of PSData hashtable

} # End of PrivateData hashtable
}
