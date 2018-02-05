<#
    Demonstrates running tasks in parallel.

    Each of `ParallelTask1` and `ParallelTask2` will run between 3-8 seconds.

    They will be launched by the `ParallelTask1andTask2` task.

    Total time taken should be a little more than the time taken for the longer task, instead of the 
    sum of running each task sequentially.

    To try out:
        .\build.cmd ..\Builder.Tests\Samples\paralleltasks.ps1 -TimeReport
#>

task ParallelTask1 {
    $waitSec = Get-Random -Minimum 3 -Maximum 8
    Start-Sleep -Seconds $waitSec
    say "ParallelTask1 has finished after $waitSec seconds"
}

task ParallelTask2 {
    $waitSec = Get-Random -Minimum 3 -Maximum 8
    Start-Sleep -Seconds $waitSec
    say "ParallelTask2 has finished after $waitSec seconds"
}

task ParallelTask1andTask2 {
    $jobArray = @()

    @(
        "ParallelTask1", "ParallelTask2"
    ) | ForEach-Object {
        $jobArray += Start-Job { 
            Param($scriptFile, $taskName, $builderPath)
            
            ipmo $builderPath
            Invoke-Builder $scriptFile -TaskList $taskName -NoLogo
        } -ArgumentList $BuildEnv.BuildScriptFile.FullName, $_, $BuildEnv.ModulePath 
    }

    Wait-Job $jobArray | Receive-Job
}

task default -depends ParallelTask1andTask2
