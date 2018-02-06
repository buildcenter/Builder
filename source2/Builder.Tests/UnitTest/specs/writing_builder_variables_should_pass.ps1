properties {
  $x = 1
}

task default -depends Verify 

task Verify -description "This task verifies Builder's variables" {
  #Verify the exported module variables
  cd variable:
  assert (Test-Path "BuildEnv") "variable 'BuildEnv' was not exported from module!"

  assert ($BuildEnv.ContainsKey("BuildSuccess")) "'BuildEnv' variable does not contain key 'BuildSuccess'"
  assert ($BuildEnv.ContainsKey("Version")) "'BuildEnv' variable does not contain key 'Version'"
  assert ($BuildEnv.ContainsKey("BuildScriptFile")) "'BuildEnv' variable does not contain key 'BuildScriptFile'"
  assert ($BuildEnv.ContainsKey("BuildScriptDir")) "'BuildEnv' variable does not contain key 'BuildScriptDir'"  

  assert (-not $BuildEnv.BuildSuccess) '$BuildEnv.BuildSuccess should be $false'
  assert ($BuildEnv.Version) '$BuildEnv.Version was null or empty'
  assert ($BuildEnv.BuildScriptFile) '$BuildEnv.BuildScriptFile was null' 
  assert ($BuildEnv.BuildScriptFile.Name -eq "writing_builder_variables_should_pass.ps1") '$BuildEnv.BuildScriptFile.Name was not equal to "writing_builder_variables_should_pass.ps1"'
  assert ($BuildEnv.BuildScriptDir) '$BuildEnv.BuildScriptDir was null or empty'

  assert ($BuildEnv.Context.Count -eq 1) '$BuildEnv.Context should have had a length of one (1) during script execution'

  $config = $BuildEnv.Context.Peek().Setting
  assert ($config) '$BuildEnv.Setting is $null'
  assert ((New-Object "System.IO.FileInfo" $config.BuildFileName).FullName -eq $BuildEnv.BuildScriptFile.FullName) ('$BuildEnv.Context.Peek().Setting.BuildFileName not equal to "{0}"' -f $BuildEnv.BuildScriptFile.FullName)
  assert ($config.EnvPath -eq $null) '$BuildEnv.Context.Peek().Setting.EnvPath is not $null'
  assert ($config.TaskNameFormat -eq "Executing {0}") '$BuildEnv.Context.Peek().Setting.TaskNameFormat not equal to "Executing {0}"'
  assert (-not $config.VerboseError) '$BuildEnv.Context.Peek().Setting.VerboseError should be $false'
  assert ($config.VerboseLevel -is [Int]) '$BuildEnv.Context.Peek().Setting.VerboseLevel should be integer'
  assert ($config.ColoredOutput) '$BuildEnv.Context.Peek().Setting.ColoredOutput should be $false'
  assert ($config.Modules -eq $null) '$BuildEnv.Context.Peek().Setting.Modules is not $null'
}