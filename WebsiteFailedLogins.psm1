# initialize global variable for ini config
$Global:Ini = @{}

# initialize global variable for README
[string]$Global:WFLReadme = ""

# initialize global variable for DefaultConfig INI
[string]$Global:WFLDefaultConfig = ""

# initialize global variable for Standard Out Results
[string[]]$Global:WFLResults = @()

# require TLS1.2 for all communications
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Function Get-LogparserQuery
{
    <#
    .SYNOPSIS

    Returns a Log parser query based on values from the configuration file.

    .OUTPUTS

    System.String

    #>

    [CmdletBinding()]
    [OutputType('System.String')]
    param(

        [switch]
        # By default, returns query for Client IP (c-ip) failed logins. This switch is used to get the total failed login count query.
        $TotalFailedLogins,

        [switch]
        # Includes cs-uri-stem=UrlPath and cs-method=POST
        $FormsAuth
    )

    # Begin query build
    [string]$ReturnQuery = '"SELECT '

    if($TotalFailedLogins){

        $ReturnQuery += 'COUNT(*) AS Hits '

    } else {

        $ReturnQuery += 'c-ip AS ClientIP, COUNT(*) AS Hits '
    }

    $ReturnQuery += "FROM `'{0}`' " -f $Global:Ini.Website.LogPath
    $ReturnQuery += "WHERE s-sitename LIKE `'{0}`' " -f $Global:Ini.Website.Sitename
    $ReturnQuery += "AND TO_LOCALTIME(TO_TIMESTAMP(date,time)) >= TO_TIMESTAMP(`'{0}`',`'yyyy-MM-dd HH:mm:ss`') " -f $Global:Ini.Website.StartTimeTS
	$ReturnQuery += 'AND sc-status = {0} ' -f $Global:Ini.Website.HttpResponse

    if($FormsAuth){

        $ReturnQuery += "AND cs-uri-stem LIKE `'{0}`' AND cs-Method LIKE `'POST`' " -f $Global:Ini.Website.UrlPath
    }

    if($TotalFailedLogins -eq $false){

        $ReturnQuery += 'GROUP BY ClientIP HAVING Hits >= {0} ORDER BY Hits DESC"' -f $Global:Ini.Website.FailedLoginsPerIP
    } 

    if($ReturnQuery.TrimEnd().EndsWith('"') -eq $false){

        $ReturnQuery = $ReturnQuery.TrimEnd() + '"'
    }

    return $ReturnQuery

} # End Function Get-LogparserQuery

