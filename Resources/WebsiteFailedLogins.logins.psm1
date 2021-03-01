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

    Write-Verbose -Message 'Starting FailedLoginsPerIP.'

    $returnValue = @{}

    $logparserArgs = @('-recurse:-1','-headers:ON','-i:IISW3C','-o:CSV','-q:ON','-stats:OFF')

    $logparserResults = Invoke-Logparser -Path $IniConfig.Logparser.ExePath `
                                         -Query $IniConfig.Logparser.FailedLoginsPerIpQuery `
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

                $returnValue.Add($entry.ClientIP, $entryResult)
            }

        } else {

            $resultObjHashtable = Get-FailedLoginsPerIPResult -IniConfig $IniConfig `
                                                              -ClientIP $resultsObj.ClientIP `
                                                              -FailedLogins $resultsObj.Hits

            $returnValue.Add($resultsObj.ClientIP, $resultObjHashtable)
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
                'Start'          = $IniConfig.Website.StartTimeTSZ
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

    Write-Verbose -Message 'Starting TotalFailedLogins.'

    $returnValue = @{}

    [Int] $totalHits = 0

    $logparserArgs = @('-recurse:-1','-headers:OFF','-i:IISW3C','-o:CSV','-q:ON','-stats:OFF')

    Write-Verbose -Message "$($IniConfig.Logparser.ExePath)"
    Write-Verbose -Message "$($IniConfig.Logparser.TotalFailedLoginsQuery)"
    Write-Verbose -Message "$($logparserArgs)"

    [string] $logparserResult = Invoke-Logparser -Path $IniConfig.Logparser.ExePath `
                                                 -Query $IniConfig.Logparser.TotalFailedLoginsQuery `
                                                 -Switches $logparserArgs

    if ([System.String]::IsNullOrEmpty($logparserResult) -eq $false)
    {
        Write-Verbose -Message 'Not null.'

        if ([System.Int32]::TryParse($logparserResult, [ref] $totalHits))
        {
            Write-Verbose -Message 'Parse successful.'

            if ($totalHits -ge $IniConfig.Website.TotalFailedLogins)
            {
                Write-Verbose -Message "Threshold: $($IniConfig.Website.TotalFailedLogins) < TotalHits: $($totalHits)"

                $returnValue = @{
                                    'FriendlyName'      = $IniConfig.Website.FriendlyName
                                    'TotalFailedLogins' = $totalHits
                                    'Sitename'          = $IniConfig.Website.Sitename
                                    'IISLogPath'        = $IniConfig.Website.LogPath
                                    'Authentication'    = $IniConfig.Website.Authentication
                                    'HttpResponse'      = $IniConfig.Website.HttpResponse
                                    'UrlPath'           = $IniConfig.Website.UrlPath
                                    'Start'             = $IniConfig.Website.StartTimeTSZ
                                    'End~'              = "$((Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))"
                                }
            }
        }
    }

    return $returnValue

} # End Function Get-TotalFailedLogins

Export-ModuleMember -Function 'Get-FailedLoginsPerIP','Get-TotalFailedLogins'
