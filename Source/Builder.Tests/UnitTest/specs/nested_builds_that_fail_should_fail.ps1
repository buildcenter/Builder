task default -depends RunAlwaysFail

task RunAlwaysFail {
	Invoke-Builder .\nested\always_fail.ps1
}
