Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath 'WebsiteFailedLogins.lp.psm1')

Function Get-FailedLoginsPerIP
{
    <#
        .SYNOPSIS

            Gets each Client IP (c-ip) having generated failed logins >= FailedLoginsPerIP since StartTime.
    #>
    [OutputType('System.Collections.Hashtable')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Collections.Hashtable]
        # INI Configuration.
        $IniConfig
    )

    $returnValue = @{}

    $logparserQuery = Get-LogparserQuery -IniConfig $IniConfig

    $logparserArgs = @('-recurse:-1','-headers:ON','-i:IISW3C','-o:CSV','-q:ON','-stats:OFF')

    $logparserResults = Invoke-Logparser -Path $IniConfig.Logparser.ExePath `
                                         -Query $logparserQuery `
                                         -Switches $logparserArgs

    if ([System.String]::IsNullOrEmpty($logparserResults) -eq $false)
    {
        $resultsObj = $logparserResults | ConvertFrom-Csv

        if($resultsObj -is [Array])
        {
            foreach ($entry in $resultsObj)
            {
                $entryResult = Get-FailedLoginsPerIPResult -IniConfig $IniConfig `
                                                           -ClientIP $entry.ClientIP `
                                                           -FailedLogins $entry.Hits

                $returnValue.Add($($entry.ClientIP), $entryResult)
            }

        } else {

            $resultObjHashtable = Get-FailedLoginsPerIPResult -IniConfig $IniConfig `
                                                              -ClientIP $resultsObj.ClientIP `
                                                              -FailedLogins $resultsObj.Hits

            $returnValue.Add($($resultsObj.ClientIP), $resultObjHashtable)
        }
    }

    return $returnValue

} # End Function Get-FailedLoginsPerIP

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
        [System.Collections.Hashtable]
        # INI Configuration.
        $IniConfig
        ,
        [Parameter(Mandatory=$true)]
        [System.String]
        # Client IP
        $ClientIP
        ,
        [Parameter(Mandatory=$true)]
        [System.String]
        # Failed Logins
        $FailedLogins
    )

    return @{
                'FriendlyName'   = $IniConfig.Website.FriendlyName
                'ClientIP'       = $ClientIP
                'FailedLogins'   = $FailedLogins
                'Sitename'       = $IniConfig.Website.Sitename
                'IISLogPath'     = $IniConfig.Website.LogPath
                'Authentication' = $IniConfig.Website.Authentication
                'HttpResponse'   = $IniConfig.Website.HttpResponse
                'UrlPath'        = $IniConfig.Website.UrlPath
                'Start'          = "$($IniConfig.Website.StartTimeTS.Replace(' ','T') + 'Z')"
                'End~'           = "$((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))"
            }

} # End Function Get-FailedLoginsPerIPResult

Function Get-TotalFailedLogins
{
    <#
        .SYNOPSIS
            Gets the total failed login count if it meets or exceeds TotalFailedLogins threshold during the specified window.
    #>
    [CmdletBinding()]
    [OutputType('System.Collections.Hashtable')]
    param(
        [Parameter(Mandatory=$true)]
        [System.Collections.Hashtable]
        # INI Configuration.
        $IniConfig
    )

    $returnValue = @{}

    [Int32] $totalHits = 0

    $logparserQuery = Get-LogparserQuery -IniConfig $IniConfig -TotalFailedLogins

    $logparserArgs = @('-recurse:-1','-headers:OFF','-i:IISW3C','-o:CSV','-q:ON','-stats:OFF')

    [string] $logparserResult = Invoke-Logparser -Path $IniConfig.Logparser.ExePath `
                                                 -Query $logparserQuery `
                                                 -Switches $logparserArgs

    if ([System.String]::IsNullOrEmpty($logparserResult) -eq $false)
    {
        if ([System.Int32]::TryParse($logparserResult, [ref]$totalHits))
        {
            if ($totalHits -ge $IniConfig.Website.TotalFailedLogins)
            {
                $returnValue = @{
                                    'FriendlyName'      = $IniConfig.Website.FriendlyName
                                    'TotalFailedLogins' = $totalHits
                                    'Sitename'          = $IniConfig.Website.Sitename
                                    'IISLogPath'        = $IniConfig.Website.LogPath
                                    'Authentication'    = $IniConfig.Website.Authentication
                                    'HttpResponse'      = $IniConfig.Website.HttpResponse
                                    'UrlPath'           = $IniConfig.Website.UrlPath
                                    'Start'             = "$($IniConfig.Website.StartTimeTS.Replace(' ','T') + 'Z')"
                                    'End~'              = "$((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))"
                                }
            }
        }
    }

    return $returnValue

} # End Function Get-TotalFailedLogins

Export-ModuleMember -Function 'Get-FailedLoginsPerIP','Get-TotalFailedLogins'
