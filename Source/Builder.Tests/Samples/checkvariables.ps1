properties {
  $x = 1
  $y = 2
}

printTask "[{0}]"

task default -depends Verify 

task Verify -description "This task verifies Builder's variables" {
  say 'test variable:\BuildEnv ...'
  assert (Test-Path 'variable:\BuildEnv') "BuildEnv variable was not exported from module"

  say 'test BuildEnv hashtable...'
  @(
    'Version', 'Context', 'BuildSuccess', 'BuildScriptFile', 'BuildScriptDir'
  ) | ForEach-Object {
    say ('- key: {0}' -f $_)
    assert ($BuildEnv.ContainsKey($_)) ("BuildEnv variable does not contain '{0}'" -f $_)
  }

  say 'test variable data is valid...'
  assert (-not [string]::IsNullOrEmpty($BuildEnv.Version)) '$BuildEnv.Version was null or empty'
  assert ($BuildEnv.Context -ne $null) '$BuildEnv.Context was null'
  assert (-not $BuildEnv.BuildSuccess) '$BuildEnv.BuildSuccess should be $false'
  assert ($BuildEnv.BuildScriptFile -ne $null) '$BuildEnv.BuildScriptFile was null'
  assert ($BuildEnv.BuildScriptFile.Name -eq "checkvariables.ps1") ("BuildEnv variable: {0} was not equal to 'checkvariables.ps1'" -f $BuildEnv.BuildScriptFile.Name)
  assert (-not [string]::IsNullOrEmpty($BuildEnv.BuildScriptDir)) '$BuildEnv.BuildScriptDir was null or empty'

  say 'test context variables...'
  assert ($BuildEnv.Context.Peek().Tasks.Count -ne 0) "BuildEnv context variable 'tasks' had length zero"
  assert ($BuildEnv.Context.Peek().Properties.Count -ne 0) "BuildEnv context variable 'properties' had length zero"
  assert ($BuildEnv.Context.Peek().Includes.Count -eq 0) "BuildEnv context variable 'includes' should have had length zero"
  assert ($BuildEnv.Context.Peek().Setting -ne $null) "BuildEnv context variable 'Setting' was null"
  assert ($BuildEnv.Context.Peek().CurrentTaskName -eq "Verify") 'BuildEnv variable: $currentTaskName was not set correctly'
}
