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
    )

    [string] $returnQuery = '"SELECT DISTINCT c-ip as ClientIP, Count(*) AS FailedLoginCount '
    $returnQuery += "FROM '{0}' " -f $IniConfig.Logparser.LogPath
    $returnQuery += "WHERE s-sitename LIKE '{0}' " -f $IniConfig.Website.Sitename
    $returnQuery += 'AND sc-status = {0} ' -f $IniConfig.Website.HttpResponse

    if ($IniConfig.Website.Authentication -imatch 'Forms')
    {
        $returnQuery += "AND cs-uri-stem LIKE '{0}' AND cs-Method LIKE 'POST' " -f $IniConfig.Website.UrlPath
    }

    $returnQuery += "AND TO_TIMESTAMP(date,time) >= TO_TIMESTAMP('{0}','yyyy-MM-dd HH:mm:ss') " -f $IniConfig.Script.StartTimeTS

    $returnQuery += 'GROUP BY ClientIP ORDER BY FailedLoginCount DESC"' -f $minimumThreshold

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
        # Use System.Diagnostics.Process to process the logparser command
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

        [string[]] $errorMessage = @()

        $errorMessage += '[WebsiteFailedLogins][Invoke-Logparser] EXCEPTION: {0}' -f $e.Exception.Message
        $errorMessage += '[WebsiteFailedLogins][Invoke-Logparser] LASTEXITCODE: {0}' -f $LASTEXITCODE
        $errorMessage += '[WebsiteFailedLogins][Invoke-Logparser] COMMAND:'
        $errorMessage += '     {0} {1} {2}' -f $Path,$($Switches -join ' '),$Query

        Write-Error -Message $($errorMessage -join [System.Environment]::NewLine)
    }

    return $logparserReturn

} # end function Invoke-Logparser

Export-ModuleMember -Function 'Get-LogparserQuery','Invoke-Logparser'
