Import-Module $(Join-Path -Path $PSScriptRoot -ChildPath 'WebsiteFailedLogins.lp.psm1')

Function Assert-ValidIniConfig
{
    <#
        .SYNOPSIS

            Validates settings in the configuration file.
    #>
    [CmdletBinding()]
    [OutputType('System.Collections.Hashtable')]
    param(
            [Parameter(Mandatory=$true)]
            [System.Collections.Hashtable]
            # INI Configuration.
            $IniConfig
            ,
            [Parameter(Mandatory=$false)]
            [switch]
            # Perform basic checks.
            $RunningConfig
    )

    Write-Verbose -Message '[Assert-ValidIniConfig] Validating configuration file settings.'
    $i = 0

    $returnValue = @{
                        'ErrorMessages' = @()
                        'HasError'      = $false
                        'Configuration' = @{}
                    }

    [int[]] $minimumChecks = 1,7,10,11

    do {

        $i++

        if ($returnValue.ErrorMessages.Count -gt 0)
        {
            Write-Verbose -Message "[Assert-ValidIniConfig] Error at #$($i - 1)"
            $i = 1000
        }

        if ($RunningConfig)
        {
            if ($minimumChecks.Contains($i) -eq $false)
            {
                do {

                    $i++

                } until($minimumChecks.Contains($i) -eq $true -or $i -gt 19)
            }
        }

        Write-Verbose -Message "[Assert-ValidIniConfig] Check #$($i)"

        switch($i)
        {
            1 {
                    # BEGIN validate [INI]

                    if ($IniConfig.Count -le 1)
                    {
                        $returnValue.ErrorMessages += '[Error][Config] No configuration file.'
                    }

            }       # END validate [INI]

            2 {     # BEGIN validate [Website] FriendlyName

                    if ([System.String]::IsNullOrEmpty($IniConfig.Website.FriendlyName) -eq $false)
                    {
                        if ($IniConfig.Website.FriendlyName -notmatch "^[a-zA-Z0-9-_\. ]{1,50}$")
                        {
                            $returnValue.ErrorMessages += '[Error][Config][Website] FriendlyName not valid.'
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][Website] FriendlyName not specified.'
                    }

            }       # END validate [Website] FriendlyName

            3 {     # BEGIN validate [Website] Sitename

                    if ([System.String]::IsNullOrEmpty($IniConfig.Website.Sitename) -eq $false)
                    {
                        if ($IniConfig.Website.Sitename -notmatch "^(?i)(w3svc)[0-9]{1,6}$")
                        {
                            $returnValue.ErrorMessages += '[Error][Config][Website] Sitename not valid.'
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][Website] Sitename not specified.'
                    }

            }       # END validate [Website] Sitename

            4 {     # BEGIN validate [Website] Authentication

                    if ([System.String]::IsNullOrEmpty($IniConfig.Website.Authentication) -eq $false)
                    {
                        if ($IniConfig.Website.Authentication -notmatch "^(?i)(Forms|Basic|Windows)$")
                        {
                            $returnValue.ErrorMessages += '[Error][Config][Website] Authentication not valid.'
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][Website] Authentication not specified.'
                    }

            }       # END validate [Website] Authentication

            5 {     # BEGIN validate [Website] HttpResponse

                    if ([System.String]::IsNullOrEmpty($IniConfig.Website.HttpResponse) -eq $false)
                    {
                        if ($IniConfig.Website.HttpResponse -notmatch "^[0-9]{3}$")
                        {
                            $returnValue.ErrorMessages += '[Error][Config][Website] HttpResponse not valid.'
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][Website] HttpResponse not specified.'
                    }

            }       # END validate [Website] HttpResponse

            6 {     # BEGIN validate [Website] UrlPath

                    if ($IniConfig.Website.Authentication -imatch 'Forms')
                    {
                        if ([System.String]::IsNullOrEmpty($IniConfig.Website.UrlPath) -eq $false)
                        {
							try {

								$null = [System.Uri]$('https://www.domain.com{0}' -f $IniConfig.Website.UrlPath)

							} catch {

								$returnValue.ErrorMessages += '[Error][Config][Website] UrlPath not valid.'
							}

						} else {

							$returnValue.ErrorMessages += '[Error][Config][Website] UrlPath must be set when Authentication=Forms.'
						}
					}

            }       # END validate [Website] UrlPath

            7 {     # BEGIN validate [Website] LogPath

                    if ([System.String]::IsNullOrEmpty($IniConfig.Website.LogPath) -eq $false)
                    {
                        try {

                            $logPathRef = Get-Item -LiteralPath $IniConfig.Website.LogPath -ErrorAction Stop

                            if ($logPathRef.PSIsContainer)
                            {
                                if ($logPathRef.FullName.EndsWith('\'))
                                {
                                    $IniConfig.Logparser.Add('LogPath',$('{0}*' -f $logPathRef.FullName))

                                } else {

                                    $IniConfig.Logparser.Add('LogPath',$('{0}\*' -f $logPathRef.FullName))
                                }

                            } else {

                                $IniConfig.Logparser.Add('LogPath',$($logPathRef.FullName))
                            }

                        } catch {

                            $returnValue.ErrorMessages += '[Error][Config][Website] LogPath not valid.'
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][Website] LogPath not specified.'
                    }

            }       # END validate [Website] LogPath

            8 {     # BEGIN validate [Website] FailedLoginsPerIP

                    if ([System.String]::IsNullOrEmpty($IniConfig.Website.FailedLoginsPerIP) -eq $false)
                    {
                        [Int] $intPerIP = 0

                        if ([System.Int32]::TryParse($IniConfig.Website.FailedLoginsPerIP, [ref] $intPerIP))
                        {
                            if ($intPerIP -le 0)
                            {
                                $returnValue.ErrorMessages += '[Error][Config][Website] FailedLoginsPerIP must be a positive number.'
                            }

                        } else {

                            $returnValue.ErrorMessages += '[Error][Config][Website] FailedLoginsPerIP must be a positive number.'
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][Website] FailedLoginsPerIP not specified.'
                    }

            }       # END validate [Website] FailedLoginsPerIP

            9 {     # BEGIN validate [Website] TotalFailedLogins

                    if ([System.String]::IsNullOrEmpty($IniConfig.Website.TotalFailedLogins) -eq $false)
                    {
                        [Int] $intTotal = 0

                        if ([System.Int32]::TryParse($IniConfig.Website.TotalFailedLogins, [ref] $intTotal))
                        {
                            if ($intTotal -le 0)
                            {
                                $returnValue.ErrorMessages += '[Error][Config][Website] TotalFailedLogins must be a positive number.'
                            }

                        } else {

                            $returnValue.ErrorMessages += '[Error][Config][Website] TotalFailedLogins must be a positive number.'
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][Website] TotalFailedLogins not specified.'
                    }

            }       # END validate [Website] TotalFailedLogins

            10 {    # BEGIN validate [Website] StartTime

                    if ([System.String]::IsNullOrEmpty($IniConfig.Website.StartTime) -eq $false)
                    {
                        [Int] $intSeconds = 0

                        if ([System.Int32]::TryParse($IniConfig.Website.StartTime, [ref] $intSeconds))
                        {
                            if ($intSeconds -gt 0)
                            {
                                [int] $IniConfig.Website.StartTime = $intSeconds

                                $startTS = (Get-Date).ToUniversalTime().AddSeconds($($intSeconds * -1))

                                $IniConfig.Script.Add('StartTimeTS', $($startTS.ToString('yyyy-MM-dd HH:mm:ss')))
                                $IniConfig.Script.Add('StartTimeTSZ', $($startTS.ToString('yyyy-MM-ddTHH:mm:ssZ')))

                            } else {

                                $returnValue.ErrorMessages += '[Error][Config][Website] StartTime must be a positive number.'
                            }

                        } else {

                            $returnValue.ErrorMessages += '[Error][Config][Website] StartTime must be a positive number.'
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][Website] StartTime not specified.'
                    }

            }       # END validate [Website] StartTime

            11 {    # BEGIN validate [Logparser] Path

                    if ([System.String]::IsNullOrEmpty($IniConfig.Logparser.Path) -eq $false)
                    {
                        if (Test-Path -LiteralPath $IniConfig.Logparser.Path)
                        {
                            $IniConfig.Logparser.Add('ExePath', $IniConfig.Logparser.Path)

                            $lp = Get-Item -LiteralPath $IniConfig.Logparser.ExePath

                            if ($lp.PSIsContainer)
                            {
                                $lpExePath = Join-Path -Path $IniConfig.Logparser.ExePath -ChildPath 'LogParser.exe'

                                if (Test-Path -LiteralPath $lpExePath)
                                {
                                    $IniConfig.Logparser.ExePath = Join-Path -Path $IniConfig.Logparser.ExePath -ChildPath 'LogParser.exe'

                                } else {

                                    $returnValue.ErrorMessages += '[Error][Config][Logparser] Path not valid.'
                                }

                            } elseif ($lp.Name -eq 'Logparser.exe') {

                                $IniConfig.Logparser.ExePath = $lp.FullName

                            } else {

                                $returnValue.ErrorMessages += '[Error][Config][Logparser] Path not valid.'
                            }

                        } else {

                            $returnValue.ErrorMessages += '[Error][Config][Logparser] Path not valid.'
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][Logparser] Path not specified.'
                    }

            }       # END validate [Logparser] Path

            12 {    # BEGIN validate [Logparser] Exe

                    try {

                        $minVer = [System.Version]::Parse('2.2.10.0')

                        $lpExe = Get-Item -LiteralPath $IniConfig.Logparser.ExePath -ErrorAction Stop

                        $lpVer = [System.Version]::Parse($lpExe.VersionInfo.FileVersion)

                        if ($minVer -lt $lpVer)
                        {
                            $returnValue.ErrorMessages += $('[Error][Config][Logparser] Current Microsoft (R) Log Parser Version {0}' -f $lpExe.VersionInfo.FileVersion)

                            $returnValue.ErrorMessages += '[Error][Config][Logparser] Must be Microsoft (R) Log Parser Version 2.2.10'
                        }

                    } catch {

                        $e = $_
                        $returnValue.ErrorMessages += '[Error][Config][Logparser] Logparser.exe validation error.'
                        $returnValue.ErrorMessages += $('[Error][Config][Logparser] Exception: {0}' -f $e.Exception.Message)
                    }

            }       # END validate [Logparser] Exe

            13 {    # BEGIN validate [Logparser] dll

                    $minVer = [System.Version]::Parse('2.2.10.0')

                    $lp = Get-Item -LiteralPath $IniConfig.Logparser.ExePath

                    $lpDllPath = Join-Path -Path $lp.Directory -ChildPath 'logparser.dll'

                    try {

                        $lpDll = Get-Item -LiteralPath $lpDllPath

                        $lpVer = [System.Version]::Parse($lpExe.VersionInfo.FileVersion)

                        if ($lpVer -lt $minVer)
                        {
                            $returnValue.ErrorMessages += $('[Error][Config][Logparser] Current Microsoft (R) Log Parser DLL Version {0}' -f $lpDll.VersionInfo.FileVersion)
                            $returnValue.ErrorMessages += '[Error][Config][Logparser] Must be Microsoft (R) Log Parser DLL Version 2.2.10'
                        }

                    } catch {

                        $e = $_
                        $returnValue.ErrorMessages += '[Error][Config][Logparser] Logparser.dll validation error.'
                        $returnValue.ErrorMessages += $('[Error][Config][Logparser] Exception: {0}' -f $e.Exception.Message)
                    }

            }       # END validate [Logparser] dll

            14 {    # BEGIN validate [Logparser] run test query

                    $minVer = [System.Version]::Parse('2.2.10.0')

                    $lpQuery = "`"SELECT FileVersion FROM '{0}'`"" -f $IniConfig.Logparser.ExePath

                    $logparserArgs = @('-e:-1','-iw:ON','-headers:OFF','-q:ON','-i:FS','-o:CSV','-preserveLastAccTime:ON')

                    try {

                        [string] $lpFileVersion = Invoke-Logparser -Path $IniConfig.Logparser.ExePath `
                                                                    -Query $lpQuery `
                                                                    -Switches $logparserArgs

                        if ([System.String]::IsNullOrEmpty($lpFileVersion) -eq $false)
                        {
                            if ($lpFileVersion.Trim() -eq 'Task aborted.')
                            {
                                $returnValue.ErrorMessages += '[Error][Config][Logparser] Error testing launch of Logparser.exe'
                                $returnValue.ErrorMessages += '[Error][Config][Logparser] Task aborted.'

                            } elseif ($lpFileVersion.Trim().StartsWith('2.2.10') -eq $false) {

                                $returnValue.ErrorMessages += $('[Error][Config][Logparser] Current Microsoft (R) Log Parser Version {0}' -f $lpFileVersion)
                                $returnValue.ErrorMessages += '[Error][Config][Logparser] Must be Microsoft (R) Log Parser Version 2.2.10 or newer.'
                            }

                        } else {

                            $returnValue.ErrorMessages += '[Error][Config][Logparser] Error testing launch of Logparser.exe'
                            $returnValue.ErrorMessages += '[Error][Config][Logparser] No value returned.'
                        }

                    } catch {

                        $e = $_
                        $returnValue.ErrorMessages += '[Error][Config][Logparser] Error testing launch of Logparser.exe'
                        $returnValue.ErrorMessages += $('[Error][Config][Logparser] Exception: {0}' -f $e.Exception.Message)
                    }

            }       # END validate [Logparser] run test query

            15 {    # BEGIN validate [Alert] Method

                    if ([System.String]::IsNullOrEmpty($IniConfig.Alert.Method) -eq $false)
                    {
                        if ($IniConfig.Alert.Method -notmatch "^(?i)Smtp|WinEvent|None$")
                        {
                            $returnValue.ErrorMessages += '[Error][Alert] Method not valid.'
                        }

                    } else {

                        $IniConfig.Alert.Method = 'None'
                    }

            }       # END validate [Alert] Method

            16 {    # BEGIN validate [Alert] DataType

                    if ([System.String]::IsNullOrEmpty($IniConfig.Alert.DataType) -eq $false)
                    {
                        if ($IniConfig.Alert.DataType -notmatch "^(?i)(text|xml|json)$")
                        {
                            $returnValue.ErrorMessages += '[Error][Alert] DataType not valid.'
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Alert] DataType not specified.'
                    }

            }       # END validate [Alert] DataType

            17 {    # BEGIN validate [SMTP]

                    if ([System.String]::IsNullOrEmpty($IniConfig.Alert.Method) -eq $false)
                    {
                        if ($IniConfig.Alert.Method -imatch 'Smtp')
                        {
                            $smtpResult = Assert-ValidSmtpSettings -IniConfig $IniConfig

                            if ($smtpResult.HasError -eq $true)
                            {
                                $returnValue.ErrorMessages = $smtpResult.ErrorMessages
                            }
                        }
                    }

            }       # END validate [SMTP]

            18 {    # BEGIN validate [WinEvent]

                    if ([System.String]::IsNullOrEmpty($IniConfig.Alert.Method) -eq $false)
                    {
                        if ($IniConfig.Alert.Method -imatch 'WinEvent')
                        {
                            $winEventResult = Assert-ValidWinEventSettings -IniConfig $IniConfig

                            if ($winEventResult.HasError -eq $true)
                            {
                                $returnValue.ErrorMessages = $winEventResult.ErrorMessages
                            }
                        }
                    }

            }       # END validate [WinEvent]

            19 {    # BEGIN validate IIS Log Access & verify logging fields

                    $lpQuery = "`"SELECT TOP 1 * FROM '$($IniConfig.Logparser.LogPath)' " + `
                               "WHERE s-sitename LIKE '$($IniConfig.Website.Sitename)' " + `
                               "ORDER BY date, time DESC`""

                    $logparserArgs = @('-recurse:-1','-headers:ON','-iw:ON','-q:ON','-i:IISW3C','-o:CSV')

                    $fullLpCmd = "$($IniConfig.Logparser.ExePath) $($logparserArgs -join ' ') $($lpQuery)"

                    $lpError = @(
                                    '[Error][Config][Script] Full Logparser command:',
                                    $('[Error][Config][Script]   {0}' -f $fullLpCmd)
                                )

                    $lpOutput = Invoke-Logparser -Path $IniConfig.Logparser.ExePath `
                                                -Query $lpQuery `
                                                -Switches $logparserArgs

                    if ([System.String]::IsNullOrEmpty($lpOutput) -eq $false)
                    {
                        $lpOutputCsv = $lpOutput | ConvertFrom-Csv

                        # validate IIS logging field
                        $iisLogFields = @( 'date','time','c-ip','s-sitename','cs-method','cs-uri-stem','sc-status' )

                        $iisLogFieldError = $false

                        foreach ($logField in $iisLogFields)
                        {
                            # check if field exists
                            if ($null -eq $(Get-Member -InputObject $lpOutputCsv -Name $logField -MemberType NoteProperty))
                            {
                                $iisLogFieldError = $true
                                $returnValue.ErrorMessages += "[Error][Config][Script] IIS log field '$logField' not being logged."

                            } else {

                                # is a value being logged
                                $propertyValue = $lpOutputCsv | Select-Object -ExpandProperty $logField

                                if ([System.String]::IsNullOrEmpty($propertyValue) -eq $true)
                                {
                                    $iisLogFieldError = $true
                                    $returnValue.ErrorMessages += "[Error][Config][Script] IIS log field '$logField' not being logged."
                                }
                            }
                        }

                        if ($iisLogFieldError -eq $true)
                        {
                            $returnValue.ErrorMessages = $lpError + $returnValue.ErrorMessages
                            $returnValue.ErrorMessages += '[Error][Config][Script] https://github.com/phbits/WebsiteFailedLogins/wiki/Prerequisites'
                        }

                    } else {

                        $returnValue.ErrorMessages += $lpError
                        $returnValue.ErrorMessages += '[Error][Config][Script] Failed to get an IIS log record.'
                    }

            }       # END validate IIS Log Access & verify logging fields

            default {

                if ($returnValue.ErrorMessages.Count -gt 0)
                {
                    $returnValue.HasError = $true

                    $returnValue.ErrorMessages += '[Error][Config][Script] Terminating script.'

                    Write-Error -Message $($returnValue.ErrorMessages -join [System.Environment]::NewLine)
                }

                $i = 0
            }
        }

    } while ($i -gt 0)

    $returnValue.Configuration = $IniConfig

    return $returnValue

} # End Function Assert-ValidIniConfig

Function Assert-ValidWinEventSettings
{
    <#
        .SYNOPSIS

            Validates WinEvent settings in the configuration file.
    #>
    [CmdletBinding()]
    [OutputType('System.Collections.Hashtable')]
    param(
            [Parameter(Mandatory=$true)]
            [System.Collections.Hashtable]
            # INI Configuration.
            $IniConfig
    )

    Write-Verbose -Message '[Assert-ValidWinEventSettings] Validating WinEvent configuration file settings.'

    $n = 0

    $returnValue = @{
                        'ErrorMessages' = @()
                        'HasError'      = $false
                        'Configuration' = @{}
                    }

    do {

        $n++

        if ($returnValue.ErrorMessages.Count -gt 0)
        {
            $n = 100
        }

        Write-Verbose -Message "[Assert-ValidWinEventSettings] Check #$($n)"

        switch ($n)
        {
            1 {     # BEGIN validate [WinEvent] Logname

                    if ([System.String]::IsNullOrEmpty($IniConfig.WinEvent.Logname) -eq $false)
                    {
                        if ([System.Diagnostics.EventLog]::Exists($IniConfig.WinEvent.Logname) -eq $false)
                        {
                            $returnValue.ErrorMessages += '[Error][Config][WinEvent] Logname not valid.'
                            $returnValue.ErrorMessages += $('[Error][Config][WinEvent]   {0} does not exist.' -f $IniConfig.WinEvent.Logname)
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][WinEvent] Logname not specified.'
                    }

            }       # END validate [WinEvent] Logname

            2 {     # BEGIN validate [WinEvent] Source

                    if ([System.String]::IsNullOrEmpty($IniConfig.WinEvent.Source) -eq $false)
                    {
                        $result = [System.Diagnostics.EventLog]::SourceExists($IniConfig.WinEvent.Source)

                        if ($result -eq $false)
                        {
                            $returnValue.ErrorMessages += '[Error][Config][WinEvent] Source does not exist.'
                            $returnValue.ErrorMessages += '[Error][Config][WinEvent] Run the following command in an elevated prompt:'
                            $returnValue.ErrorMessages += $('[Error][Config][WinEvent]    New-EventLog -LogName Application -Source {0}' -f $IniConfig.WinEvent.Source)
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][WinEvent] Source not specified.'
                    }

            }       # END validate [WinEvent] Source

            3 {     # BEGIN validate [WinEvent] EntryType

                    if ([System.String]::IsNullOrEmpty($IniConfig.WinEvent.EntryType) -eq $false)
                    {
                        if ($IniConfig.WinEvent.EntryType -notmatch "^(?i)(Error|FailureAudit|Information|SuccessAudit|Warning)$")
                        {
                            $returnValue.ErrorMessages += '[Error][Config][WinEvent] EntryType not valid.'
                            $returnValue.ErrorMessages += '[Error][Config][WinEvent] Choose one: Error,FailureAudit,Information,SuccessAudit,Warning'
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][WinEvent] EntryType not specified.'
                        $returnValue.ErrorMessages += '[Error][Config][WinEvent] Choose one: Error,FailureAudit,Information,SuccessAudit,Warning'
                    }

            }       # END validate [WinEvent] EntryType

            4 {     # BEGIN validate [WinEvent] FailedLoginsPerIPEventId

                    if ([System.String]::IsNullOrEmpty($IniConfig.WinEvent.FailedLoginsPerIPEventId) -eq $false)
                    {
                        [Int] $intFailedLoginsPerIPEventId = 0

                        if ([System.Int32]::TryParse($IniConfig.WinEvent.FailedLoginsPerIPEventId, [ref] $intFailedLoginsPerIPEventId))
                        {
                            $winEventIdResult = Assert-WinEventId -EventName 'FailedLoginsPerIPEventId' `
                                                                  -EventId $intFailedLoginsPerIPEventId

                            if ($winEventIdResult.HasError -eq $true)
                            {
                                $returnValue.ErrorMessages = $winEventIdResult.ErrorMessages
                            }

                        } else {

                            $returnValue.ErrorMessages += '[Error][Config][WinEvent] FailedLoginsPerIPEventId not valid.'
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][WinEvent] FailedLoginsPerIPEventId not specified.'
                    }

            }       # END validate [WinEvent] FailedLoginsPerIPEventId

            5 {     # BEGIN validate [WinEvent] TotalFailedLoginsEventId

                    if ([System.String]::IsNullOrEmpty($IniConfig.WinEvent.TotalFailedLoginsEventId) -eq $false)
                    {
                        [Int] $intTotalFailedLoginsEventId = 0

                        if ([System.Int32]::TryParse($IniConfig.WinEvent.TotalFailedLoginsEventId, [ref] $intTotalFailedLoginsEventId))
                        {
                            $winEventIdResult = Assert-WinEventId -EventName 'TotalFailedLoginsEventId' `
                                                                -EventId $intTotalFailedLoginsEventId

                            if ($winEventIdResult.HasError -eq $true)
                            {
                                $returnValue.ErrorMessages = $winEventIdResult.ErrorMessages
                            }

                        } else {

                            $returnValue.ErrorMessages += '[Error][Config][WinEvent] TotalFailedLoginsEventId not valid.'
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][WinEvent] TotalFailedLoginsEventId not specified.'
                    }

            }       # END validate [WinEvent] TotalFailedLoginsEventId

            6 {     # BEGIN validate [WinEvent] Unique TotalFailedLoginsEventId & FailedLoginsPerIPEventId

                    if ($IniConfig.WinEvent.TotalFailedLoginsEventId -eq $IniConfig.WinEvent.FailedLoginsPerIPEventId)
                    {
                        $returnValue.ErrorMessages += '[Error][Config][WinEvent] TotalFailedLoginsEventId and FailedLoginsPerIPEventId must be different.'
                    }

            }       # END validate [WinEvent] Unique TotalFailedLoginsEventId & FailedLoginsPerIPEventId

            7 {     # BEGIN validate [WinEvent] Write Start

                    try {

                        Write-EventLog -LogName $IniConfig.WinEvent.Logname `
                                        -Source $IniConfig.WinEvent.Source `
                                        -EntryType $IniConfig.WinEvent.EntryType `
                                        -EventId 100 `
                                        -ErrorAction Stop `
                                        -Message 'Write-EventLog success.'

                    } catch {

                        $e = $_

                        $returnValue.ErrorMessages += '[Error][Config][Script] Event log write failed.'
                        $returnValue.ErrorMessages += $('[Error][Config][Script] Exception: {0}' -f $e.Exception.Message)
                    }

            }       # END validate [WinEvent] Write Start

            default {

                    if ($returnValue.ErrorMessages.Count -gt 0)
                    {
                        $returnValue.HasError = $true
                    }

                    $n = 0
            }
        }

    } while ($n -gt 0)

    return $returnValue

} # End Function Assert-ValidWinEventSettings

Function Assert-WinEventId
{
    <#
        .SYNOPSIS

            Validates WinEvent Event IDs
    #>
    [CmdletBinding()]
    [OutputType('System.Collections.Hashtable')]
    param(
            [Parameter(Mandatory=$true)]
            [String]
            # Event Name
            $EventName
            ,
            [Parameter(Mandatory=$true)]
            [Int]
            # Event ID
            $EventId
    )

    $returnValue = @{
                        'ErrorMessages' = @()
                        'HasError'      = $false
                    }

    switch ($EventId)
    {
        0 {
            $returnValue.ErrorMessages += $('[Error][Config][WinEvent] {0} cannot be zero.' -f $EventName)
        }
        100 {
            $returnValue.ErrorMessages += $('[Error][Config][WinEvent] {0} cannot be {1}.' -f $EventName,$EventId)
        }
        200 {
            $returnValue.ErrorMessages += $('[Error][Config][WinEvent] {0} cannot be {1}.' -f $EventName,$EventId)
        }
        default {

            if (-not $($EventId -gt 0 -and $EventId -le 999))
            {
                $returnValue.ErrorMessages += $('[Error][Config][WinEvent] {0} not valid.' -f $EventName)
            }
        }
    }

    if ($returnValue.ErrorMessages.Count -gt 0)
    {
        $returnValue.ErrorMessages += $('[Error][Config][WinEvent] {0} must be between 1-999.' -f $EventName)
        $returnValue.HasError = $true
    }

    return $returnValue

} # End Function Assert-WinEventId

Function Assert-ValidSmtpSettings
{
    <#
        .SYNOPSIS

            Validates SMTP settings in the configuration file.
    #>
    [CmdletBinding()]
    [OutputType('System.Collections.Hashtable')]
    param(
            [Parameter(Mandatory=$true)]
            [System.Collections.Hashtable]
            # INI Configuration.
            $IniConfig
    )

    Write-Verbose -Message '[Assert-ValidSmtpSettings] Validating SMTP configuration file settings.'

    $n = 0

    $returnValue = @{
                        'ErrorMessages' = @()
                        'HasError'      = $false
                        'Configuration' = @{}
                    }

    do {

        $n++

        if ($returnValue.ErrorMessages.Count -gt 0)
        {
            $n = 100
        }

        Write-Verbose -Message "[Assert-ValidSmtpSettings] Check #$($n)"

        switch ($n)
        {
            1 {    # BEGIN validate [SMTP] To

                    if ([System.String]::IsNullOrEmpty($IniConfig.Smtp.To) -eq $false)
                    {
                        try {

                            $null = [System.Net.Mail.MailAddress]::New($IniConfig.Smtp.To)

                        } catch {

                            $returnValue.ErrorMessages += '[Error][Config][SMTP] TO not valid.'
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][SMTP] TO not specified.'
                    }

            }       # END validate [SMTP] To

            2 {     # BEGIN validate [SMTP] From

                    if ([System.String]::IsNullOrEmpty($IniConfig.Smtp.From) -eq $false)
                    {
                        try {

                            $null = [System.Net.Mail.MailAddress]::new($IniConfig.Smtp.From)

                        } catch {

                            $returnValue.ErrorMessages += '[Error][Config][SMTP] FROM not valid.'
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][SMTP] FROM not specified.'
                    }

            }       # END validate [SMTP] From

            3 {     # BEGIN validate [SMTP] Subject

                    if ([System.String]::IsNullOrEmpty($IniConfig.Smtp.Subject))
                    {
                        $returnValue.ErrorMessages += '[Error][SMTP] SUBJECT not specified.'

                    } else {

                        try {

                            $msg = [System.Net.Mail.MailMessage]::new()

                            $msg.Subject = $IniConfig.Smtp.Subject

                            $msg.Dispose()

                            Remove-Variable -Name msg

                        } catch {

                            $returnValue.ErrorMessages += '[Error][Config][SMTP] SUBJECT not valid.'
                        }
                    }

            }       # END validate [SMTP] Subject

            4 {     # BEGIN validate [SMTP] Port

                    if ([System.String]::IsNullOrEmpty($IniConfig.Smtp.Port) -eq $false)
                    {
                        [Int] $intPort = 0

                        if ([System.Int32]::TryParse($IniConfig.Smtp.Port, [ref] $intPort))
                        {
                            if (-not $($intPort -gt 0 -and $intPort -le 65535))
                            {
                                $returnValue.ErrorMessages += '[Error][Config][SMTP] PORT must be 1-65535.'
                            }

                        } else {

                            $returnValue.ErrorMessages += '[Error][Config][SMTP] PORT must be 1-65535.'
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][SMTP] PORT not specified.'
                    }

            }       # END validate [SMTP] Port

            5 {     # BEGIN validate [SMTP] Server

                    if ([System.String]::IsNullOrEmpty($IniConfig.Smtp.Server) -eq $false)
                    {
                        try {

                            $smtpServer = New-Object System.Net.Sockets.TcpClient($IniConfig.Smtp.Server, $IniConfig.Smtp.Port)

                            if ($smtpServer.Connected -eq $false)
                            {
                                $returnValue.ErrorMessages += '[Error][Config][SMTP] TCP connection failed to {0}:{1}' -f $IniConfig.Smtp.Server,$IniConfig.Smtp.Port
                            }

                            $smtpServer.Dispose()

                            Remove-Variable -Name smtpServer

                        } catch {

                            $e = $_
                            $returnValue.ErrorMessages += '[Error][Config][SMTP] TCP connection failed to {0}:{1}' -f $IniConfig.Smtp.Server,$IniConfig.Smtp.Port
                            $returnValue.ErrorMessages += $('[Error][Config][SMTP] Exception: {0}' -f $e.Exception.Message)
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][SMTP] SERVER not specified.'
                    }

            }       # END validate [SMTP] Server

            6 {     # BEGIN validate [SMTP] CredentialXml

                    if ([System.String]::IsNullOrEmpty($IniConfig.Smtp.CredentialXml) -eq $false)
                    {
                        try {

                            $credCheck = Import-Clixml -LiteralPath $IniConfig.Smtp.CredentialXml -ErrorAction Stop

                            if ($credCheck.GetType().Name -ne 'PSCredential')
                            {
                                $returnValue.ErrorMessages += '[Error][Config][SMTP] CredentialXml import failed.'
                            }

                            Remove-Variable -Name credCheck

                        } catch {

                            $e = $_
                            $returnValue.ErrorMessages += '[Error][Config][SMTP] CredentialXml import failed.'
                            $returnValue.ErrorMessages += $('[Error][Config][SMTP] Exception: {0}' -f $e.Exception.Message)
                        }
                    }

            }       # END validate [SMTP] CredentialXml

            7 {     # BEGIN validate [SMTP] Send test alert

                    $emailSplat = @{
                        'To'          = $IniConfig.Smtp.To
                        'From'        = $IniConfig.Smtp.From
                        'Subject'     = $('[TEST] {0}' -f $IniConfig.Smtp.Subject)
                        'SmtpServer'  = $IniConfig.Smtp.Server
                        'Port'        = $IniConfig.Smtp.Port
                        'Body'        = "Test message to validate configuration.`n`nUse '-RunningConfig' switch once all errors have been fixed."
                        'UseSsl'      = $true
                        'ErrorAction' = 'Stop'
                    }

                    if ([System.String]::IsNullOrEmpty($IniConfig.Smtp.CredentialXml) -eq $false)
                    {
                        $emailSplat.Add('Credential', $(Import-Clixml -LiteralPath $IniConfig.Smtp.CredentialXml))
                    }

                    try {

                        Send-MailMessage @emailSplat | Out-Null

                        Remove-Variable -Name emailSplat

                    } catch {

                        $e = $_
                        $returnValue.ErrorMessages += '[Error][Config][SMTP] Send test message failed.'
                        $returnValue.ErrorMessages += $('[Error][Config][SMTP] Exception: {0}' -f $e.Exception.Message)
                    }

            }       # END validate [SMTP] Send test alert

            default {

                if ($returnValue.ErrorMessages.Count -gt 0)
                {
                    $returnValue.HasError = $true
                }

                $n = 0
            }
        }

    } while ($n -gt 0)

    return $returnValue

} # End Function Assert-ValidSmtpSettings

Function Get-IniConfig
{
    <#
        .SYNOPSIS

            Parses the configuration file into a hashtable.

        .INPUTS

            System.String

        .LINK

            https://blogs.technet.microsoft.com/heyscriptingguy/2011/08/20/use-powershell-to-work-with-any-ini-file/
    #>
    [CmdletBinding()]
    [OutputType('System.Collections.Hashtable')]
    param(
            [Parameter(Mandatory=$true)]
            [ValidateScript({Test-Path $_})]
            [string]
            # Path to configuration file.
            $Path
    )

    Write-Verbose -Message '[Get-IniConfig] Reading configuration file.'

    $config = @{}

    switch -regex -file $Path
    {
        "^\[(.+)\].*$" # Section
        {
            $section = $matches[1]

            if ($section.ToString().Trim().StartsWith('#') -eq $false)
            {
                $config.Add($section.Trim(),@{})
            }
        }

        "(.+?)\s*=(.*)" # Key
        {
            $name,$value = $matches[1..2]

            if ($name.ToString().Trim().StartsWith('#') -eq $false)
            {
                $config[$section].Add($name.Trim(), $value.Trim())
            }
        }
    }

    if ([System.String]::IsNullOrEmpty($config['Script']))
    {
        $config.Add('Script',@{})
    }

    if ($config.ContainsKey('Script'))
    {
        $config['Script'].Add('ConfigPath',(Get-Item $Path).FullName)

        $config['Script'].Add('StartTS', (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))
    }

    return $config

} # End Function Get-IniConfig

Export-ModuleMember -Function 'Assert-ValidIniConfig','Get-IniConfig'
