<#
	If an error occured in a task, `taskTearDown` will not work for that task and beyond.
#>

task default -depends Test

task Test -depends Compile, Clean {
    assert $false "This fails."
}

task Compile -depends Clean {
    "Compile"
}

task Clean {
    "Clean"
}

taskTearDown {
    "$($BuildEnv.Context.Peek().CurrentTaskName) Tear Down"
}