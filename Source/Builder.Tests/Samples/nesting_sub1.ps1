properties {	$x = 100}task default -depends Nested1CheckXtask Nested1CheckX{	assert ($x -eq 100) ('Expect $x to be 100 (actual value is {0})' -f $x) }