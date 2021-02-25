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

    $i = 0

    $returnValue = @{
                        'ErrorMessages' = @()
                        'HasError'      = $false
                        'Configuration' = @{}
                    }

    [int[]] $minimumChecks = 1,7,8,9,10,11,19,25,26,27

    do {

        $i++

        if ($returnValue.ErrorMessages.Count -gt 0)
        {
            $i = 1000
        }

        if ($RunningConfig)
        {
            if ($minimumChecks.Contains($i) -eq $false)
            {
                do {

                    $i++

                } until($minimumChecks.Contains($i) -eq $true -or $i -gt 31)
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
                        [int] $intPerIP = 0

                        if ([System.Int32]::TryParse($IniConfig.Website.FailedLoginsPerIP, [ref]$intPerIP))
                        {
                            if ($intPerIP -gt 0)
                            {
                                $IniConfig.Website.FailedLoginsPerIP = $intPerIP

                            } else {

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
                        [Int32] $intTotal = 0

                        if ([System.Int32]::TryParse($IniConfig.Website.TotalFailedLogins, [ref]$intTotal))
                        {
                            if ($intTotal -gt 0)
                            {
                                [int] $IniConfig.Website.TotalFailedLogins = $intTotal

                            } else {

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
                        [int] $intSeconds = 0

                        if ([System.Int32]::TryParse($IniConfig.Website.StartTime, [ref]$intSeconds))
                        {
                            if ($intSeconds -gt 0)
                            {
                                [int] $IniConfig.Website.StartTime = $intSeconds

                                $IniConfig.Website.StartTimeTS = (Get-Date).ToUniversalTime().AddSeconds($($intSeconds * -1)).ToString('yyyy-MM-dd HH:mm:ss')

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
                                $IniConfig.Logparser.ExePath = Join-Path -Path $IniConfig.Logparser.ExePath -ChildPath 'LogParser.exe'
                            }

                            try {

                                $lpExe = Get-Item -LiteralPath $IniConfig.Logparser.ExePath -ErrorAction Stop

                                if ($lpExe.VersionInfo.FileVersion -ne '2.2.10.0')
                                {
                                    $returnValue.ErrorMessages += $('[Error][Config][Logparser] Current Microsoft (R) Log Parser Version {0}' -f $lpExe.VersionInfo.FileVersion)

                                    $returnValue.ErrorMessages += '[Error][Config][Logparser] Must be Microsoft (R) Log Parser Version 2.2.10'
                                }

                            } catch {

                                $e = $_
                                $returnValue.ErrorMessages += '[Error][Config][Logparser] Logparser.exe validation error.'
                                $returnValue.ErrorMessages += $('[Error][Config][Logparser] Exception: {0}' -f $e.Exception.Message)
                            }

                        } else {

                            $returnValue.ErrorMessages += '[Error][Config][Logparser] Path not valid.'
                        }

                    } else {

                        $returnValue.ErrorMessages += '[Error][Config][Logparser] Path not specified.'
                    }

            }       # END validate [Logparser] Path

            12 {    # BEGIN validate [Logparser] dll

                $lp = Get-Item -LiteralPath $IniConfig.Logparser.ExePath

                $lpDllPath = Join-Path -Path $lp.Directory -ChildPath 'logparser.dll'

                try {

                    $lpDll = Get-Item -LiteralPath $lpDllPath

                    if ($lpDll.VersionInfo.FileVersion -ne '2.2.10.0')
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

            13 {    # BEGIN validate [Logparser] run test query

                    if ($IniConfig.Logparser.ContainsKey('ExePath'))
                    {
                        # test launch of logparser
                        try {

                            $lpQuery = "`"SELECT FileVersion FROM `'{0}`'`"" -f $IniConfig.Logparser.ExePath

                            $logparserArgs = @('-e:-1','-iw:ON','-headers:OFF','-q:ON','-i:FS','-o:CSV')

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
                                    $returnValue.ErrorMessages += '[Error][Config][Logparser] Must be Microsoft (R) Log Parser Version 2.2.10'
                                }

                            } else {

                                $returnValue.ErrorMessages += '[Error][Config][Logparser] Error testing launch of Logparser.exe'
                                $returnValue.ErrorMessages += '[Error][Config][Logparser] No value returned.'
                            }

                        } catch {

                            $e = $_
                            $returnValue.ErrorMessages += '[Error][Config][Logparser] Error testing launch of Logparser.exe'
                            $returnValue.ErrorMessages += $('[Error][Config][Logparser] {0}' -f $e.Exception.Message)
                        }
                    }

            }       # END validate [Logparser] run test query

            14 {    # BEGIN validate [Alert] Method

                    if ([System.String]::IsNullOrEmpty($IniConfig.Alert.Method) -eq $false)
                    {
                        if ($IniConfig.Alert.Method -notmatch "^(?i)Smtp|WinEvent|stdout|None|\s$")
                        {
                            $returnValue.ErrorMessages += '[Error][Alert] Method not valid.'
                        }

                    } else {

                        $IniConfig.Alert.Method = 'stdout'
                    }

            }       # END validate [Alert] Method

            15 {    # BEGIN validate [Alert] DataType

                if ([System.String]::IsNullOrEmpty($IniConfig.Alert.DataType) -eq $false)
                {
                    if ($IniConfig.Alert.DataType -notmatch "^(?i)text|xml|json$")
                    {
                        $returnValue.ErrorMessages += '[Error][Alert] DataType not valid.'
                    }

                } else {

                    $returnValue.ErrorMessages += '[Error][Alert] DataType not specified.'
                }

            }       # END validate [Alert] DataType

            16 {    # BEGIN validate [SMTP] To

                    if ([System.String]::IsNullOrEmpty($IniConfig.Alert.Method) -eq $false)
                    {
                        if ($IniConfig.Alert.Method -imatch 'Smtp')
                        {
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
                        }
                    }

            }       # END validate [SMTP] To

            17 {    # BEGIN validate [SMTP] From

                    if ([System.String]::IsNullOrEmpty($IniConfig.Alert.Method) -eq $false)
                    {
                        if ($IniConfig.Alert.Method -imatch 'Smtp')
                        {
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
                        }
                    }

            }       # END validate [SMTP] From

            18 {    # BEGIN validate [SMTP] Subject

                    if ([System.String]::IsNullOrEmpty($IniConfig.Alert.Method) -eq $false)
                    {
                        if ($IniConfig.Alert.Method -imatch 'Smtp')
                        {
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
                        }
                    }

            }       # END validate [SMTP] Subject

            19 {    # BEGIN validate [SMTP] Port

                    if ([System.String]::IsNullOrEmpty($IniConfig.Alert.Method) -eq $false)
                    {
                        if ($IniConfig.Alert.Method -imatch 'Smtp')
                        {
                            if ([System.String]::IsNullOrEmpty($IniConfig.Smtp.Port) -eq $false)
                            {
                                [int] $intPort = 0

                                if ([System.Int32]::TryParse($IniConfig.Smtp.Port, [ref]$intPort))
                                {
                                    if ($intPort -gt 0)
                                    {
                                        [int] $IniConfig.Smtp.Port = $intPort

                                    } else {

                                        $returnValue.ErrorMessages += '[Error][Config][SMTP] PORT must be a positive number.'
                                    }

                                } else {

                                    $returnValue.ErrorMessages += '[Error][Config][SMTP] PORT must be a positive number.'
                                }

                            } else {

                                $returnValue.ErrorMessages += '[Error][Config][SMTP] PORT not specified.'
                            }
                        }
                    }

            }       # END validate [SMTP] Port

            20 {    # BEGIN validate [SMTP] Server

                    if ([System.String]::IsNullOrEmpty($IniConfig.Alert.Method) -eq $false)
                    {
                        if ($IniConfig.Alert.Method -imatch 'Smtp')
                        {
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

                                    $returnValue.ErrorMessages += '[Error][Config][SMTP] TCP connection failed to {0}:{1}' -f $IniConfig.Smtp.Server,$IniConfig.Smtp.Port
                                }

                            } else {

                                $returnValue.ErrorMessages += '[Error][Config][SMTP] SERVER not specified.'
                            }
                        }
                    }

            }       # END validate [SMTP] Server

            21 {    # BEGIN validate [SMTP] CredentialXml

                    if ([System.String]::IsNullOrEmpty($IniConfig.Alert.Method) -eq $false)
                    {
                        if ($IniConfig.Alert.Method -imatch 'Smtp')
                        {
                            if ([System.String]::IsNullOrEmpty($IniConfig.Smtp.CredentialXml) -eq $false)
                            {
                                try {

	                                $credFile = Get-Item -LiteralPath $IniConfig.Smtp.CredentialXml -ErrorAction Stop

	                                $credCheck = Import-Clixml -LiteralPath $credFile.FullName

                                    if ($credCheck.GetType().Name -ne 'PSCredential')
                                    {
		                                $returnValue.ErrorMessages += '[Error][Config][SMTP] CredentialXml import failed.'
	                                }

	                                Remove-Variable -Name credCheck,credFile

                                } catch {

                                    $returnValue.ErrorMessages += '[Error][Config][SMTP] CredentialXml import failed.'
                                }
                            }
                        }
                    }

            }       # END validate [SMTP] CredentialXml

            22 {    # BEGIN validate [WinEvent] Logname

                    if ([System.String]::IsNullOrEmpty($IniConfig.Alert.Method) -eq $false)
                    {
                        if ($IniConfig.Alert.Method -imatch 'WinEvent')
                        {
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
                        }
                    }

            }       # END validate [WinEvent] Logname

            23 {    # BEGIN validate [WinEvent] Source

                    if ([System.String]::IsNullOrEmpty($IniConfig.Alert.Method) -eq $false)
                    {
                        if ($IniConfig.Alert.Method -imatch 'WinEvent')
                        {
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
                        }
                    }

            }       # END validate [WinEvent] Source

            24 {    # BEGIN validate [WinEvent] EntryType

                    if ([System.String]::IsNullOrEmpty($IniConfig.Alert.Method) -eq $false)
                    {
                        if ($IniConfig.Alert.Method -imatch 'WinEvent')
                        {
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
                        }
                    }

            }       # END validate [WinEvent] EntryType

            25 {    # BEGIN validate [WinEvent] FailedLoginsPerIPEventId

                    if ([System.String]::IsNullOrEmpty($IniConfig.Alert.Method) -eq $false)
                    {
                        if ($IniConfig.Alert.Method -imatch 'WinEvent')
                        {
                            if ([System.String]::IsNullOrEmpty($IniConfig.WinEvent.FailedLoginsPerIPEventId) -eq $false)
                            {
                                [int] $intFailedLoginsPerIPEventId = 0

                                if ([System.Int32]::TryParse($IniConfig.WinEvent.FailedLoginsPerIPEventId, [ref]$intFailedLoginsPerIPEventId))
                                {
                                    if ($intFailedLoginsPerIPEventId -gt 0)
                                    {
                                        if ($intFailedLoginsPerIPEventId -eq 100 -or $intFailedLoginsPerIPEventId -eq 200)
                                        {
                                            $returnValue.ErrorMessages += $('[Error][Config][WinEvent] FailedLoginsPerIPEventId can not be {0}.' -f $intFailedLoginsPerIPEventId)

                                        } else {

                                            [int] $IniConfig.WinEvent.FailedLoginsPerIPEventId = $intFailedLoginsPerIPEventId
                                        }

                                    } else {

                                        $returnValue.ErrorMessages += '[Error][Config][WinEvent] FailedLoginsPerIPEventId must be a positive number.'
                                    }

                                } else {

                                    $returnValue.ErrorMessages += '[Error][Config][WinEvent] FailedLoginsPerIPEventId must be a positive number.'
                                }

                            } else {

                                $returnValue.ErrorMessages += '[Error][Config][WinEvent] FailedLoginsPerIPEventId not specified.'
                            }
                        }
                    }

            }       # END validate [WinEvent] FailedLoginsPerIPEventId

            26 {    # BEGIN validate [WinEvent] TotalFailedLoginsEventId

                    if ([System.String]::IsNullOrEmpty($IniConfig.Alert.Method) -eq $false)
                    {
                        if ($IniConfig.Alert.Method -imatch 'WinEvent')
                        {
                            if ([System.String]::IsNullOrEmpty($IniConfig.WinEvent.TotalFailedLoginsEventId) -eq $false)
                            {
                                [int] $intTotalFailedLoginsEventId = 0

                                if ([System.Int32]::TryParse($IniConfig.WinEvent.TotalFailedLoginsEventId, [ref]$intTotalFailedLoginsEventId))
                                {
                                    if ($intTotalFailedLoginsEventId -gt 0)
                                    {
                                        if ($intTotalFailedLoginsEventId -eq 100 -or $intTotalFailedLoginsEventId -eq 200)
                                        {
                                            $returnValue.ErrorMessages += $('[Error][Config][WinEvent] TotalFailedLoginsEventId can not be {0}.' -f $intTotalFailedLoginsEventId)

                                        } else {

                                            [int] $IniConfig.WinEvent.TotalFailedLoginsEventId = $intTotalFailedLoginsEventId
                                        }

                                    } else {

                                        $returnValue.ErrorMessages += '[Error][Config][WinEvent] TotalFailedLoginsEventId must be a positive number.'
                                    }

                                } else {

                                    $returnValue.ErrorMessages += '[Error][Config][WinEvent] TotalFailedLoginsEventId must be a positive number.'
                                }

                            } else {

                                $returnValue.ErrorMessages += '[Error][Config][WinEvent] TotalFailedLoginsEventId not specified.'
                            }
                        }
                    }

            }       # END validate [WinEvent] TotalFailedLoginsEventId

            27 {    # BEGIN validate [WinEvent] Unique TotalFailedLoginsEventId & FailedLoginsPerIPEventId

                    if ([System.String]::IsNullOrEmpty($IniConfig.Alert.Method) -eq $false)
                    {
                        if ($IniConfig.Alert.Method -imatch 'WinEvent')
                        {
                            if ($IniConfig.WinEvent.TotalFailedLoginsEventId -eq $IniConfig.WinEvent.FailedLoginsPerIPEventId)
                            {
                                $returnValue.ErrorMessages += '[Error][Config][WinEvent] TotalFailedLoginsEventId and FailedLoginsPerIPEventId must be different.'
                            }
                        }
                    }

            }       # END validate [WinEvent] Unique TotalFailedLoginsEventId & FailedLoginsPerIPEventId

            28 {    # BEGIN validate IIS Log Access & verify logging field

                    $lpQuery = "`"SELECT TOP 1 * FROM '$($IniConfig.Logparser.LogPath)' WHERE s-sitename LIKE '$($IniConfig.Website.Sitename)' ORDER BY date, time DESC`""

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
                        $iisLogFields = @( "'date'","'time'","'c-ip'","'s-sitename'","'cs-method'","'cs-uri-stem'","'sc-status'" )

                        $iisLogFieldError = $false

                        foreach ($logField in $iisLogFields)
                        {
                            if ([System.String]::IsNullOrEmpty($($lpOutputCsv.$($logField))) -eq $true)
                            {
                                $iisLogFieldError = $true
                                $returnValue.ErrorMessages += "[Error][Config][Script] IIS log field $logField not being logged."
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

            }       # END validate IIS Log Access & verify logging field

            29 {    # BEGIN validate [WinEvent] Write Start

                    if ([System.String]::IsNullOrEmpty($IniConfig.Alert.Method) -eq $false)
                    {
                        if ($IniConfig.Alert.Method -imatch 'WinEvent')
                        {
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
                        }
                    }

            }       # END validate [WinEvent] Write Start

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
