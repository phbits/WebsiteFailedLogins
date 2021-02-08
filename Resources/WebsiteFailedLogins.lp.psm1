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
        # By default, returns query for Client IP (c-ip) failed logins. This switch is used to get the total failed login count query.
        $TotalFailedLogins
        ,
        [Parameter(Mandatory=$false)]
        [switch]
        # Includes cs-uri-stem=UrlPath and cs-method=POST
        $FormsAuth
    )

    # Begin query build
    [string] $returnQuery = '"SELECT '

    if ($TotalFailedLogins)
    {
        $returnQuery += 'COUNT(*) AS Hits '

    } else {

        $returnQuery += 'c-ip AS ClientIP, COUNT(*) AS Hits '
    }

    $returnQuery += "FROM '{0}' " -f $IniConfig.Website.LogPath
    $returnQuery += "WHERE s-sitename LIKE '{0}' " -f $IniConfig.Website.Sitename
    $returnQuery += "AND TO_LOCALTIME(TO_TIMESTAMP(date,time)) >= TO_TIMESTAMP('{0}','yyyy-MM-dd HH:mm:ss') " -f $IniConfig.Website.StartTimeTS
	$returnQuery += 'AND sc-status = {0} ' -f $IniConfig.Website.HttpResponse

    if ($FormsAuth)
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

Export-ModuleMember -Function 'Get-LogparserQuery'
