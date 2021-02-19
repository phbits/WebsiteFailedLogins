Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath 'WebsiteFailedLogins.alert.psm1')
Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath 'WebsiteFailedLogins.lp.psm1')

Function Get-FailedLoginsPerIP
{
    <#
        .SYNOPSIS

            Gets each Client IP (c-ip) having generated failed logins >= FailedLoginsPerIP since StartTime.
    #>
    [OutputType('System.Object[]')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.Collections.Hashtable]
        # INI Configuration.
        $IniConfig
    )

    $returnValue = @()

    $logparserQuery = Get-LogparserQuery -IniConfig $IniConfig

    $logparserArgs = @('-recurse:-1','-headers:ON','-i:IISW3C','-o:CSV','-q:ON','-stats:OFF')

    $logparserResults = Invoke-Logparser -Path $IniConfig.Logparser.ExePath `
                                         -Query $logparserQuery `
                                         -Switches $logparserArgs

    $queryTimestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss')

    if ([System.String]::IsNullOrEmpty($logparserResults) -eq $false)
    {
        $resultsObj = $logparserResults | ConvertFrom-Csv

        $resultBase = @{
                            'FriendlyName'   = $IniConfig.Website.FriendlyName
                            'ClientIP'       = ''
                            'FailedLogins'   = ''
                            'Sitename'       = $IniConfig.Website.Sitename
                            'IISLogPath'     = $IniConfig.Website.LogPath
                            'Authentication' = $IniConfig.Website.Authentication
                            'HttpResponse'   = $IniConfig.Website.HttpResponse
                            'UrlPath'        = $IniConfig.Website.UrlPath
                            'Start'          = "$($IniConfig.Website.StartTimeTS) UTC"
                            'End~'           = "$($queryTimestamp) UTC"
                        }

        if($resultsObj -is [Array])
        {
            foreach ($item in $resultsObj)
            {
                $itemResult = $resultBase
                $itemResult.ClientIP = $item.ClientIP
                $itemResult.FailedLogins = $item.Hits

                $returnValue += $itemResult
            }
        } else {

            $resultBase.ClientIP = $resultsObj.ClientIP
            $resultBase.FailedLogins = $resultsObj.Hits
            $returnValue += $resultBase
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

    [string] $queryTimestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

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
                                    'End~'              = "$queryTimestamp"
                                }
            }
        }
    }

    return $returnValue

} # End Function Get-TotalFailedLogins

Export-ModuleMember -Function 'Get-FailedLoginsPerIP','Get-TotalFailedLogins'
