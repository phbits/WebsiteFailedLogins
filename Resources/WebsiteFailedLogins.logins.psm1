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

    $logparserResults = Invoke-Logparser -Path $IniConfig.Logparser.Path -Query $logparserQuery

    $queryTimestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss')

    if ($null -ne $logparserResults)
    {
        $resultsObj = $logparserResults | ConvertFrom-Csv

        foreach ($item in $resultsObj)
        {
            $returnValue += @{
                                'FriendlyName'   = $IniConfig.FriendlyName
                                'ClientIP'       = $item.ClientIP
                                'FailedLogins'   = $item.Hits
                                'Sitename'       = $IniConfig.Website.Sitename
                                'IISLogPath'     = $IniConfig.Website.LogPath
                                'Authentication' = $IniConfig.Website.Authentication
                                'HttpResponse'   = $IniConfig.Website.HttpResponse
                                'UrlPath'        = $IniConfig.Website.UrlPath
                                'Start'          = "$($IniConfig.Website.StartTimeTS) UTC"
                                'End~'           = "$($queryTimestamp) UTC"
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
        [Parameter(Mandatory=$true)]
        [System.Collections.Hashtable]
        # INI Configuration.
        $IniConfig
    )

    $returnValue = @{}

    [Int32] $totalHits = 0

    $logparserQuery = Get-LogparserQuery -IniConfig $IniConfig -TotalFailedLogins

    [string] $logparserResult = Invoke-Logparser -Path $IniConfig.Logparser.Path -Query $logparserQuery

    [string] $queryTimestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')

    if ([System.String]::IsNullOrEmpty($logparserResult) -eq $false)
    {
        if ([System.Int32]::TryParse($logparserResult, [ref]$totalHits))
        {
            if ($totalHits -ge $IniConfig.Website.TotalFailedLogins)
            {
                $returnValue = @{
                                    'FriendlyName'      = $IniConfig.FriendlyName
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

function Invoke-Logparser
{
    <#
        .SYNOPSIS
            Private function that wraps Logparser.exe
        .LINK
            https://github.com/dsccommunity/AuditPolicyDsc/blob/dev/DSCResources/AuditPolicyResourceHelper/AuditPolicyResourceHelper.psm1
    #>

    [OutputType([System.String])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [System.String]
        # Logparser Path
        $Path
        ,
        [Parameter(Mandatory=$true)]
        [System.String]
        # Logparser Query
        $Query
    )

    $includeHeaders = '-headers:OFF'

    if ($Query.Contains('ClientIP') -eq $true)
    {
        $includeHeaders = '-headers:ON'
    }

    $logparserArguments = @('-recurse:-1',$includeHeaders,'-i:IISW3C','-o:CSV','-q:ON','-stats:OFF',$Query)
    
    try {
        # Use System.Diagnostics.Process to process the auditpol command
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo.Arguments = $logparserArguments
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.FileName = $Path
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
        
        if ($process.Start() -eq $true)
        {
            [string] $logparserReturn = $process.StandardOutput.ReadToEnd()
        }

        $process.Dispose()
    }
    catch {
        $e = $_
        # Catch the error thrown if the lastexitcode is not 0
        [string] $errorString = "`n EXCEPTION:    $($e.Exception.Message)" + `
                                "`n LASTEXITCODE: $LASTEXITCODE" + `
                                "`n COMMAND:      $Path $logparserArguments"

        Write-Error -Message $errorString
    }

    return $logparserReturn

} # end function Invoke-Logparser

Export-ModuleMember -Function 'Get-FailedLoginsPerIP','Get-TotalFailedLogins'
