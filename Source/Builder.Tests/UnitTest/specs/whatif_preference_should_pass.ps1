task default -depends RunWhatIf

task RunWhatIf {
	try 
	{
		# Setup the -whatif flag globally
		$global:WhatIfPreference = $true
		
		# Ensure that the nested script does something with -whatif e.g. Set-Item
		$parameters = @{ p1 = 'whatifcheck' }
		
		Invoke-Builder .\nested\whatifpreference.ps1 -Parameters $parameters
	} 
	finally 
	{
		$global:WhatIfPreference = $false
	}
}
