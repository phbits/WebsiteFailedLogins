Function Get-FailedLoginsPerIP
{
    <#
        .SYNOPSIS

            Gets each Client IP (c-ip) having generated failed logins >= FailedLoginsPerIP since StartTime.
    #>
    [OutputType('System.Object[]')]
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true)]
        [System.Collections.Hashtable]
        # INI Configuration.
        $IniConfig
    )

    $returnValue = @()

    $logparserQuery = Get-LogparserQuery -IniConfig $IniConfig

    $logparserResults = & $IniConfig.Logparser.Path -i:IISW3C -o:CSV -q:ON -stats:OFF $logparserQuery

    $queryTimestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

    if ($null -ne $logparserResults)
    {
        $resultsObj = $logparserResults | ConvertFrom-Csv

        foreach ($item in $resultsObj)
        {
            $returnValue += @{
                                'ClientIP'       = $item.ClientIP
                                'FailedLogins'   = $item.Hits
                                'Sitename'       = $IniConfig.Website.Sitename
                                'IISLogPath'     = $IniConfig.Website.LogPath
                                'Authentication' = $IniConfig.Website.Authentication
                                'HttpResponse'   = $IniConfig.Website.HttpResponse
                                'UrlPath'        = $IniConfig.Website.UrlPath
                                'Start'          = $IniConfig.Website.StartTimeTS
                                'End~'           = $queryTimestamp
                             }
        }
    }

    return $returnValue

} # End Function Get-FailedLoginsPerIP

Function Get-TotalFailedLogins
{
    <#
        .SYNOPSIS

            Gets the total failed login count if it meets or exceeds TotalFailedLogins threshold during the specified window.
    #>
    [CmdletBinding()]
    [OutputType('System.Collections.Hashtable')]
    param(
        [parameter(Mandatory=$true)]
        [System.Collections.Hashtable]
        # INI Configuration.
        $IniConfig
    )

    $returnValue = @{}

    [Int32] $totalHits = 0

    $logparserQuery = Get-LogparserQuery -TotalFailedLogins

    [string] $logparserResult = & $IniConfig.Logparser.Path -headers:OFF -i:IISW3C -o:CSV -q:ON -stats:OFF $logparserQuery

    [string] $queryTimestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

    if ([System.String]::IsNullOrEmpty($logparserResult) -eq $false)
    {
        if ([System.Int32]::TryParse($logparserResult, [ref]$totalHits))
        {
            if ($totalHits -ge $IniConfig.Website.TotalFailedLogins)
            {
                $returnValue = @{
                                    'TotalFailedLogins' = $totalHits
                                    'Sitename'          = $IniConfig.Website.Sitename
                                    'IISLogPath'        = $IniConfig.Website.LogPath
                                    'Authentication'    = $IniConfig.Website.Authentication
                                    'HttpResponse'      = $IniConfig.Website.HttpResponse
                                    'UrlPath'           = $IniConfig.Website.UrlPath
                                    'Start'             = $IniConfig.Website.StartTimeTS
                                    'End~'              = $queryTimestamp
                                }
            }
        }
    }

    return $returnValue

} # End Function Get-TotalFailedLogins

Export-ModuleMember -Function 'Get-FailedLoginsPerIP','Get-TotalFailedLogins'
