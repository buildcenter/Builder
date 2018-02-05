<#
	You can override properties defined in the build script from the command line.

	In this example, you will override the value of 'x' and 'y' in the build script.

	To try out, run the following command in Powershell:

		 .\Builder.ps1 ..\Builder.Tests\Samples\properties.ps1 -Properties @{ 'x' = 1; 'y' = 2 }
#>

properties {
  $x = $null
  $y = $null
  $z = $null
}

task default -depends TestProperties

task TestProperties { 
  assert ($x -eq 1) "x should be 1. Run with -properties @{x = 1; y = 2}"
  assert ($y -eq 2) "y should be 2. Run with -properties @{x = 1; y = 2}"
  assert ($z -eq $null) "z should be null"
}
