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

            Automate this by running it as a scheduled task. See README.md for details or run the following command:

                Get-WebsiteFailedLoginsREADME -SectionKeyword Scheduling

        .INPUTS

            System.String

        .OUTPUTS

            System.Collections.Hashtable
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
            # Performs the minimum validation checks against the configuration file. Use this switch after all configuration errors have been resolved.
            $RunningConfig
    )
   
    $returnValue = @{
                        'FailedLoginsPerIP' = @()
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
    
    } else {

        # Per IP Failed Logins
        $resultFailedLoginsPerIP = Get-FailedLoginsPerIP -IniConfig $returnValue.Configuration

        if ($resultFailedLoginsPerIP.Count -gt 0)
        {
            $returnValue.FailedLoginsPerIP = $resultFailedLoginsPerIP

            $returnValue.HasResults = $true

            foreach ($entry in $resultFailedLoginsPerIP)
            {
                Submit-Alert -Message $($entry.ClientIP) -SubjectAppend $($entry.ClientIP)
            }
            <#
            for ($i=0; $i -lt $keys.Length; $i++){

                $key = $keys[$i]

                $Global:WFLResults += "# IP Entry $($i + 1) #"

                $hashMsg[$key] | foreach-Object{ $Global:WFLResults += '  {0}' -f $_ }

                Submit-Alert -Message $($hashMsg[$key]) -SubjectAppend $key
            }
            #>
        }

        # Total Failed Logins
        $resultTotalFailedLogins = Get-TotalFailedLogins -IniConfig $returnValue.Configuration

        if ($resultTotalFailedLogins.Count -gt 0)
        {
            $returnValue.TotalFailedLogins = $resultTotalFailedLogins

            $returnValue.HasResults = $true

            Submit-Alert -Message $resultTotalFailedLogins -SubjectAppend 'TotalFailedLogins' -TotalFailedLogins
            <#
            $Global:WFLResults += '# Total Failed Logins #'
            
            $arrMsg | ForEach-Object{ $Global:WFLResults += '  {0}' -f $_ }

            Submit-Alert -Message $arrMsg -SubjectAppend 'TotalFailedLogins' -TotalFailedLogins
            #>
        }




    }

    


    if ($IniConfig.Count -le 1)
    {
        $ReturnValue.HasError = $true

    } else {

        if ($MinimumValidation)
        {
            $ReturnValue.HasError = Confirm-IniConfig -Brief
    
        } else {
        
            $ReturnValue.HasError = Confirm-IniConfig
        }
    }

    if ($ReturnValue.HasError -eq $false)
    {
        # Per IP Failed Logins
        $resultFailedLoginsPerIP = Get-FailedLoginsPerIP -IniConfig $IniConfig

        if ($resultFailedLoginsPerIP.Count -gt 0)
        {
            $returnValue.FailedLoginsPerIP = $resultFailedLoginsPerIP

            $returnValue.HasResults = $true

            foreach ($entry in $resultFailedLoginsPerIP)
            {
                Submit-Alert -Message $($entry.ClientIP) -SubjectAppend $($entry.ClientIP)
            }
            <#
            for ($i=0; $i -lt $keys.Length; $i++){

				$key = $keys[$i]

                $Global:WFLResults += "# IP Entry $($i + 1) #"

				$hashMsg[$key] | foreach-Object{ $Global:WFLResults += '  {0}' -f $_ }

				Submit-Alert -Message $($hashMsg[$key]) -SubjectAppend $key
            }
            #>
        }

        # Total Failed Logins
        $resultTotalFailedLogins = Get-TotalFailedLogins

        if ($resultTotalFailedLogins.Count -gt 0)
        {
            $returnValue.TotalFailedLogins = $resultTotalFailedLogins

            $returnValue.HasResults = $true

            Submit-Alert -Message $resultTotalFailedLogins -SubjectAppend 'TotalFailedLogins' -TotalFailedLogins
            <#
            $Global:WFLResults += '# Total Failed Logins #'
            
            $arrMsg | ForEach-Object{ $Global:WFLResults += '  {0}' -f $_ }

            Submit-Alert -Message $arrMsg -SubjectAppend 'TotalFailedLogins' -TotalFailedLogins
            #>
        }

    } else {

        [string[]]$Message = $Global:Ini.Script.ErrorMsg

        $Message += '# Loaded Configuration #'

        #$Message += $(Get-LoadedConfig)

        Write-Output $Message

        Submit-Alert -IniConfig $IniConfig -Message $Message -TerminatingError
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
            [parameter(Mandatory=$false)]
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

		Write-Output $('[ERROR] {0}' -f $e.Exception.Message)
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
			[parameter(Mandatory=$false)]
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

		Write-Output $('[ERROR] {0}' -f $e.Exception.Message)
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

        $defaultConfigPath = Join-Path -Path $defaultConfigPathFolder -ChildPath 'WebsiteFailedLogins.ini'

		$configFile = Get-Item -LiteralPath $defaultConfigPath -ErrorAction Stop

        [string[]] $configContents = Get-Content -LiteralPath $configFile.FullName
        
        return $configContents

	} catch {

		$e = $_

		Write-Output $('[ERROR] {0}' -f $e.Exception.Message)
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
			[parameter(Mandatory=$false)]
			[ValidateScript({Test-Path -LiteralPath $_ -PathType Container})]
            [string]
            # Destination folder to copy WebsiteFailedLogins.ini
            $DestinationFolder = (Get-Location).Path
	)

	try {

        $defaultConfigPathFolder = Join-Path -Path $PSScriptRoot -ChildPath 'Resources'

        $defaultConfigPath = Join-Path -Path $defaultConfigPathFolder -ChildPath 'WebsiteFailedLogins.ini'
    
		$configFile = Get-Item -LiteralPath $defaultConfigPath -ErrorAction Stop

		Copy-Item -Path $configFile.FullName -Destination $DestinationFolder

	} catch {
	
		$e = $_

		Write-Output $('[ERROR] {0}' -f $e.Exception.Message)
	}

} # End Function Copy-WebsiteFailedLoginsDefaultConfiguration
