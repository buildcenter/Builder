properties {
	$x = $null
	$y = $null
	$z = $null
}

task default -depends TestProperties

task TestProperties { 
  assert ($x -ne $null) "x should not be null"
  assert ($y -ne $null) "y should not be null"
  assert ($z -eq $null) "z should be null"
}