properties {
	$x = 1
}

task default -depends RunNested1, RunNested2, CheckX

task RunNested1 {
	Invoke-Builder nesting_sub1.ps1 -NoLogo
}

task RunNested2 {
	Invoke-Builder nesting_sub2.ps1 -NoLogo
}

task CheckX {
	assert ($x -eq 1) ('Expect $x to be 1 (actual value is {0})' -f $x) 
}