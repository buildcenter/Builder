task default -depends CallMSBuild 

task CallUsingEnvPath {
    Invoke-Builder -BuildFile (Join-Path $BuildEnv.BuildScriptDir -ChildPath 'using_envpath_should_pass.ps1')
}

task CallMSBuild -depends CallUsingEnvPath {
	$msBuildVersion = msbuild /version
    say $msBuildVersion
}
