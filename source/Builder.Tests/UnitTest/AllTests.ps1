#Requires -Version 2.0

$script:IgnoreError = $(
    if ($PSVersionTable.PSVersion.Major -ge 3) { 'Ignore' }
    else { 'SilentlyContinue' }
)

#######################################################################
#  Data
#######################################################################

DATA PBUnitTestLocalizedData
{
    ConvertFrom-StringData @'
# ---- [ Localized Data ] ---------------------------------------------

UnitTest = Unit Test
Err_BadSpecFileName  = Invalid unit test pecification file name. A specification file should end with '_should_pass' or '_should_fail: {0}
Header = Running unit test on Builder
Passed = PASSED
Failed = FAILED
HasFailedTest = One or more of the build files failed x_x
AllTestsSuccessful = All build specs passed (^_^
DetailHeader = Test Results
ConclusionHeader = Conclusion

# ---- [ /Localized Data ] --------------------------------------------
'@
}
Import-LocalizedData -BindingVariable PBUnitTestLocalizedData -FileName Message.psd1 -ErrorAction $script:IgnoreError


#######################################################################
#  Private Module Functions
#######################################################################

function RunBuilds
{
	$buildFileList = dir (Join-Path $PSScriptRoot -ChildPath 'specs/*.ps1')
	$testResults = @()

	# Add a fake build file to the $buildFiles array so that we can verify
	# that Invoke-Builder fails
	$nonExistantBuildFile = '' | select Name, FullName
	$nonExistantBuildFile.Name = "specifying_a_non_existant_buildfile_should_fail.ps1"
	$nonExistantBuildFile.FullName = "c:\specifying_a_non_existant_buildfile_should_fail.ps1"
	$buildFileList += $nonExistantBuildFile

	PrintOutput '[' -ForegroundColor Gray -NoNewLine
	foreach ($buildFile in $buildFileList) 
	{		
		$testResult = "" | select Name, Result
		$testResult.Name = $buildFile.Name
		Invoke-Builder $buildFile.FullName -Parameters @{
			'p1'='v1'
			'p2'='v2'
		} -Properties @{
			'x'='1'
			'y'='2'
		} -Initialization { 
			if (-not $container) 
            { 
                $container = @{}; 
            } 
			$container.bar = "bar" 
			$container.baz = "baz"
			$bar = 2
			$baz = 3 
		} | Out-Null
		$testResult.Result = GetResult $buildFile.Name -BuildSuccess:$BuildEnv.BuildSuccess
		$testResults += $testResult

		if ($testResult.Result -eq 'Passed')
		{
			PrintOutput '-' -ForegroundColor Green -NoNewLine
		}
		else
		{
			PrintOutput 'x' -ForegroundColor Red -NoNewLine
		}
	}
	PrintOutput ']' -ForegroundColor Gray

  	$testResults
}

function GetResult 
{
	[CmdletBinding()]
	Param(
		[Parameter(Position = 1, Mandatory = $true)]
		[string]$FileName,

		[Parameter(Mandatory = $false)]
		[switch]$BuildSuccess
	)

	$shouldSucceed = $null

	if ($FileName.EndsWith("_should_pass.ps1")) 
	{
		$shouldSucceed = $true
	} 
	elseif ($FileName.EndsWith("_should_fail.ps1")) 
	{
		$shouldSucceed = $false
	} 
	else 
	{
		$errRecord = New-ErrorRecord -Message ($PBUnitTestLocalizedData.Err_BadSpecFileName -f $FileName) -Exception FormatException -ErrorID BadSpecFileName -ErrorCategory InvalidData
		$PSCmdlet.ThrowTerminatingError($errRecord)
	}

	if ($BuildSuccess -eq $shouldSucceed) { 'Passed' }
	else { 'Failed' }
}

function PrintOutput
{
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory = $true, Position = 1)]
		[string]$Text,

		[Parameter(Mandatory = $false)]
		[ConsoleColor]$ForegroundColor = 'White',

		[Parameter(Mandatory = $false)]
		[switch]$NoNewLine
	)

	if (($Host.UI -ne $null) -and 
        ($Host.UI.RawUI -ne $null) -and 
        ($Host.UI.RawUI.ForegroundColor -ne $null)) 
    {
    	Write-Host $Text -ForegroundColor $ForegroundColor -NoNewLine:$NoNewLine
    }
    else 
    {
        Write-Output $Text
    }
}


#######################################################################
#  Main
#######################################################################

PrintOutput ('=' * $PBUnitTestLocalizedData.UnitTest.Length)
PrintOutput $PBUnitTestLocalizedData.UnitTest
PrintOutput ('=' * $PBUnitTestLocalizedData.UnitTest.Length)

# build with progress bar
Write-Output ''
PrintOutput $PBUnitTestLocalizedData.Header -ForegroundColor Cyan

Remove-Module Builder -ErrorAction $script:IgnoreError
$builderPsmPath = Join-Path (Split-Path $PSScriptRoot -Parent) -ChildPath '../Builder/Builder.psm1'
Import-Module $builderPsmPath
$BuildEnv.RunByUnitTest = $true
$results = RunBuilds
Remove-Module Builder

# show results
Write-Output ''
PrintOutput $PBUnitTestLocalizedData.DetailHeader -ForegroundColor Cyan
PrintOutput ('-' * $PBUnitTestLocalizedData.DetailHeader.Length) -ForegroundColor Cyan

$results | sort 'Name' | ForEach-Object { 
	$testName = $_.Name.Substring(0, $_.Name.Length - 4) # .ps1
	if ($_.Result -eq 'Passed') 
	{ 
		PrintOutput ('[{0}] {1}' -f $PBUnitTestLocalizedData.Passed, $testName) -ForegroundColor Green
	} 
	else 
	{ 
		PrintOutput ('[{0}] {1}' -f $PBUnitTestLocalizedData.Failed, $testName) -ForegroundColor Red
	}
} 

# conclude
Write-Output ''
PrintOutput $PBUnitTestLocalizedData.ConclusionHeader -ForegroundColor Cyan
PrintOutput ('-' * $PBUnitTestLocalizedData.ConclusionHeader.Length) -ForegroundColor Cyan

$failures = $results | where { $_.Result -eq 'Failed' }
if ($failures) 
{	
	PrintOutput $PBUnitTestLocalizedData.HasFailedTest -ForegroundColor Red
	exit 1
} 
else 
{
	PrintOutput $PBUnitTestLocalizedData.AllTestsSuccessful -ForegroundColor Green
	exit 0
}
