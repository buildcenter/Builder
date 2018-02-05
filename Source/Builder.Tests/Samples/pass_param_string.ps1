<#
	Demonstrates using the `-Parameters` parameter.

	The 'Parameters' parameter is a hashtable that can be accessed as variables in the build script.

	This script assumes that the 'Parameters' parameter is a hashtable containing:
		- 'buildConfiguration' = 'release'

	Notice that these keys in the 'Parameters' hashtable can be directly used in the script as variables.

	To try out, run this command in Powershell:

		.\Builder.ps1 ..\Builder.Tests\Samples\pass_param_string.ps1 -Parameters @{'buildConfiguration' = 'release'}
#>

properties {
	$buildOutputPath = ".\bin\$buildConfiguration"
}

task default -depends DoRelease

task DoRelease {
	assert ("$buildConfiguration" -ne $null) '$buildConfiguration should not be null'
	assert ("$buildConfiguration" -eq 'Release') 'Call with -parameters @{ buildConfiguration = "Release" }'
	
	say ("This will build output into path '{0}' for build configuration '{1}'" -f $buildOutputPath, $buildConfiguration)
}
