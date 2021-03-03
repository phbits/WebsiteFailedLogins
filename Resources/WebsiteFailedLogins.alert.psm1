Function Submit-Alert
{
    <#
        .SYNOPSIS

            Submits alert to Windows Event Log or via SMTP.
    #>
    [CmdletBinding()]
    param(
            [Parameter(Mandatory=$true)]
            [System.Collections.Hashtable]
            # INI Configuration.
            $IniConfig
            ,
            [Parameter(Mandatory=$true)]
            [System.Collections.Hashtable]
            # Alert data.
            $AlertData
            ,
            [Parameter(Mandatory=$false)]
            [switch]
            # Signifies terminating error.
            $TerminatingError
    )

    Write-Verbose -Message '[Submit-Alert] Processing alert.'

    $alertSplat = @{
                        'IniConfig' = $IniConfig
                        'AlertData' = $AlertData
                    }

    if ($TerminatingError -eq $true)
    {
        $alertSplat.Add('TerminatingError',$true)
    }

    if ($IniConfig.Alert.Method -imatch 'WinEvent')
    {
        Write-EventAlert @alertSplat
    }

    if ($IniConfig.Alert.Method -imatch 'Smtp')
    {
        Send-SmtpAlert @alertSplat
    }

} # End Function Submit-Alert

Function Write-EventAlert
{
    <#
        .SYNOPSIS

            Writes alert to windows event log.
    #>
    [CmdletBinding()]
    param(
            [Parameter(Mandatory=$true)]
            [System.Collections.Hashtable]
            # INI Configuration.
            $IniConfig
            ,
            [Parameter(Mandatory=$true)]
            [System.Collections.Hashtable]
            # Alert Data.
            $AlertData
            ,
            [Parameter(Mandatory=$false)]
            [switch]
            # Signifies terminating error.
            $TerminatingError
    )

    Write-Verbose -Message '[Write-EventAlert] Writing alert to Event Log.'

    $formattedAlertData = Get-FormattedAlertData -DataType $IniConfig.Alert.DataType `
                                                 -AlertData $AlertData

    $eventProperties = @{
                        'LogName'     = $IniConfig.WinEvent.Logname
                        'Source'      = $IniConfig.WinEvent.Source
                        'EntryType'   = $IniConfig.WinEvent.EntryType
                        'EventId'     = $IniConfig.WinEvent.FailedLoginsPerIPEventId
                        'ErrorAction' = 'Stop'
                        'Message'     = $formattedAlertData
                        }

    if ($AlertData.ContainsKey('TotalFailedLogins'))
    {
        $eventProperties.EventId = $IniConfig.WinEvent.TotalFailedLoginsEventId
    }

    if ($TerminatingError)
    {
        $eventProperties.EntryType = 'Error'
        $eventProperties.EventId   = 200
        $eventProperties.Message   = Get-FormattedAlertData -DataType 'json' -AlertData $AlertData
    }

    try {
            Write-EventLog @eventProperties

    } catch {

        $e = $_
        Write-Error -Message '[Error][Script][Alert] Event log write failed.'
        Write-Error -Message $('[Error][Script][Alert] Exception: {0}' -f $e.Exception.Message)
    }

} # End Function Write-EventAlert

Function Send-SmtpAlert
{
    <#
        .SYNOPSIS

            Sends alert via SMTP.
    #>
    [CmdletBinding()]
    param(
            [Parameter(Mandatory=$true)]
            [System.Collections.Hashtable]
            # INI Configuration.
            $IniConfig
            ,
            [Parameter(Mandatory=$true)]
            [System.Collections.Hashtable]
            # Alert Data.
            $AlertData
            ,
            [Parameter(Mandatory=$false)]
            [switch]
            # Signifies terminating error
            $TerminatingError
    )

    Write-Verbose -Message '[Send-SmtpAlert] Sending alert via SMTP.'

    $formattedAlertData = Get-FormattedAlertData -DataType $IniConfig.Alert.DataType `
                                                 -AlertData $AlertData

    $emailSplat = @{
                        'To'          = $IniConfig.Smtp.To
                        'From'        = $IniConfig.Smtp.From
                        'Subject'     = $IniConfig.Smtp.Subject
                        'SmtpServer'  = $IniConfig.Smtp.Server
                        'Port'        = $IniConfig.Smtp.Port
                        'Body'        = $formattedAlertData
                        'UseSsl'      = $true
                        'ErrorAction' = 'Stop'
                    }

    if ($AlertData.ContainsKey('TotalFailedLogins'))
    {
        $emailSplat.Subject = '[TotalFailedLogins] {0}' -f $IniConfig.Smtp.Subject
    }

    if ($AlertData.ContainsKey('ClientIP'))
    {
        $emailSplat.Subject = '[FailedLoginsPerIP][{0}] {1}' -f $AlertData.ClientIP,$IniConfig.Smtp.Subject
    }

    if ($TerminatingError)
    {
        $emailSplat.Subject = '[TerminatingError] {0}' -f $IniConfig.Smtp.Subject
        $emailSplat.Body = Get-FormattedAlertData -DataType 'json' -AlertData $AlertData
    }

    if ([System.String]::IsNullOrEmpty($IniConfig.Smtp.CredentialXml) -eq $false)
    {
        $emailSplat.Add('Credential', $(Import-Clixml -LiteralPath $IniConfig.Smtp.CredentialXml))
    }

    try {
            Send-MailMessage @emailSplat

    } catch {

        $e = $_
        Write-Error -Message '[Error][Script][Alert] Smtp send failed.'
        Write-Error -Message $('[Error][Script][Alert] Exception: {0}' -f $e.Exception.Message)
    }

} # End Function Send-SmtpAlert

Function Get-FormattedAlertData
{
    <#
        .SYNOPSIS

            Formats the alert data into desired format.
    #>
    [CmdletBinding()]
    [OutputType('System.String')]
    param(
            [Parameter(Mandatory=$true)]
            [System.String]
            # Data type format.
            $DataType
            ,
            [Parameter(Mandatory=$true)]
            # Alert Data.
            $AlertData
    )

    Write-Verbose -Message "[Get-FormattedAlertData] formatting data as $($DataType.ToUpper())."

    switch ($DataType.ToUpper())
    {
        'XML' {
                return [System.Management.Automation.PSSerializer]::Serialize($AlertData,2)
        }

        'JSON' {
                return $($AlertData | ConvertTo-Json)
        }

        default { # Text
                [string[]] $stringData = $AlertData.Keys | ForEach-Object{ "$($_) = $($AlertData[$($_)])" }
                return $($stringData -Join [System.Environment]::NewLine)
        }
    }

} # End Function Get-FormattedAlertData

Export-ModuleMember -Function 'Submit-Alert'
