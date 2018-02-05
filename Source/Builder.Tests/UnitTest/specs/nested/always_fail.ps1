task default -depends AlwaysFail

task AlwaysFail {
	assert $false "This should always fail."
}