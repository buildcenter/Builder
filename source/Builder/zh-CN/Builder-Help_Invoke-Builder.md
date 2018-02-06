.SYNOPSIS
    Runs a Builder build script.

.DESCRIPTION
    Use this command to execute a build script. Refer to the links section for examples on how to write build scripts using Builder DSL syntax.

.PARAMETER BuildFile
    The path to the build script to execute.

.PARAMETER Docs
    Prints a list of tasks. This parameter is valid but redundant if the `DetailDocs` parameter is also specified.

.PARAMETER DetailDocs
    Prints a list of tasks and their descriptions.

.PARAMETER Initialization
    Runs a script before starting the build script.

.PARAMETER NoLogo
    Do not display the startup banner and copyright message.

.PARAMETER Parameters
    A hashtable containing parameters to be passed into the current build script. These parameters will be processed before the `Properties` function of the 
    script is processed. This means you can access parameters from within the `Properties` function.

.PARAMETER Properties
    A hashtable containing properties to be passed into the current build script. These properties will override matching properties that are found in the 
    `Properties` function of the script.

.PARAMETER TaskList
    A comma-separated list of task names to execute.

.PARAMETER TimeReport
    Display the time report.

.EXAMPLE
    Invoke-Builder

    DESCRIPTION
    -----------
    Runs the 'default' task in the '.build.ps1' build script.



.EXAMPLE
    Invoke-Builder '.\build.ps1' Tests,Package

    DESCRIPTION
    -----------
    Runs the 'Tests' and 'Package' tasks in the '.build.ps1' build script.



.EXAMPLE
    Invoke-Builder Tests

    DESCRIPTION
    -----------
    Run the 'Tests' task in the 'default.ps1' build script. The 'default.ps1' file is assumed to be in the current directory.



.EXAMPLE
    Invoke-Builder 'Tests, Package'

    DESCRIPTION
    -----------
    Run the 'Tests' and 'Package' tasks in the 'default.ps1' build script. The 'default.ps1' file is assumed to be in the current directory.

    NOTE: The quotes around the list of tasks to execute is required if you want to execute more than 1 task.



.EXAMPLE
    Invoke-Builder .\build.ps1 -docs

    DESCRIPTION
    -----------
    Prints a report of all the tasks and their dependencies and descriptions and then exits.



.EXAMPLE
    @'
    properties {
      $my_property = $p1 + $p2
    }

    task default -depends TestParams

    task TestParams {
      assert ($my_property -ne $null) '$my_property should not be null'
    }
    '@ | Set-Content -Path .\parameters.ps1
    Invoke-Builder .\parameters.ps1 -Parameters @{ "p1" = "v1"; "p2" = "v2" }

    DESCRIPTION
    -----------
    Runs the build script called 'parameters.ps1' and passes in parameters 'p1' and 'p2' with values 'v1' and 'v2'.

    Notice how you can refer to the parameters that were passed into the script from within the "properties" function. The value of 
    the `$p1` variable should be the string "v1" and the value of the `$p2` variable should be "v2".



.EXAMPLE
    @'
    properties {
        $x = $null
        $y = $null
        $z = $null
    }

    task default -depends TestProperties

    task TestProperties {
        assert ($x -ne $null) "x should not be null"
        assert ($y -ne $null) "y should not be null"
        assert ($z -eq $null) "z should be null"
    }
    '@ | Set-Content -Path .\properties.ps1
    Invoke-Builder .\properties.ps1 -Properties @{ "x" = "1"; "y" = "2" }

    DESCRIPTION
    -----------
    Runs the build script called 'properties.ps1' and passes in parameters 'x' and 'y' with values '1' and '2'.

    This feature allows you to override existing properties in your build script.



.NOTE
    ---- Exceptions ----

    If there is an exception thrown during the running of a build script Builder will set the `$BuildEnv.BuildSuccess` variable to 
    `$false`. To detect failue outside PowerShell (for example by build server), finish PowerShell process with non-zero exit code when 
    `$BuildEnv.BuildSuccess` is `$false`. Calling Builder from 'cmd.exe' with 'Builder.cmd' will give you that behaviour.



    ---- BuildEnv variable ----

    When the Builder module is loaded, a special variable called `$BuildEnv` is created. This variable is a hashtable containing the 
    following keys:

    - **Version**: contains the current version of Builder
    - **Context**: holds onto the current state of all variables
    - **RunByUnitTest**: indicates that build is being run by the unit tester. Do not modify this variable.
    - **DefaultSetting**: contains default configuration. To override, modify the 'Builder-Config.ps1' file, which 
      must be placed in the same directory as 'Builder.psm1' or the build script.
    - **BuildSuccess**: indicates that the current build was successful.
    - **BuildScriptFile**: contains a `System.IO.FileInfo` object representing the current build script.
    - **BuildScriptDir**: contains the fully qualified path to the current build script.

.LINK
    http://www.github.com/buildcenter/Builder

.LINK
    Task

.LINK
    Include

.LINK
    Properties

.LINK
    PrintTask

.LINK
    TaskSetup

.LINK
    TaskTearDown

.LINK
    Assert

.LINK
    EnvPath
