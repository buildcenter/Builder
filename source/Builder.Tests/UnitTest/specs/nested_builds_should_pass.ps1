properties {
	$x = 1
}

task default -depends RunNested1, RunNested2, CheckX

task RunNested1 {
	Invoke-Builder .\nested\nested1.ps1
}

task RunNested2 {
	Invoke-Builder .\nested\nested2.ps1
}

task CheckX {
	assert ($x -eq 1) '$x was not 1' 
}