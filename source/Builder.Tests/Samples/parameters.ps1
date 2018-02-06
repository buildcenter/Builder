<#
	Demonstrates using the `-Parameters` parameter.

	The 'Parameters' parameter is a hashtable that can be accessed as variables in the build script.

	This script assumes that the 'Parameters' parameter is a hashtable containing:
		- 'p1' = 'v1'
		- 'p2' = 'v2'

	Notice that these keys in the 'Parameters' hashtable can be directly used in the script as variables.

	To try out, run this command in Powershell:

		.\Builder.ps1 ..\Builder.Tests\Samples\parameters.ps1 -Parameters @{'p1' = 'v1'; 'p2' = 'v2'}
#>

properties {
	$my_property = $p1 + $p2
}

task default -depends TestParams

task TestParams { 
	say ('Value of $my_property is {0}' -f $my_property)
	assert ($my_property -eq 'v1v2') "Run with -parameters @{'p1' = 'v1'; 'p2' = 'v2'}"
}
