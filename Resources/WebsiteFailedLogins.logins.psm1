Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath 'WebsiteFailedLogins.lp.psm1')

Function Get-WebsiteFailedLogins
{
    <#
        .SYNOPSIS
            Gets all failed logins.
    #>
    [OutputType('System.Object[]')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Collections.Hashtable]
        # INI Configuration.
        $IniConfig
    )

    Write-Verbose -Message '[Get-WebsiteFailedLogins] Starting WebsiteFailedLogins.'

    $returnValue = @()

    $logparserArgs = @('-recurse:-1','-headers:ON','-i:IISW3C','-o:CSV','-q:ON','-stats:OFF')

    $logparserResults = Invoke-Logparser -Path $IniConfig.Logparser.ExePath `
                                         -Query $IniConfig.Logparser.WebsiteFailedLoginsQuery `
                                         -Switches $logparserArgs

    if ([System.String]::IsNullOrEmpty($logparserResults) -eq $false)
    {
        $returnValue = $logparserResults | ConvertFrom-Csv
    }

    return $returnValue

} # End Function Get-WebsiteFailedLogins

Function Get-FailedLoginsPerIPResult
{
    <#
        .SYNOPSIS
            Returns FailedLoginsPerIP result variable.
    #>
    [OutputType('System.Collections.Hashtable')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Hashtable]
        # INI Configuration.
        $IniConfig
        ,
        [Parameter(Mandatory=$true)]
        [String]
        # Client IP
        $ClientIP
        ,
        [Parameter(Mandatory=$true)]
        [Int]
        # Failed Logins
        $FailedLogins
    )

    $returnValue = @{
                        'FriendlyName'   = $IniConfig.Website.FriendlyName
                        'ClientIP'       = $ClientIP
                        'FailedLogins'   = $FailedLogins
                        'Sitename'       = $IniConfig.Website.Sitename
                        'IISLogPath'     = $IniConfig.Website.LogPath
                        'Authentication' = $IniConfig.Website.Authentication
                        'HttpResponse'   = $IniConfig.Website.HttpResponse
                        'Start'          = $IniConfig.Script.StartTimeTSZ
                        'End~'           = $IniConfig.Script.EndTimeTSZ
                    }

    if ($IniConfig.Website.Authentication -imatch 'Forms')
    {
        $returnValue.Add('UrlPath', $IniConfig.Website.UrlPath)
    }

    return $returnValue

} # End Function Get-FailedLoginsPerIPResult

Function Get-TotalFailedLoginsResult
{
    <#
        .SYNOPSIS
            Returns TotalFailedLogins result variable.
    #>
    [OutputType('System.Collections.Hashtable')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Hashtable]
        # INI Configuration.
        $IniConfig
        ,
        [Parameter(Mandatory=$true)]
        [Int]
        # Total Failed Logins
        $TotalFailedLogins
        ,
        [Parameter(Mandatory=$true)]
        [Hashtable]
        # Client IP List
        $ClientIpList
    )

    $returnValue = @{
                        'FriendlyName'      = $IniConfig.Website.FriendlyName
                        'ClientIPList'      = $ClientIpList
                        'TotalFailedLogins' = $TotalFailedLogins
                        'Sitename'          = $IniConfig.Website.Sitename
                        'IISLogPath'        = $IniConfig.Website.LogPath
                        'Authentication'    = $IniConfig.Website.Authentication
                        'HttpResponse'      = $IniConfig.Website.HttpResponse
                        'Start'             = $IniConfig.Script.StartTimeTSZ
                        'End~'              = $IniConfig.Script.EndTimeTSZ
                    }

    if ($IniConfig.Website.Authentication -imatch 'Forms')
    {
        $returnValue.Add('UrlPath', $IniConfig.Website.UrlPath)
    }

    return $returnValue

} # End Function Get-TotalFailedLoginsResult

Export-ModuleMember -Function 'Get-WebsiteFailedLogins','Get-FailedLoginsPerIPResult','Get-TotalFailedLoginsResult'
