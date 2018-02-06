properties {
	$container = @{}
	$container.foo = "foo"
	$container.bar = $null
	$foo = 1
	$bar = 1
}

task default -depends TestInit

task TestInit {
  # values are:
  # 1: original
  # 2: overide
  # 3: new
  
  assert ($container.foo -eq "foo") "$container.foo should be foo"
  assert ($container.bar -eq "bar") "$container.bar should be bar"
  assert ($container.baz -eq "baz") "$container.baz should be baz"
  assert ($foo -eq 1) "$foo should be 1"
  assert ($bar -eq 2) "$bar should be 2"
  assert ($baz -eq 3) "$baz should be 3"
}