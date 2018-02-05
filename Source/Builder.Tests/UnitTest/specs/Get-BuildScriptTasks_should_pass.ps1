task default -depends CheckGetBuildScriptTasks

function Assert-EqualArrays($a, $b, $message)
{
    $differences = @(Compare-Object $a $b -SyncWindow 0)

    if ($differences.Length -gt 0)
    {
        $differences
    }

    assert ($differences.Length -eq 0) "$message : $($differences.Length) differences found."
}

function Assert-TaskEqual($t1, $t2)
{
    assert ($t1.Name -eq $t2.Name)                "Task names do not match: $($t1.Name) vs $($t2.Name)"
    assert ($t1.Alias -eq $t2.Alias)              "Task aliases do not match for task $($t1.Name): $($t1.Alias) vs $($t2.Alias)"
    assert ($t1.Description -eq $t2.Description)  "Task descriptions do not match for task $($t1.Name): $($t1.Description) vs $($t2.Description)"

    Assert-EqualArrays $t1.DependsOn $t2.DependsOn "Task dependencies do not match for task $($t1.Name)"
}

task CheckGetBuildScriptTasks {
    $tasks = Get-BuildScriptTasks .\nested\docs.ps1
    $tasks = $tasks | sort -Property Name

    assert ($tasks.Length -eq 7) 'Unexpected number of tasks.'

    $taskSpecs = @(
        [pscustomobject]@{
            Name = 'Compile'
            Alias = ''
            Description = ''
            DependsOn = @('CompileSolutionA', 'CompileSolutionB')
        }
        [pscustomobject]@{
            Name = 'CompileSolutionA'
            Alias = ''
            Description = 'Compiles solution A'
            DependsOn = @()
        }
        [pscustomobject]@{
            Name = 'CompileSolutionB'
            Alias = ''
            Description = ''
            DependsOn = @()
        }
        [pscustomobject]@{
            Name = 'default'
            Alias = ''
            Description = ''
            DependsOn = @('Compile', 'Test')
        }
        [pscustomobject]@{
            Name = 'IntegrationTests'
            Alias = ''
            Description = ''
            DependsOn = @()
        }
        [pscustomobject]@{
            Name = 'Test'
            Alias = ''
            Description = ''
            DependsOn = @('UnitTests', 'IntegrationTests')
        }
        [pscustomobject]@{
            Name = 'UnitTests'
            Alias = 'ut'
            Description = ''
            DependsOn = @()
        }
    )

    for ($i = 0; $i -lt $taskSpecs.Count; $i++)
    {
        Assert-TaskEqual $tasks[$i] $taskSpecs[$i]
    }
}
