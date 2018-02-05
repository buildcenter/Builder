will {
    say 'I am a will in a master build script'
}

task default -depends Finish

task Finish {
	say 'I am master build script. I am going to call the sub build script...'
	#Invoke-Builder -NoLogo -BuildFile (Join-Path $BuildEnv.BuildScriptDir -ChildPath 'lastwill_sub.ps1')
	Invoke-Builder nestedwill_sub.ps1 -NoLogo
	say ('Something went wrong in {0} if you can see me!' -f 'Finish')
}
