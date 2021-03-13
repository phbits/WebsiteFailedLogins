# Require TLS1.2 for all communications
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Function Invoke-WebsiteFailedLogins
{
    <#
        .SYNOPSIS

            Launches WebsiteFailedLogins.

        .DESCRIPTION

            Generates an alert for:

                - Each IP address meeting or exceeding the threshold FailedLoginsPerIP

                - When the total failed logins threshold (TotalFailedLogins) is met or exceeded

            See wiki for details.

        .LINK

            https://github.com/phbits/WebsiteFailedLogins/wiki

        .EXAMPLE

            $results = Invoke-WebsiteFailedLogins -Configuration D:\WFL\W3SVC1.ini

        .EXAMPLE

            $results = Invoke-WebsiteFailedLogins -Configuration D:\WFL\W3SVC1.ini -RunningConfig

        .INPUTS

            System.String

        .OUTPUTS

            System.Collections.Hashtable
    #>
    [CmdletBinding()]
    [OutputType('System.Collections.Hashtable')]
    param(
            [Parameter(Mandatory=$true)]
			[ValidateScript({Test-Path -LiteralPath $_})]
            [string]
            # Path to configuration file.
            $Configuration
            ,
            [Parameter(Mandatory=$false)]
            [switch]
            # Performs the minimum validation checks against the configuration file. Use this switch after all configuration errors have been resolved.
            $RunningConfig
    )

    $returnValue = @{
                        'FailedLoginsPerIP' = @{}
                        'TotalFailedLogins' = @{}
                        'HasError'          = $false
                        'HasResults'        = $false
                        'Configuration'     = @{}
                        'ErrorMessages'     = @()
                    }

    $iniConfig = Get-IniConfig -Path $Configuration

    $configTestResult = Assert-ValidIniConfig -IniConfig $iniConfig -RunningConfig:$($RunningConfig)

    $returnValue.Configuration = $configTestResult.Configuration

    if ($configTestResult.HasError)
    {
        $returnValue.HasError = $true
        $returnValue.ErrorMessages = $configTestResult.ErrorMessages

        $alertData = $returnValue
        $alertData.Remove('FailedLoginsPerIP')
        $alertData.Remove('TotalFailedLogins')

        Submit-Alert -IniConfig $returnValue.Configuration -AlertData $alertData -TerminatingError

    } else {

        $lpQuery = Get-LogparserQuery -IniConfig $returnValue.Configuration

        $returnValue.Configuration.Logparser.Add('WebsiteFailedLoginsQuery', $lpQuery)

        $allFailedLogins = Get-WebsiteFailedLogins -IniConfig $returnValue.Configuration

        $returnValue.Configuration.Script.Add('EndTimeTSZ', (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ'))

        if ([System.String]::IsNullOrEmpty($allFailedLogins) -eq $false)
        {
            [Int] $totalFailedLogins = 0
            [Int] $bottom20Percent = [System.Math]::Round($(.2 * $returnValue.Configuration.Website.TotalFailedLogins))

            [Hashtable] $totalFailedLoginClientIpList = @{}

            foreach ($entry in $allFailedLogins)
            {
                if ([Int] $entry.FailedLoginCount -ge [Int] $returnValue.Configuration.Website.FailedLoginsPerIP)
                {
                    $clientIpResult = Get-FailedLoginsPerIpResult -IniConfig $returnValue.Configuration `
                                                                  -ClientIP $entry.ClientIP `
                                                                  -FailedLogins $entry.FailedLoginCount

                    $returnValue.FailedLoginsPerIP.Add($entry.ClientIP, $clientIpResult)

                    $returnValue.HasResults = $true
                }

                if ([Int] $entry.FailedLoginCount -gt $bottom20Percent)
                {
                    $totalFailedLoginClientIpList.Add($entry.ClientIP, [Int] $entry.FailedLoginCount)
                }

                $totalFailedLogins += [Int] $entry.FailedLoginCount
            }

            if ($totalFailedLogins -ge [Int] $returnValue.Configuration.Website.TotalFailedLogins)
            {
                $returnValue.TotalFailedLogins = Get-TotalFailedLoginsResult -IniConfig $returnValue.Configuration `
                                                                             -TotalFailedLogins $totalFailedLogins `
                                                                             -ClientIpList $totalFailedLoginClientIpList

                $returnValue.HasResults = $true
            }
        }

        # send alerts
        if ($returnValue.HasResults -eq $true -and $returnValue.Configuration.Alert.Method -imatch "(Smtp|WinEvent)")
        {
            if ($returnValue.FailedLoginsPerIP.Count -gt 0)
            {
                foreach ($key in $returnValue.FailedLoginsPerIP.Keys)
                {
                    Submit-Alert -IniConfig $returnValue.Configuration `
                                 -AlertData $($returnValue.FailedLoginsPerIP[$key])
                }
            }

            if ($returnValue.TotalFailedLogins.Count -gt 0)
            {
                Submit-Alert -IniConfig $returnValue.Configuration `
                             -AlertData $returnValue.TotalFailedLogins
            }
        }
    }

    return $returnValue

} # End Function Invoke-WebsiteFailedLogins

Function Get-WebsiteFailedLoginsREADME
{
    <#
        .SYNOPSIS

            Gets the WebsiteFailedLogins README file.
    #>
    [OutputType('System.String[]')]
    [CmdletBinding()]
    param(
            [Parameter(Mandatory=$false)]
            [System.String]
            # Section to return.
            $SectionKeyword
    )

	try {

        $readMePath = Join-Path -Path $PSScriptRoot -ChildPath 'README.md'

		$readMeFile = Get-Item -LiteralPath $readMePath -ErrorAction Stop

		$readMeContent = Get-Content -LiteralPath $readMeFile.FullName

        if ([System.String]::IsNullOrEmpty($SectionKeyword))
        {
            $readMeContent | foreach-Object{ Write-Output $_ }

        } else {

            $printLine = $false

            $sectionKeywordLower = $SectionKeyword.ToLower().Trim()

            for ($i=0; $i -lt $readMeContent.Length; $i++)
            {
                $line = $readMeContent[$i]

                if ($line.Trim().StartsWith('#'))
                {
                    $printLine = $false
                }

                if ([System.String]::IsNullOrEmpty($line) -eq $false)
                {
                    if ($line.ToLower().Contains($sectionKeywordLower))
                    {
                        if ($printLine -eq $false)
                        {
                            Write-Output $readMeContent[$i - 1]
                        }

                        $printLine = $true
                    }
                }

                if ($printLine)
                {
                    Write-Output $line
                }
            }
        }

	} catch {

		$e = $_
		Write-Error -Message "$('[ERROR][Exception] {0}' -f $e.Exception.Message)"
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
			[Parameter(Mandatory=$false)]
            [ValidateScript({Test-Path -LiteralPath $_ -PathType Container})]
			[string]
            # Destination folder to copy README.md
            $DestinationFolder = (Get-Location).Path
	)

	try {

        $readMePath = Join-Path -Path $PSScriptRoot -ChildPath 'README.md'

		$readMeFile = Get-Item -LiteralPath $readMePath -ErrorAction Stop

		Copy-Item -Path $readMeFile.FullName -Destination $DestinationFolder

	} catch {

		$e = $_
		Write-Error -Message "$('[ERROR][Exception] {0}' -f $e.Exception.Message)"
	}

} # End Function Copy-WebsiteFailedLoginsReadme

Function Get-WebsiteFailedLoginsDefaultConfiguration
{
    <#
        .SYNOPSIS

            Gets the WebsiteFailedLogins default configuration file.
    #>
    [OutputType('System.String[]')]
    [CmdletBinding()]
    param( )

	try {

        $defaultConfigPathFolder = Join-Path -Path $PSScriptRoot -ChildPath 'Resources'

        $defaultConfigPath = Join-Path -Path $defaultConfigPathFolder -ChildPath 'WebsiteFailedLogins_default.ini'

		$configFile = Get-Item -LiteralPath $defaultConfigPath -ErrorAction Stop

        [string[]] $configContents = Get-Content -LiteralPath $configFile.FullName

        return $configContents

	} catch {

		$e = $_
		Write-Error -Message "$('[ERROR][Exception] {0}' -f $e.Exception.Message)"
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
			[Parameter(Mandatory=$false)]
			[ValidateScript({Test-Path -LiteralPath $_ -PathType Container})]
            [string]
            # Destination folder to copy WebsiteFailedLogins.ini
            $DestinationFolder = (Get-Location).Path
	)

	try {

        $defaultConfigPathFolder = Join-Path -Path $PSScriptRoot -ChildPath 'Resources'

        $defaultConfigPath = Join-Path -Path $defaultConfigPathFolder -ChildPath 'WebsiteFailedLogins_default.ini'

		$configFile = Get-Item -LiteralPath $defaultConfigPath -ErrorAction Stop

		Copy-Item -Path $configFile.FullName -Destination $DestinationFolder

	} catch {

		$e = $_
		Write-Error -Message "$('[ERROR][Exception] {0}' -f $e.Exception.Message)"
	}

} # End Function Copy-WebsiteFailedLoginsDefaultConfiguration
