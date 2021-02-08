
Function Submit-Alert
{
    <#
        .SYNOPSIS

            Submits alert to Event Log or via SMTP.
    #>
    [CmdletBinding()]
    param(
            [parameter(Mandatory=$true)]
            [System.Collections.Hashtable]
            # INI Configuration.
            $IniConfig
            ,
            [parameter(Mandatory=$true)]
            [System.Collections.Hashtable]
            # Alert data.
            $Alert
            ,
            [parameter(Mandatory=$true)]
            [System.String[]]
            # Message body.
            $Message
            ,
            [parameter(Mandatory=$false)]
            [System.String]
            # Message appended to subject.
            $SubjectAppend
            ,
            [parameter(Mandatory=$false)]
            [switch]
            # Defaults to FailedLoginsPerIP. This switch enables TotalFailedLogins.
            $TotalFailedLogins
            ,
            [parameter(Mandatory=$false)]
            [switch]
            # Signifies terminating error.
            $TerminatingError
    )

    if ($IniConfig.Alert.Method -imatch "^(.*)WinEvent(.*)$")
    {
        if ($TerminatingError)
        {
            Write-EventAlert -Message $Message -TerminatingError

        } elseif ($TotalFailedLogins)
        {

            Write-EventAlert -Message $Message -TotalFailedLogins

        } else {

            Write-EventAlert -Message $Message
        }
    }

    if ($IniConfig.Alert.Method -imatch "^(.*)Smtp(.*)$")
    {
        if ($TerminatingError)
        {
            Send-SmtpAlert -Message $Message -TerminatingError

        } else {

            $subject = $IniConfig.Smtp.Subject

            if([System.String]::IsNullOrEmpty($SubjectAppend) -eq $false){

                $subject = '{0} {1}' -f $IniConfig.Smtp.Subject,$SubjectAppend
            }
            
            Send-SmtpAlert -Message $Message -MessageSubject $subject
        }
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
            [parameter(Mandatory=$true)]
            [System.Collections.Hashtable]
            # INI Configuration.
            $IniConfig
            ,
            [parameter(Mandatory=$true)]
            [System.Collections.Hashtable]
            # Alert
            $Alert
            ,
            [parameter(Mandatory=$false)]
            [switch]
            # Defaults to FailedLoginsPerIP. This switch enables TotalFailedLogins.
            $TotalFailedLogins
            ,
            [parameter(Mandatory=$false)]
            [switch]
            # Signifies terminating error.
            $TerminatingError
    )

    $eventEntryType = $IniConfig.WinEvent.EntryType

    $eventId = $IniConfig.WinEvent.FailedLoginsPerIPEventId

    if($TotalFailedLogins)
    {
        $eventId = $IniConfig.WinEvent.TotalFailedLoginsEventId
    }

    if($TerminatingError)
    {
        $eventEntryType = 'Error'

        $eventId = 200
    }

    try {
            Write-EventLog -LogName $IniConfig.WinEvent.Logname `
                           -Source $IniConfig.WinEvent.Source `
                           -EntryType $eventEntryType `
                           -EventId $eventId `
                           -Message $([System.Management.Automation.PSSerializer]::Serialize($Alert,2)) `
                           -ErrorAction Stop

    } catch {
        
        $e = $_

        Write-Host $('[Error][Script] Alert Event log write failed. {0}' -f $e.Exception.Message)
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
            [parameter(Mandatory=$true)]
            [System.Collections.Hashtable]
            # INI Configuration.
            $IniConfig
            ,
            [parameter(Mandatory=$true)]
            [System.Collections.Hashtable]
            # Alert
            $Alert
            ,
            [parameter(Mandatory=$true)]
            [System.String[]]
            # Message body.
            $Message
            ,
            [parameter(Mandatory=$false)]
            [System.String]
            # Subject for email.
            $MessageSubject
            ,
            [parameter(Mandatory=$false)]
            [switch]
            # Signifies terminating error
            $TerminatingError
    )

    $emailSubject = $IniConfig.Smtp.Subject

    if([System.String]::IsNullOrEmpty($emailSubject) -eq $false)
    {
        $emailSubject = $MessageSubject
    }

    if($TerminatingError)
    {
        $emailSubject = '[TerminatingError] {0}' -f $emailSubject
    }

    try {

        if([System.String]::IsNullOrEmpty($IniConfig.Smtp.CredentialXml))
        {
            Send-MailMessage -To $IniConfig.Smtp.To `
                             -From $IniConfig.Smtp.From `
                             -Subject $EmailSubject `
                             -SmtpServer $IniConfig.Smtp.Server `
                             -Port $IniConfig.Smtp.Port `
                             -Body $([System.Management.Automation.PSSerializer]::Serialize($Alert,2)) `
                             -UseSsl `
                             -ErrorAction Stop

        } else {

            $creds = Import-Clixml -LiteralPath $IniConfig.Smtp.CredentialXml

            Send-MailMessage -To $IniConfig.Smtp.To `
                             -From $IniConfig.Smtp.From `
                             -Subject $EmailSubject `
                             -SmtpServer $IniConfig.Smtp.Server `
                             -Port $IniConfig.Smtp.Port `
                             -Body $([System.Management.Automation.PSSerializer]::Serialize($Alert,2)) `
                             -Credential $creds `
                             -UseSsl `
                             -ErrorAction Stop

            Remove-Variable -Name creds
        }

    } catch {
        
        $e = $_

        Write-Host $('[Error][Script] Alert smtp send failed. {0}' -f $e.Exception.Message)
    }

} # End Function Send-SmtpAlert

