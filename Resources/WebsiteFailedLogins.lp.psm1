Function Get-LogparserQuery
{
    <#
        .SYNOPSIS

            Returns a Log parser query based on values from the configuration file.
    #>
    [CmdletBinding()]
    [OutputType('System.String')]
    param(
        [Parameter(Mandatory=$true)]
        [System.Collections.Hashtable]
        # INI Configuration.
        $IniConfig
        ,
        [Parameter(Mandatory=$false)]
        [switch]
        # By default, returns query for Client IP (c-ip) failed logins.
        # This switch is used to get the total failed login count query.
        $TotalFailedLogins
    )

    # Begin query build
    [string] $returnQuery = '"SELECT '

    if ($TotalFailedLogins)
    {
        $returnQuery += 'COUNT(*) AS Hits '

    } else {

        $returnQuery += 'c-ip AS ClientIP, COUNT(*) AS Hits '
    }

    $returnQuery += "FROM '{0}' " -f $IniConfig.Logparser.LogPath
    $returnQuery += "WHERE s-sitename LIKE '{0}' " -f $IniConfig.Website.Sitename
    $returnQuery += "AND TO_TIMESTAMP(date,time) >= TO_TIMESTAMP('{0}','yyyy-MM-dd HH:mm:ss') " -f $IniConfig.Website.StartTimeTS
	$returnQuery += 'AND sc-status = {0} ' -f $IniConfig.Website.HttpResponse

    if ($IniConfig.Website.Authentication -eq 'Forms')
    {
        $returnQuery += "AND cs-uri-stem LIKE '{0}' AND cs-Method LIKE 'POST' " -f $IniConfig.Website.UrlPath
    }

    if ($TotalFailedLogins -eq $false)
    {
        $returnQuery += 'GROUP BY ClientIP HAVING Hits >= {0} ORDER BY Hits DESC"' -f $IniConfig.Website.FailedLoginsPerIP
    } 

    if ($returnQuery.TrimEnd().EndsWith('"') -eq $false)
    {
        $returnQuery = $returnQuery.TrimEnd() + '"'
    }

    return $returnQuery

} # End Function Get-LogparserQuery

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
        ,
        [Parameter(Mandatory=$true)]
        [System.Object[]]
        # Logparser switches
        $Switches
    )

    try {
        # Use System.Diagnostics.Process to process the auditpol command
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo.Arguments = $($Switches + $Query)
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

Export-ModuleMember -Function 'Get-LogparserQuery','Invoke-Logparser'