Function Confirm-IniConfig
{
    <#
    .SYNOPSIS

    Validates settings in the configuration file.

    .OUTPUTS

    System.Boolean
    #>

    [CmdletBinding()]
    [OutputType('System.Boolean')]
    param(
            [parameter(Mandatory=$false)]
            [ValidateScript({Test-Path -LiteralPath $_})]
            [string]
            # Path to configuration file.
            $Path
            ,
            [parameter(Mandatory=$false)]
            [switch]
            # Perform basic checks.
            $Brief
    )

    $i = 0

    [string[]]$ErrorMsg = @()

    [int[]]$MinimumChecks = 1,6,7,8,9,10,11,15,16,21,22,23,25

    do{

        $i++
        
        if($Brief){

            if($MinimumChecks.Contains($i) -eq $false){

                do {

                    $i++

                } until($MinimumChecks.Contains($i) -eq $true -or $i -gt $MinimumChecks[-1])
            }
        }

        if($ErrorMsg.Length -gt 0){

            $i = 1000
        }

        switch($i)
        {
            1 {     # BEGIN validate [INI]

                    if([System.String]::IsNullOrEmpty($Path) -eq $false){

                        $Global:Ini = Get-IniConfig -FilePath $Path
                    }

                    if($Global:Ini.Count -eq 0){

                        $ErrorMsg += '[Error] No configuration file.'

                        $i = 1000
                    }

            }       # END validate [INI]

            2 {     # BEGIN validate [Website] Sitename

                    if([System.String]::IsNullOrEmpty($Global:Ini.Website.Sitename) -eq $false){

                        if($Global:Ini.Website.Sitename -notmatch "^(?i)(w3svc)[0-9]{1,6}$"){

                            $ErrorMsg += '[Error][Website] Sitename not valid.'
                        }

                    } else {

                        $ErrorMsg += '[Error][Website] Sitename not specified.'
                    }

            }       # END validate [Website] Sitename

            3 {     # BEGIN validate [Website] Authentication

                    if([System.String]::IsNullOrEmpty($Global:Ini.Website.Authentication) -eq $false){

                        if($Global:Ini.Website.Authentication -notmatch "^(?i)(Forms|Basic|Windows)$"){

                            $ErrorMsg += '[Error][Website] Authentication not valid.'
                        }

                    } else {

                        $ErrorMsg += '[Error][Website] Authentication not specified.'
                    }

            }       # END validate [Website] Authentication

            4 {     # BEGIN validate [Website] HttpResponse

                    if([System.String]::IsNullOrEmpty($Global:Ini.Website.HttpResponse) -eq $false){

                        if($Global:Ini.Website.HttpResponse -notmatch "^[0-9]{3}$"){

                            $ErrorMsg += '[Error][Website] HttpResponse not valid.'
                        }

                    } else {

                        $ErrorMsg += '[Error][Website] HttpResponse not specified.'
                    }

            }       # END validate [Website] HttpResponse

            5 {     # BEGIN validate [Website] UrlPath

					if($Global:Ini.Website.Authentication -match "^(?i)(Forms)$"){

						if([System.String]::IsNullOrEmpty($Global:Ini.Website.UrlPath) -eq $false){

							try{

								$URI = [System.Uri]$('https://www.domain.com{0}' -f $Global:Ini.Website.UrlPath)

							} catch {

								$ErrorMsg += '[Error][Website] UrlPath not valid.'
							}

						} else {

							$ErrorMsg += '[Error][Website] UrlPath not specified.'
						}
					}

            }       # END validate [Website] UrlPath

            6 {     # BEGIN validate [Website] LogPath

                    if([System.String]::IsNullOrEmpty($Global:Ini.Website.LogPath) -eq $false){

                        try {

                            $LogPathRef = Get-Item -LiteralPath $Global:Ini.Website.LogPath -ErrorAction Stop

                            if($LogPathRef.PSIsContainer){

                                if($LogPathRef.FullName.EndsWith('\')){

                                    $Global:Ini.Website.LogPath = '{0}*' -f $LogPathRef.FullName
                                
                                } else {

                                    $Global:Ini.Website.LogPath = '{0}\*' -f $LogPathRef.FullName
                                }

                            } else {

                                $Global:Ini.Website.LogPath = $LogPathRef.FullName
                            }

                        } catch {

                            $ErrorMsg += '[Error][Website] LogPath not valid.'
                        }

                    } else {

                        $ErrorMsg += '[Error][Website] LogPath not specified.'
                    }

            }       # END validate [Website] LogPath

            7 {     # BEGIN validate [Website] FailedLoginsPerIP

                    if([System.String]::IsNullOrEmpty($Global:Ini.Website.FailedLoginsPerIP) -eq $false){

                        [int]$intPerIP = 0

                        if([System.Int32]::TryParse($Global:Ini.Website.FailedLoginsPerIP, [ref]$intPerIP)){

                            if($intPerIP -gt 0){

                                [int]$Global:Ini.Website.FailedLoginsPerIP = $intPerIP

                            } else {

                                $ErrorMsg += '[Error][Website] FailedLoginsPerIP must be a positive number.'
                            }
                        
                        } else {

                            $ErrorMsg += '[Error][Website] FailedLoginsPerIP must be a positive number.'
                        }

                    } else {

                        $ErrorMsg += '[Error][Website] FailedLoginsPerIP not specified.'
                    }

            }       # END validate [Website] FailedLoginsPerIP

            8 {     # BEGIN validate [Website] TotalFailedLogins

                    if([System.String]::IsNullOrEmpty($Global:Ini.Website.TotalFailedLogins) -eq $false){

                        [int]$intTotal = 0

                        if([System.Int32]::TryParse($Global:Ini.Website.TotalFailedLogins, [ref]$intTotal)){

                            if($intTotal -gt 0){

                                [int]$Global:Ini.Website.TotalFailedLogins = $intTotal

                            } else {

                                $ErrorMsg += '[Error][Website] TotalFailedLogins must be a positive number.'
                            }
                        
                        } else {

                            $ErrorMsg += '[Error][Website] TotalFailedLogins must be a positive number.'
                        }

                    } else {

                        $ErrorMsg += '[Error][Website] TotalFailedLogins not specified.'
                    }

            }       # END validate [Website] TotalFailedLogins

            9 {     # BEGIN validate [Website] StartTime

                    if([System.String]::IsNullOrEmpty($Global:Ini.Website.StartTime) -eq $false){

                        [int]$intSeconds = 0

                        if([System.Int32]::TryParse($Global:Ini.Website.StartTime, [ref]$intSeconds)){

                            if($intSeconds -gt 0){

                                [int]$Global:Ini.Website.StartTime = $intSeconds

                                $Global:Ini.Website.StartTimeTS = (Get-Date).AddSeconds($intSeconds * -1).ToString('yyyy-MM-dd HH:mm:ss')

                            } else {

                                $ErrorMsg += '[Error][Website] StartTime must be a positive number.'
                            }
                        
                        } else {

                            $ErrorMsg += '[Error][Website] StartTime must be a positive number.'
                        }

                    } else {

                        $ErrorMsg += '[Error][Website] StartTime not specified.'
                    }

            }       # END validate [Website] StartTime

            10 {     # BEGIN validate [Logparser] Path

                    if([System.String]::IsNullOrEmpty($Global:Ini.Logparser.Path) -eq $false){

                        if(Test-Path -LiteralPath $Global:Ini.Logparser.Path){

                            $lp = Get-Item -LiteralPath $Global:Ini.Logparser.Path

                            if($lp.PSIsContainer){

                                $Global:Ini.Logparser.Path = Join-Path -Path $Global:Ini.Logparser.Path -ChildPath 'LogParser.exe'
                            }

                            try{

                                $lpExe = Get-Item -LiteralPath $Global:Ini.Logparser.Path -ErrorAction Stop

                                if($lpExe.VersionInfo.FileVersion -ne '2.2.10.0'){

                                    $ErrorMsg += $('[Error][Logparser] Current Microsoft (R) Log Parser Version {0}' -f $lpExe.VersionInfo.FileVersion)

                                    $ErrorMsg += '[Error][Logparser] Must be Microsoft (R) Log Parser Version 2.2.10'
                                }

                            } catch {
                                
                                $e = $_

                                $ErrorMsg += $('[Error][Logparser] {0}' -f $e.Exception.Message)
                            }

                            # test launch of logparser
                            try{
                                
                                $lpQuery = "`"SELECT FileVersion FROM `'$($Global:Ini.Logparser.Path)`'`""

                                [string]$lpFileVersion = & $Global:Ini.Logparser.Path -e:-1 -iw:ON -headers:OFF -q:ON -i:FS -o:CSV $lpQuery

                                if($null -ne $lpFileVersion){

                                    if([System.String]::IsNullOrEmpty($lpFileVersion) -eq $false){
                                        
                                        if($lpFileVersion.Trim() -eq 'Task aborted.'){

                                            $ErrorMsg += '[Error][Logparser] Error testing launch of Logparser.exe'

                                        } elseif($lpFileVersion.Trim().StartsWith('2.2.10') -eq $false){

                                            $ErrorMsg += $('[Error][Logparser] Current Microsoft (R) Log Parser Version {0}' -f $lpFileVersion)

                                            $ErrorMsg += '[Error][Logparser] Must be Microsoft (R) Log Parser Version 2.2.10'
                                        }

                                    } else {

                                        $ErrorMsg += '[Error][Logparser] Error testing launch of Logparser.exe'
                                    }
                                
                                } else {

                                    $ErrorMsg += '[Error][Logparser] Error testing launch of Logparser.exe'
                                }

                            } catch {

                                $e = $_

                                $ErrorMsg += '[Error][Logparser] Error testing launch of Logparser.exe'

                                $ErrorMsg += $('[Error][Logparser] {0}' -f $e.Exception.Message)
                            }

                        } else {

                            $ErrorMsg += '[Error][Logparser] Path not valid.'
                        }

                    } else {

                        $ErrorMsg += '[Error][Logparser] Path not specified.'
                    }

            }       # END validate [Logparser] Path

            11 {    # BEGIN validate [Alert] Method

                    if([System.String]::IsNullOrEmpty($Global:Ini.Alert.Method) -eq $false){

                        if($Global:Ini.Alert.Method -notmatch "^(?i)Smtp|WinEvent|stdout$"){

                            $ErrorMsg += '[Error][Alert] Method not valid.'
                        }

                    } else {

                        $Global:Ini.Alert.Method = 'stdout'
                    }

            }       # END validate [Alert] Method

            12 {    # BEGIN validate [SMTP] To

                    if([System.String]::IsNullOrEmpty($Global:Ini.Alert.Method) -eq $false){

                        if($Global:Ini.Alert.Method -match "^(?i)(.*)Smtp(.*)$"){

                            if([System.String]::IsNullOrEmpty($Global:Ini.Smtp.To) -eq $false){

                                try {

                                    $smtpTo = [System.Net.Mail.MailAddress]::New($Global:Ini.Smtp.To)

                                } catch {

                                    $ErrorMsg += '[Error][SMTP] TO not valid.'
                                }

                            } else {

                                $ErrorMsg += '[Error][SMTP] TO not specified.'
                            }
                        }
                    }

            }       # END validate [SMTP] To

            13 {    # BEGIN validate [SMTP] From

                    if([System.String]::IsNullOrEmpty($Global:Ini.Alert.Method) -eq $false){

                        if($Global:Ini.Alert.Method -match "^(?i)(.*)Smtp(.*)$"){

                            if([System.String]::IsNullOrEmpty($Global:Ini.Smtp.From) -eq $false){

                                try {

                                    $smtpFrom = [System.Net.Mail.MailAddress]::new($Global:Ini.Smtp.From)

                                } catch {

                                    $ErrorMsg += '[Error][SMTP] FROM not valid.'
                                }

                            } else {

                                $ErrorMsg += '[Error][SMTP] FROM not specified.'
                            }
                        }
                    }

            }       # END validate [SMTP] From

            14 {    # BEGIN validate [SMTP] Subject

                    if([System.String]::IsNullOrEmpty($Global:Ini.Alert.Method) -eq $false){

                        if($Global:Ini.Alert.Method -match "^(?i)(.*)Smtp(.*)$"){

                            if([System.String]::IsNullOrEmpty($Global:Ini.Smtp.Subject)){

                                $ErrorMsg += '[Error][SMTP] SUBJECT not specified.'
                            
                            } else {

                                try {

                                    $msg = [System.Net.Mail.MailMessage]::new()
                                
                                    $msg.Subject = $Global:Ini.Smtp.Subject
                                    
                                    $msg.Dispose()
                                    
                                    Remove-Variable -Name msg

                                } catch {

                                    $ErrorMsg += '[Error][SMTP] SUBJECT not valid.'
                                }
                            }
                        }
                    }

            }       # END validate [SMTP] Subject

            15 {    # BEGIN validate [SMTP] Port

                    if([System.String]::IsNullOrEmpty($Global:Ini.Alert.Method) -eq $false){

                        if($Global:Ini.Alert.Method -match "^(?i)(.*)Smtp(.*)$"){

                            if([System.String]::IsNullOrEmpty($Global:Ini.Smtp.Port) -eq $false){

                                [int]$intPort = 0

                                if([System.Int32]::TryParse($Global:Ini.Smtp.Port, [ref]$intPort)){

                                    if($intPort -gt 0){

                                        [int]$Global:Ini.Smtp.Port = $intPort

                                    } else {

                                        $ErrorMsg += '[Error][SMTP] PORT must be a positive number.'
                                    }
                        
                                } else {

                                    $ErrorMsg += '[Error][SMTP] PORT must be a positive number.'
                                }

                            } else {

                                $ErrorMsg += '[Error][SMTP] PORT not specified.'
                            }
                        }
                    }

            }       # END validate [SMTP] Port

            16 {    # BEGIN validate [SMTP] Server

                    if([System.String]::IsNullOrEmpty($Global:Ini.Alert.Method) -eq $false){

                        if($Global:Ini.Alert.Method -match "^(?i)(.*)Smtp(.*)$"){

                            if([System.String]::IsNullOrEmpty($Global:Ini.Smtp.Server) -eq $false){

                                try {

                                    $smtpServer = New-Object System.Net.Sockets.TcpClient($Global:Ini.Smtp.Server, $Global:Ini.Smtp.Port)

                                    if($smtpServer.Connected -eq $false){

                                        $ErrorMsg += '[Error][SMTP] TCP connection failed to {0}:{1}' -f $Global:Ini.Smtp.Server,$Global:Ini.Smtp.Port
                                    }

                                    $smtpServer.Dispose()

                                    Remove-Variable -Name smtpServer

                                } catch {

                                    $ErrorMsg += '[Error][SMTP] TCP connection failed to {0}:{1}' -f $Global:Ini.Smtp.Server,$Global:Ini.Smtp.Port
                                }

                            } else {

                                $ErrorMsg += '[Error][SMTP] SERVER not specified.'
                            }
                        }
                    }

            }       # END validate [SMTP] Server

            17 {    # BEGIN validate [SMTP] CredentialXml

                    if([System.String]::IsNullOrEmpty($Global:Ini.Alert.Method) -eq $false){

                        if($Global:Ini.Alert.Method -match "^(?i)(.*)Smtp(.*)$"){

                            if([System.String]::IsNullOrEmpty($Global:Ini.Smtp.CredentialXml) -eq $false){

                                try {

	                                $credFile = Get-Item -LiteralPath $Global:Ini.Smtp.CredentialXml -ErrorAction Stop

	                                $credCheck = Import-Clixml -LiteralPath $credFile.FullName

	                                if($credCheck.GetType().Name -ne 'PSCredential'){

		                                $ErrorMsg += '[Error][SMTP] CredentialXml import failed.'
	                                }

	                                Remove-Variable -Name credCheck,credFile

                                } catch {

                                    $ErrorMsg += '[Error][SMTP] CredentialXml import failed.'
                                }
                            }
                        }
                    }

            }       # END validate [SMTP] CredentialXml

            18 {    # BEGIN validate [WinEvent] Logname

                    if([System.String]::IsNullOrEmpty($Global:Ini.Alert.Method) -eq $false){

                        if($Global:Ini.Alert.Method -match "^(?i)(.*)WinEvent(.*)$"){

                            if([System.String]::IsNullOrEmpty($Global:Ini.WinEvent.Logname) -eq $false){

                                try {

                                    Get-WinEvent -LogName $Global:Ini.WinEvent.Logname -MaxEvents 1 -ErrorAction Stop | Out-Null

                                } catch {

                                    $ErrorMsg += '[Error][WinEvent] no Logname {0}' -f $Global:Ini.WinEvent.Logname
                                }

                            } else {

                                $ErrorMsg += '[Error][WinEvent] Logname not specified.'
                            }
                        }
                    }

            }       # END validate [WinEvent] Logname

            19 {    # BEGIN validate [WinEvent] Source

                    if([System.String]::IsNullOrEmpty($Global:Ini.Alert.Method) -eq $false){

                        if($Global:Ini.Alert.Method -match "^(?i)(.*)WinEvent(.*)$"){

                            if([System.String]::IsNullOrEmpty($Global:Ini.WinEvent.Source) -eq $false){

                                try{

                                    $result = [System.Diagnostics.EventLog]::SourceExists($Global:Ini.WinEvent.Source)

                                    if ($result -eq $false){

                                        $ErrorMsg += '[Error][WinEvent] Source does not exist.'
                                    }
                                
                                } catch {

                                    $e = $_

                                    $ErrorMsg += '[Error][WinEvent] Source does not exist.'

                                    $ErrorMsg += '[Error][WinEvent] Source check exception: {0}' -f $e.Exception.Message
                                }

                            } else {

                                $ErrorMsg += '[Error][WinEvent] Source not specified.'
                            }
                        }
                    }

            }       # END validate [WinEvent] Source

            20 {    # BEGIN validate [WinEvent] EntryType

                    if([System.String]::IsNullOrEmpty($Global:Ini.Alert.Method) -eq $false){

                        if($Global:Ini.Alert.Method -match "^(?i)(.*)WinEvent(.*)$"){

                            if([System.String]::IsNullOrEmpty($Global:Ini.WinEvent.EntryType) -eq $false){

                                if($Global:Ini.WinEvent.EntryType -notmatch "^(?i)(Error|FailureAudit|Information|SuccessAudit|Warning)$"){

                                    $ErrorMsg += '[Error][WinEvent] EntryType not valid.'
                                }

                            } else {

                                $ErrorMsg += '[Error][WinEvent] EntryType not specified.'
                            }
                        }
                    }

            }       # END validate [WinEvent] EntryType

            21 {    # BEGIN validate [WinEvent] FailedLoginsPerIPEventId

                    if([System.String]::IsNullOrEmpty($Global:Ini.Alert.Method) -eq $false){

                        if($Global:Ini.Alert.Method -match "^(?i)(.*)WinEvent(.*)$"){

                            if([System.String]::IsNullOrEmpty($Global:Ini.WinEvent.FailedLoginsPerIPEventId) -eq $false){

                                [int]$intFailedLoginsPerIPEventId = 0

                                if([System.Int32]::TryParse($Global:Ini.WinEvent.FailedLoginsPerIPEventId, [ref]$intFailedLoginsPerIPEventId)){

                                    if($intFailedLoginsPerIPEventId -gt 0){

                                        if($intFailedLoginsPerIPEventId -eq 100 -or $intFailedLoginsPerIPEventId -eq 200){

                                            $ErrorMsg += $('[Error][WinEvent] FailedLoginsPerIPEventId can not be {0}.' -f $intFailedLoginsPerIPEventId)

                                        } else {

                                            [int]$Global:Ini.WinEvent.FailedLoginsPerIPEventId = $intFailedLoginsPerIPEventId
                                        }

                                    } else {

                                        $ErrorMsg += '[Error][WinEvent] FailedLoginsPerIPEventId must be a positive number.'
                                    }
                        
                                } else {

                                    $ErrorMsg += '[Error][WinEvent] FailedLoginsPerIPEventId must be a positive number.'
                                }

                            } else {

                                $ErrorMsg += '[Error][WinEvent] FailedLoginsPerIPEventId not specified.'
                            }
                        }
                    }

            }       # END validate [WinEvent] FailedLoginsPerIPEventId

            22 {    # BEGIN validate [WinEvent] TotalFailedLoginsEventId

                    if([System.String]::IsNullOrEmpty($Global:Ini.Alert.Method) -eq $false){

                        if($Global:Ini.Alert.Method -match "^(?i)(.*)WinEvent(.*)$"){

                            if([System.String]::IsNullOrEmpty($Global:Ini.WinEvent.TotalFailedLoginsEventId) -eq $false){

                                [int]$intTotalFailedLoginsEventId = 0

                                if([System.Int32]::TryParse($Global:Ini.WinEvent.TotalFailedLoginsEventId, [ref]$intTotalFailedLoginsEventId)){

                                    if($intTotalFailedLoginsEventId -gt 0){

                                        if($intTotalFailedLoginsEventId -eq 100 -or $intTotalFailedLoginsEventId -eq 200){

                                            $ErrorMsg += $('[Error][WinEvent] TotalFailedLoginsEventId can not be {0}.' -f $intTotalFailedLoginsEventId)

                                        } else {

                                            [int]$Global:Ini.WinEvent.TotalFailedLoginsEventId = $intTotalFailedLoginsEventId
                                        }

                                    } else {

                                        $ErrorMsg += '[Error][WinEvent] TotalFailedLoginsEventId must be a positive number.'
                                    }
                        
                                } else {

                                    $ErrorMsg += '[Error][WinEvent] TotalFailedLoginsEventId must be a positive number.'
                                }

                            } else {

                                $ErrorMsg += '[Error][WinEvent] TotalFailedLoginsEventId not specified.'
                            }
                        }
                    }

            }       # END validate [WinEvent] TotalFailedLoginsEventId

            23 {    # BEGIN validate [WinEvent] Unique TotalFailedLoginsEventId & FailedLoginsPerIPEventId

                    if([System.String]::IsNullOrEmpty($Global:Ini.Alert.Method) -eq $false){

                        if($Global:Ini.Alert.Method -match "^(?i)(.*)WinEvent(.*)$"){

                            if($Global:Ini.WinEvent.TotalFailedLoginsEventId -eq $Global:Ini.WinEvent.FailedLoginsPerIPEventId){

                                $ErrorMsg += '[Error][WinEvent] TotalFailedLoginsEventId and FailedLoginsPerIPEventId must be different.'
                            }
                        }
                    }

            }       # END validate [WinEvent] Unique TotalFailedLoginsEventId & FailedLoginsPerIPEventId

            24 {    # BEGIN validate IIS Log Access

                    $lpQuery = "SELECT TOP 1 * FROM `'$($Global:Ini.Website.LogPath)`' WHERE s-sitename LIKE `'$($Global:Ini.Website.Sitename)`'"

                    try{
                                
                        $lpOutput = & $Global:Ini.Logparser.Path -iw:ON -q:ON -i:IISW3C -o:CSV $lpQuery | ConvertFrom-Csv

                        if($null -ne $lpOutput){

                            if([System.String]::IsNullOrEmpty($lpOutput.'s-sitename') -eq $false){`
                                        
                                if($lpOutput.'s-sitename' -ne $Global:Ini.Website.Sitename){

                                    $ErrorMsg += $('[Error][Script] Failed to return log entry for sitename {0} using Logparser.exe and path {1}' -f $Global:Ini.Website.Sitename.ToUpper(),$Global:Ini.Website.LogPath)
                                }

                            } else {

                                $ErrorMsg += $('[Error][Script] Failed to return log entry for sitename {0} using Logparser.exe and path {1}' -f $Global:Ini.Website.Sitename.ToUpper(),$Global:Ini.Website.LogPath)
                            }
                                
                        } else {

                            $ErrorMsg += $('[Error][Script] Failed to return log entry for sitename {0} using Logparser.exe and path {1}' -f $Global:Ini.Website.Sitename.ToUpper(),$Global:Ini.Website.LogPath)
                        }

                    } catch {

                        $e = $_

                        $ErrorMsg += $('[Error][Script] Failed to return log entry for sitename {0} using Logparser.exe and path {1}' -f $Global:Ini.Website.Sitename.ToUpper(),$Global:Ini.Website.LogPath)

                        $ErrorMsg += $('[Error][Script] {0}' -f $e.Exception.Message)
                    }

            }       # END validate IIS Log Access

            25 {    # BEGIN validate [WinEvent] Write Start

                    if([System.String]::IsNullOrEmpty($Global:Ini.Alert.Method) -eq $false){

                        if($Global:Ini.Alert.Method -match "^(?i)(.*)WinEvent(.*)$"){

                            [string[]]$EventMessage = 'Status = Started'

                            $EventMessage += Get-LoadedConfig

                            try {

                                Write-EventLog -LogName $Global:Ini.WinEvent.Logname `
                                               -Source $Global:Ini.WinEvent.Source `
                                               -EntryType Information `
                                               -EventId 100 `
                                               -ErrorAction Stop `
                                               -Message $($EventMessage -Join [System.Environment]::NewLine)

                            } catch {

                                $ErrorMsg += '[Error][Script] Event log write failed.'
                            }
                        }
                    }

            }       # END validate [WinEvent] Write Start

            default {

                if($ErrorMsg.Length -gt 0){

                    $Global:Ini['Script'].Add('HasError',$true)

                    $ErrorMsg = @('[Error][Script] Terminating error.') + $ErrorMsg

                    $Global:Ini['Script'].Add('ErrorMsg',$ErrorMsg)

                } else {

                    $Global:Ini['Script'].Add('HasError',$false)

                }

                $i = 0
            }
        }

    } while($i -gt 0)


    return $Global:Ini.Script.HasError

} # End Function Confirm-IniConfig

Function Get-IniConfig
{
    <#
    .SYNOPSIS

    Parses the configuration file into a hashtable.

    .INPUTS

    System.String

    .OUTPUTS

    System.Collections.Hashtable

    .LINK

    https://blogs.technet.microsoft.com/heyscriptingguy/2011/08/20/use-powershell-to-work-with-any-ini-file/
    #>

    [CmdletBinding()]
    [OutputType('System.Collections.Hashtable')]
    param(
            [parameter(Mandatory=$true)]
            [ValidateScript({Test-Path $_})]
            [string]
            # Path to configuration file.
            $Path
    )

    $config = @{}

    switch -regex -file $Path
    {
        "^.*\[(.+)\].*$" # Section
        {
            $section = $matches[1]

            if($section.ToString().Trim().StartsWith('#') -eq $false){

                $config.Add($section.Trim(),@{})
            }
        }

        "(.+?)\s*=(.*)" # Key
        {
            $name,$value = $matches[1..2]

            if($name.ToString().Trim().StartsWith('#') -eq $false){

                $config[$section].Add($name.Trim(), $value.Trim())
            }
        }
    }

    if([System.String]::IsNullOrEmpty($config['Script'])){

        $config.Add('Script',@{})
    }

    $config['Script'].Add('ConfigPath',(Get-Item $Path).FullName)

    $config['Script'].Add('StartTS', (Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))

    return $config

} # End Function Get-IniConfig

Function Get-LoadedConfig
{
    <#
    .SYNOPSIS

    Gets the currently loaded configuration.

    .OUTPUTS

    System.String[]
    #>

    [CmdletBinding()]
    [OutputType('System.String[]')]
    param( )

    [string[]]$returnConfig = @()

    if($Global:Ini.Count -le 1){

        $returnConfig += '[Error] No configuration loaded.'

        return $returnConfig

    } else {

        $Sections = $Global:Ini.Keys | Sort-Object

        foreach($Section in $Sections){

            $returnConfig += '[{0}]' -f $Section.ToUpper()

            $Settings = $Global:Ini[$Section].Keys | Sort-Object

            foreach($Setting in $Settings){

                if($Setting -eq 'ErrorMsg'){

                    [string[]]$errorList = $Global:Ini[$Section][$Setting]

                    for($i=0; $i -lt $errorList.Length; $i++){

                        $returnConfig += '  ErrorMsg{0} = {1}' -f $($i + 1), $errorList[$i]
                    }

                } else {

                    $returnConfig += '  {0} = {1}' -f $Setting, $Global:Ini[$Section][$Setting]
                }
            }
        }
    }

    return $returnConfig

} # End Get-LoadedConfig

Function Invoke-WebsiteFailedLogins
{
    <#
    .SYNOPSIS

    Launches WebsiteFailedLogins.

	.DESCRIPTION

	Generates an alert for:
        
        - Each IP address meeting or exceeding the threshold FailedLoginsPerIP
        
        - When the total failed logins threshold (TotalFailedLogins) is met or exceeded

	Automate this by running it as a scheduled task. See README.md for details or run the following command:

        Get-WebsiteFailedLoginsREADME -SectionKeyword Scheduling

    .INPUTS

    System.String

    .OUTPUTS

    System.String[]

    #>

    [CmdletBinding()]
    [OutputType('System.String[]')]
    param(
            [parameter(Mandatory=$true)]
			[ValidateScript({Test-Path -LiteralPath $_})]
            [string]
            # Path to configuration file.
            $Configuration
            ,
            [parameter(Mandatory=$false)]
            [switch]
            # Performs the minimum number of validation checks against the configuration file. Use this switch after all configuration errors have been resolved.
            $MinimumValidation
    )

    [bool]$HasError = $false
    
    [string[]]$Global:WFLResults = @()

    $Global:Ini = Get-IniConfig -Path $Configuration
    
    if($MinimumValidation){

        $HasError = Confirm-IniConfig -Brief

    } else {
    
        $HasError = Confirm-IniConfig
    }
    
    if($HasError -eq $false){

        $Global:WFLResults += 'Status = Started'

        # Per IP Failed Logins
        $hashMsg = Get-FailedLoginsPerIP

        if($hashMsg.Count -gt 0){

            [string[]]$keys = $hashMsg.Keys | Sort-Object

            for($i=0; $i -lt $keys.Length; $i++){

				$key = $keys[$i]

                $Global:WFLResults += "# IP Entry $($i + 1) #"

				$hashMsg[$key] | foreach-Object{ $Global:WFLResults += '  {0}' -f $_ }

				Submit-Alert -Message $($hashMsg[$key]) -SubjectAppend $key
            }
        }

        # Total Failed Logins
        $arrMsg = Get-TotalFailedLogins

        if($arrMsg.Length -gt 0){

            $Global:WFLResults += '# Total Failed Logins #'
            
            $arrMsg | ForEach-Object{ $Global:WFLResults += '  {0}' -f $_ }

            Submit-Alert -Message $arrMsg -SubjectAppend 'TotalFailedLogins' -TotalFailedLogins
        }

        Write-Output $Global:WFLResults

    } else {

        [string[]]$Message = $Global:Ini.Script.ErrorMsg

        $Message += '# Loaded Configuration #'

        $Message += $(Get-LoadedConfig)

        Write-Output $Message

        Submit-Alert -Message $Message -TerminatingError
    }

    Write-Output 'Status = Finished'

} # End Function Invoke-WebsiteFailedLogins

Function Get-FailedLoginsPerIP
{
    <#
    .SYNOPSIS

    Gets each Client IP (c-ip) having generated failed logins >= FailedLoginsPerIP since StartTime.

    .INPUTS

    None

    .OUTPUTS

    System.Collections.Hashtable

    #>

    [CmdletBinding()]
    [OutputType('System.Collections.Hashtable')]
    param( )

    $ReturnHash = @{}

    $LogparserQuery = Get-LogparserQuery

    if($Global:Ini.Website.Authentication -match "^(?i)Forms$"){

        $LogparserQuery = Get-LogparserQuery -FormsAuth
    }

    $LogparserResults = & $Global:Ini.Logparser.Path -i:IISW3C -o:CSV -q:ON -stats:OFF $LogparserQuery

    $queryTimestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

    if($null -ne $LogparserResults){

        $ResultsObj = $LogparserResults | ConvertFrom-Csv

        foreach($item in $ResultsObj){

            [string[]]$EventMessage = @()

            $EventMessage += 'ClientIP = {0}' -f $item.ClientIP

            $EventMessage += 'FailedLogins = {0}' -f $item.Hits

            $EventMessage += 'Sitename = {0}' -f $Global:Ini.Website.Sitename

			$EventMessage += 'IISLogPath = {0}' -f $Global:Ini.Website.LogPath

			$EventMessage += 'Authentication = {0}' -f $Global:Ini.Website.Authentication

			$EventMessage += 'HttpResponse = {0}' -f $Global:Ini.Website.HttpResponse

			$EventMessage += 'UrlPath = {0}' -f $Global:Ini.Website.UrlPath

            $EventMessage += 'Start = {0}' -f $Global:Ini.Website.StartTimeTS

            $EventMessage += 'End ~ {0}' -f $queryTimestamp

            $ReturnHash.Add($item.ClientIP, $EventMessage)
        }
    }

    return $ReturnHash

} # End Function Get-FailedLoginsPerIP

Function Submit-Alert
{
    <#
    .SYNOPSIS

    Submits alert to Event Log or via SMTP.

    .OUTPUTS

    None

    #>

    [CmdletBinding()]
    param(
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

    if($Global:Ini.Alert.Method -match "^(?i)(.*)WinEvent(.*)$"){

        if($TerminatingError){

            Write-EventAlert -Message $Message -TerminatingError

        } elseif($TotalFailedLogins){

            Write-EventAlert -Message $Message -TotalFailedLogins

        } else {

            Write-EventAlert -Message $Message
        }
    }

    if($Global:Ini.Alert.Method -match "^(?i)(.*)Smtp(.*)$"){

        if($TerminatingError){

            Send-SmtpAlert -Message $Message -TerminatingError

        } else {

            $subject = $Global:Ini.Smtp.Subject

            if([System.String]::IsNullOrEmpty($SubjectAppend) -eq $false){

                $subject = '{0} {1}' -f $Global:Ini.Smtp.Subject,$SubjectAppend
            }
            
            Send-SmtpAlert -Message $Message -MessageSubject $subject
        }
    }

} # End Function Submit-Alert

Function Get-TotalFailedLogins
{
    <#
    .SYNOPSIS

    Gets the total failed login count if it meets or exceeds TotalFailedLogins threshold during the specified window.

    .INPUTS

    None

    .OUTPUTS

    System.String[]

    #>

    [CmdletBinding()]
    [OutputType('System.String[]')]
    param( )

    [string[]]$EventMessage = @()

    [int]$TotalHits = 0

    $LogparserQuery = Get-LogparserQuery -TotalFailedLogins

    if($Global:Ini.Website.Authentication -match "^(?i)Forms$"){

        $LogparserQuery = Get-LogparserQuery -TotalFailedLogins -FormsAuth
    }

    [string]$LogparserResult = & $Global:Ini.Logparser.Path -headers:OFF -i:IISW3C -o:CSV -q:ON -stats:OFF $LogparserQuery

    [string]$queryTimestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')

    if([System.String]::IsNullOrEmpty($LogparserResult) -eq $false){

        if([System.Int32]::TryParse($LogparserResult, [ref]$TotalHits)){

            if($TotalHits -ge $Global:Ini.Website.TotalFailedLogins){

                $EventMessage += 'TotalFailedLogins = {0}' -f $TotalHits

                $EventMessage += 'Sitename = {0}' -f $Global:Ini.Website.Sitename

			    $EventMessage += 'IISLogPath = {0}' -f $Global:Ini.Website.LogPath

			    $EventMessage += 'Authentication = {0}' -f $Global:Ini.Website.Authentication

			    $EventMessage += 'HttpResponse = {0}' -f $Global:Ini.Website.HttpResponse

			    $EventMessage += 'UrlPath = {0}' -f $Global:Ini.Website.UrlPath

                $EventMessage += 'Start = {0}' -f $Global:Ini.Website.StartTimeTS

                $EventMessage += 'End ~ {0}' -f $queryTimestamp
            }
        }
    }

    return $EventMessage

} # End Function Get-TotalFailedLogins

Function Write-EventAlert
{
    <#
    .SYNOPSIS

    Writes alert to windows event log.

    .OUTPUTS

    None

    #>

    [CmdletBinding()]
    param(
            [parameter(Mandatory=$true)]
            [System.String[]]
            # Message for alert.
            $Message
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

    $EventEntryType = $Global:Ini.WinEvent.EntryType

    $EventId = $Global:Ini.WinEvent.FailedLoginsPerIPEventId

    if($TotalFailedLogins){

        $EventId = $Global:Ini.WinEvent.TotalFailedLoginsEventId
    }

    if($TerminatingError){

        $EventEntryType = 'Error'

        $EventId = 200
    }

    try {

            Write-EventLog -LogName $Global:Ini.WinEvent.Logname `
                           -Source $Global:Ini.WinEvent.Source `
                           -EntryType $EventEntryType `
                           -EventId $EventId `
                           -Message $($Message -Join [System.Environment]::NewLine) `
                           -ErrorAction Stop

    } catch {
        
        $e = $_

        Write-Output $('[Error][Script] Alert Event log write failed. {0}' -f $e.Exception.Message)
    }


} # End Function Write-EventAlert

Function Send-SmtpAlert
{
    <#
    .SYNOPSIS

    Sends alert via SMTP.

    .OUTPUTS

    None

    #>

    [CmdletBinding()]
    param(
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

    $EmailSubject = $Global:Ini.Smtp.Subject

    if([System.String]::IsNullOrEmpty($EmailSubject) -eq $false){

        $EmailSubject = $MessageSubject
    }

    if($TerminatingError){

        $EmailSubject = '[TerminatingError] {0}' -f $EmailSubject
    }

    try {

        if([System.String]::IsNullOrEmpty($Global:Ini.Smtp.CredentialXml)){

            Send-MailMessage -To $Global:Ini.Smtp.To `
                             -From $Global:Ini.Smtp.From `
                             -Subject $EmailSubject `
                             -SmtpServer $Global:Ini.Smtp.Server `
                             -Port $Global:Ini.Smtp.Port `
                             -Body $($Message -Join [System.Environment]::NewLine) `
                             -UseSsl `
                             -ErrorAction Stop

        } else {

            $creds = Import-Clixml -LiteralPath $Global:Ini.Smtp.CredentialXml

            Send-MailMessage -To $Global:Ini.Smtp.To `
                             -From $Global:Ini.Smtp.From `
                             -Subject $EmailSubject `
                             -SmtpServer $Global:Ini.Smtp.Server `
                             -Port $Global:Ini.Smtp.Port `
                             -Body $($Message -Join [System.Environment]::NewLine) `
                             -Credential $creds `
                             -UseSsl `
                             -ErrorAction Stop

            Remove-Variable -Name creds
        }

    } catch {
        
        $e = $_

        Write-Output $('[Error][Script] Alert smtp send failed. {0}' -f $e.Exception.Message)
    }

} # End Function Send-SmtpAlert

Function Get-WebsiteFailedLoginsREADME
{
    <#
    .SYNOPSIS

    Gets the WebsiteFailedLogins README file.

    #>

    [CmdletBinding()]
    param( 
            [parameter(Mandatory=$false)]
            [System.String]
            # Section to return.
            $SectionKeyword
    )

	try {

		$ReadMeFile = Get-Item -LiteralPath $Global:WFLReadme -ErrorAction Stop

		$ReadMeContent = Get-Content -LiteralPath $ReadMeFile.FullName

        if([System.String]::IsNullOrEmpty($SectionKeyword)){

            $ReadMeContent | foreach-Object{ Write-Output $_ }

        } else {

            $PrintLine = $false

            $SectionKeywordLower = $SectionKeyword.ToLower().Trim()

            for($i=0; $i -lt $ReadMeContent.Length; $i++){

            $line = $ReadMeContent[$i]
                
                if($line.Trim().StartsWith('#')){

                    $PrintLine = $false
                }
                
                if([System.String]::IsNullOrEmpty($line) -eq $false){
                                
                    if($line.ToLower().Contains($SectionKeywordLower)){

                        if($PrintLine -eq $false){

                            Write-Output $ReadMeContent[$i - 1]
                        }
                        
                        $PrintLine = $true
                    }
                }

                if($PrintLine){

                    Write-Output $line
                }
            }
        }

	} catch {
	
		$e = $_

		Write-Output $('[ERROR][Script] {0}' -f $e.Exception.Message)
	}

} # End Function Get-WebsiteFailedLoginsReadme

Function Copy-WebsiteFailedLoginsREADME
{
    <#
    .SYNOPSIS

    Copy the WebsiteFailedLogins README file (README.md) to the destination folder.

    #>

    [CmdletBinding()]
    param( 
			[parameter(Mandatory=$true)]
            [ValidateScript({Test-Path -LiteralPath $_ -PathType Container})]
			[string]
            # Destination folder to copy README.md
            $DestinationFolder
	)

	try {

		$ReadMeFile = Get-Item -LiteralPath $Global:WFLReadme -ErrorAction Stop

		Copy-Item -Path $ReadMeFile.FullName -Destination $DestinationFolder

	} catch {
	
		$e = $_

		Write-Output $('[ERROR][Script] {0}' -f $e.Exception.Message)
	}

} # End Function Copy-WebsiteFailedLoginsReadme

Function Get-WebsiteFailedLoginsDefaultConfiguration
{
    <#
    .SYNOPSIS

    Gets the WebsiteFailedLogins default configuration file.

    #>

    [CmdletBinding()]
    param( )

	try {

		$ConfigFile = Get-Item -LiteralPath $Global:WFLDefaultConfig -ErrorAction Stop

		Get-Content -LiteralPath $ConfigFile.FullName | foreach-Object{ Write-Output $_ }

	} catch {

		$e = $_

		Write-Output $('[ERROR][Script] {0}' -f $e.Exception.Message)
	}

} # End Function Get-WebsiteFailedLoginsDefaultConfiguration

Function Copy-WebsiteFailedLoginsDefaultConfiguration
{
    <#
    .SYNOPSIS

    Copy the WebsiteFailedLogins default configuration file to the destination folder.

    #>

    [CmdletBinding()]
    param( 
			[parameter(Mandatory=$true)]
			[ValidateScript({Test-Path -LiteralPath $_ -PathType Container})]
            [string]
            # Destination folder to copy WebsiteFailedLogins.ini
            $DestinationFolder
	)

	try {
	
		$ConfigFile = Get-Item -LiteralPath $Global:WFLDefaultConfig -ErrorAction Stop

		Copy-Item -Path $ConfigFile.FullName -Destination $DestinationFolder

	} catch {
	
		$e = $_

		Write-Output $('[ERROR][Script] {0}' -f $e.Exception.Message)
	}

} # End Function Copy-WebsiteFailedLoginsDefaultConfiguration

Function Set-ReadMeAndIniPath
{
    <#
    .SYNOPSIS

    Set path for README and default configuration file in global variables.

    #>

    [CmdletBinding()]
    param( )

	if([System.String]::IsNullOrEmpty($Global:Ini['Script'])){

		$Global:Ini.Add('Script',@{})
	}

	$ReadMePath = Join-Path -Path $PSScriptRoot -ChildPath 'README.md'

	$Global:WFLReadme = $ReadMePath

	$DefaultConfigPath = Join-Path -Path $PSScriptRoot -ChildPath 'WebsiteFailedLogins.ini'

	$Global:WFLDefaultConfig = $DefaultConfigPath
}

Set-ReadMeAndIniPath
