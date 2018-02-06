<#
	Instead of using `assert`, the parameter 'RequiredVariables' offers an easier way to check that 
	the variables you need are not null before executing the task.

	If the variable you require is null or undefined, an error is raised.

	To try out, run this in Powershell:

		.\Builder.ps1 ..\Builder.Tests\Samples\requiredvariables.ps1 -properties @{ x=1; y=2; z=3 }
#>

properties {
  $x = $null
  $y = $null
  $z = $null
}

task default -depends TestRequiredVariables

# Tip: you can separate multiple lines using `
task TestRequiredVariables `
  -description "This task shows how to make a variable required to run task. Run this script with -properties @{x = 1; y = 2; z = 3}" `
  -requiredVariables x, y, z `
{
	say ("You will only see me if the variables x, y and z are defined!")
}
