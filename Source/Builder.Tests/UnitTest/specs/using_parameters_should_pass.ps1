﻿properties {
	$my_property = $p1 + $p2
}

task default -depends TestParams

task TestParams { 
	assert ($my_property -ne $null) '$my_property should not be null'  
}