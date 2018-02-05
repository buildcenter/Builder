<#
	The scripts for `taskSetup` and `taskTearDown` gets executed before and after each task respectively.

	To try out:
		.\build.cmd ..\Builder.Tests\Samples\tasksetupandteardown.ps1
#>

taskSetup {
  "Executing task setup"
}

taskTearDown {
  "Executing task tear down"
}

task default -depends TaskB

task TaskA {
  "TaskA executed"
}

task TaskB -depends TaskA {
  "TaskB executed"
}
