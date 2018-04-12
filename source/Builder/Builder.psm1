#Requires -Version 2.0

#######################################################################
#  Localization data
#######################################################################

# Ignore error if localization for current UICulture is unavailable
Import-LocalizedData -BindingVariable PBLocalizedData -BaseDirectory $PSScriptRoot -FileName 'Message.psd1' -ErrorAction $(
    if ($PSVersionTable.PSVersion.Major -ge 3) { 'Ignore' } 
    else { 'SilentlyContinue' }
)

# Fallback to US English if localization data failed to load
# Do not continue if fallback failed to load too
if (-not $PBLocalizedData)
{
    Import-LocalizedData -BindingVariable PBLocalizedData -BaseDirectory $PSScriptRoot -UICulture 'en-US' -FileName 'Message.psd1' -ErrorVariable loadDefaultLocalizationError -ErrorAction $(
        if ($PSVersionTable.PSVersion.Major -ge 3) { 'Ignore' } 
        else { 'SilentlyContinue' }
    )

    # Continue with error if localization variable is available
    # Otherwise stop
    if ($loadDefaultLocalizationError)
    {
        if (-not $PBLocalizedData)
        {
            $PSCmdlet.ThrowTerminatingError($loadDefaultLocalizationError[0])            
        }
        else
        {
            $loadDefaultLocalizationError[0]
        }
    }
}

# This shouldn't happen. Just in case.
if (-not $PBLocalizedData)
{
    if (-not (Test-Path (Join-Path $PSScriptRoot -ChildPath 'en-US/Message.psd1') -PathType Leaf))
    {
        # This will generate the ItemNotFound exception
        Get-Content (Join-Path $PSScriptRoot -ChildPath 'en-US/Message.psd1') -ErrorVariable localizationFileNotFoundError -ErrorAction $(
            if ($PSVersionTable.PSVersion.Major -ge 3) { 'Ignore' } 
            else { 'SilentlyContinue' }
        )

        $localizationException = $localizationFileNotFoundError[0].Exception
        if (-not $localizationException)
        {
            # This shouldn't happen, but just in case
            $localizationException = "Cannot find path '{0}' because it does not exist." -f (Join-Path $PSScriptRoot -ChildPath 'en-US/Message.psd1')
        }

        $PSCmdlet.ThrowTerminatingError((
            New-Object 'System.Management.Automation.ErrorRecord' -ArgumentList $localizationException, 'DefaultLocalizationFileNotFound', 'ObjectNotFound', $null
        ))        
    }
    else
    {
        $localizationError = New-Object 'System.Management.Automation.ErrorRecord' -ArgumentList ("An error has occured while loading the '{0}' localization data file." -f (Join-Path $PSScriptRoot -ChildPath 'en-US/Message.psd1')), 'InvalidLocalizationFile', 'InvalidData', $null
        $PSCmdlet.ThrowTerminatingError($localizationError)
    }
}


#######################################################################
#  Public module functions
#######################################################################

function Exec
{
    <#
        .SYNOPSIS
            Helper command for executing command-line programs.

        .DESCRIPTION
            Define the script block to call an external program. This command automatically checks the `$lastexitcode` variable to 
            determine whether an error has occcured. 
            
            If an error is detected, the default behavior is to throw an exception and terminate. Alternatively, you may re-execute 
            the script block several times until there are no errors.

        .PARAMETER Command
            The script block to execute. This script block will typically contain the command-line invocation.

        .PARAMETER ErrorMessage
            The error message to display if an exception is thrown.

        .PARAMETER MaxRetry
            Repeat execution of the script block if an error was encountered, up to the number of times defined by this parameter.

        .PARAMETER RetryDelay
            When re-executing the script block, wait for the number of seconds defined by this parameter between each attempt.

        .PARAMETER RetryTriggerErrorPattern
            Re-execute the script block only if the last error message matches the regular expression pattern defined by this 
            parameter.

        .PARAMETER NoWill
            Do not trigger any last wills (if defined) when failing.
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [scriptblock]$Command,

        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = ($PBLocalizedData.Err_BadCommand -f $Command),

        [Parameter(Mandatory = $false)]
        [int]$MaxRetry = 0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, [Int]::MaxValue)]
        [int]$RetryDelay = 1,
        
        [Parameter(Mandatory = $false)]
        [string]$RetryTriggerErrorPattern = $null,

        [Parameter(Mandatory = $false)]
        [switch]$NoWill
    )

    $tryCount = 1

    do 
    {
        try 
        {
            $global:LASTEXITCODE = 0
            & $Command

            if ($LASTEXITCODE -ne 0) 
            {
                Die $ErrorMessage 'ExecError' -NoWill:$NoWill
            }

            break
        }
        catch [Exception]
        {
            if ($tryCount -gt $MaxRetry) 
            {
                Die $_ 'ExecError' -NoWill:$NoWill
            }

            if ($RetryTriggerErrorPattern -ne $null) 
            {
                $isMatch = [RegEx]::IsMatch($_.Exception.Message, $RetryTriggerErrorPattern)

                if ($isMatch -eq $false) 
                { 
                    Die $_ 'ExecError' -NoWill:$NoWill
                }
            }

            Write-Output ("[EXEC] " + ($PBLocalizedData.RetryMessage -f $tryCount, $MaxRetry, $RetryDelay))

            $tryCount++
            Start-Sleep -Seconds $RetryDelay
        }
    } while ($true)
}

function Assert
{
    <#
        .SYNOPSIS
            A helper keyword for "Design by Contract" assertion checking.

        .DESCRIPTION
            Assertions helps to make the code less "noisy" by eliminating the need to write nested 
            `if` statements that are normally required to verify assumptions in the code.

        .PARAMETER Condition
            The boolean condition to evaluate.

        .PARAMETER ErrorMessage
            The error message to display if the `Condition` parameter is false.

        .PARAMETER NoWill
            Do not trigger any last wills (if defined) when failing.

        .EXAMPLE
            assert $false "This always throws an exception"

        .EXAMPLE
            assert (($i % 2) -eq 0) "$i is not an even number"

            DESCRIPTION
            -----------
            This statement may throw an exception if `$i` is not an even number.

            Note: you may need to wrap the condition with paranthesis to prevent a syntax error.
    #>
    
    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        $Condition,

        [Parameter(Position = 2, Mandatory = $true)]
        $ErrorMessage,

        [Parameter()]
        [switch]$NoWill
    )

    if (-not $Condition) 
    {
        Die $ErrorMessage 'AssertConditionFailure' -NoWill:$NoWill
    }
}

function Properties 
{
    <#
        .SYNOPSIS
            Define a script block that contains assignments to variables. These variables will be available to all tasks in the build script.

        .DESCRIPTION
            A build script may use the `properties` keyword to define variables. These variables will be available to all the `tasks` in the build script.

        .PARAMETER Properties
            The script block containing all the variable assignment statements.
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    $BuildEnv.Context.Peek().Properties += $ScriptBlock
}

function Will
{
    <#
        .SYNOPSIS
            Execute a script block whenever an exception is encountered.

        .DESCRIPTION
            Use this keyword to define a last will script block. Last wills are executed 
            just before the build script terminates due to an exception.

        .PARAMETER ScriptBlock
            The last will script block to execute.

        .NOTES
            You can define multiple last wills by using the `will` keyword repeatedly. The wills 
            will be executed in the order that they are defined.
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    $BuildEnv.Context.Peek().Will += $ScriptBlock
}

function PrintTask 
{
    <#
        .SYNOPSIS
            Customize how to render the task name during a build.

        .DESCRIPTION
            Accepts either a string which represents a format string (formats using the -f format operator see "help about_operators"), or 
            a script block that has a single parameter that is the name of the task that will be executed.

        .PARAMETER Format
            A format string or a script block to execute.

        .EXAMPLE
            task default -depends TaskA, TaskB, TaskC

            printTask "-------- {0} --------"

            task TaskA {
              "TaskA is executing"
            }

            task TaskB {
              "TaskB is executing"
            }

            task TaskC {
              "TaskC is executing"
            }

            # The script above produces the following output:
            # 
            # -------- TaskA --------
            # TaskA is executing
            # -------- TaskB --------
            # TaskB is executing
            # -------- TaskC --------
            # TaskC is executing
            #
            # Build Succeeded!

            DESCRIPTION
            -----------
            Use a format string to customize how the task name is printed.

        .EXAMPLE
            printTask {
               param($taskName)

               say "Executing Task: $taskName" -fg blue
            }

            task default -depends TaskA, TaskB, TaskC

            task TaskA {
              "TaskA is executing"
            }

            task TaskB {
              "TaskB is executing"
            }

            task TaskC {
              "TaskC is executing"
            }

            DESCRIPTION
            -----------
            Use a script block to customize how the task name is printed.

            This example uses the script block parameter to the `printTask` keyword to render each 
            task name in the color blue.

            Note: the `$taskName` parameter is arbitrary it could be named anything.
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        $Format
    )

    $BuildEnv.Context.Peek().Setting.TaskNameFormat = $Format
}

function Include 
{
    <#
        .SYNOPSIS
            Include the functions or code of another script file into the current build script's scope.

        .DESCRIPTION
            A build script may declare an "include" keyword which allows you to define a script to be 
            included and added to the scope of the currently running build script. Code from such file 
            will be executed AFTER code from build script.

        .PARAMETER FilePath
            A string containing the path of the script file to include.
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [string]$FilePath
    )

    Assert (Test-Path $FilePath -PathType Leaf) -ErrorMessage ($PBLocalizedData.Err_InvalidIncludePath -f $FilePath)
    $BuildEnv.Context.Peek().Includes.Enqueue((Resolve-Path $FilePath))
}

function TaskSetup 
{
    <#
        .SYNOPSIS
            Defines a script block that will be executed before each task.

        .DESCRIPTION
            Use this keyword to define a script block that will be executed before each
            task in the build script.

        .PARAMETER ScriptBlock
            A script block to execute.
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    $BuildEnv.Context.Peek().TaskSetupScriptBlock = $ScriptBlock
}

function TaskTearDown 
{
    <#
        .SYNOPSIS
            Runs a script block after each task.

        .DESCRIPTION
            Use this keyword to define a script block that will be executed after each
            task in the build script.

        .PARAMETER ScriptBlock
            A scriptblock to execute.
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [scriptblock]$ScriptBlock
    )

    $BuildEnv.Context.Peek().TaskTearDownScriptBlock = $ScriptBlock
}

function EnvPath 
{
    <#
        .SYNOPSIS
            Sets the environmental paths you want to use during build.

        .DESCRIPTION
            This keyword accept a list of directory paths. These paths will be prepended to the existing system paths within the calling context.

        .PARAMETER Path
            A list of paths to prepend to the existing system paths.
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [string[]]$Path
    )

    $BuildEnv.Context.Peek().Setting.EnvPath = $Path
    ConfigureBuildEnvironment
}

function Invoke-Task
{
    <#
        .SYNOPSIS
            Executes another task in the current build script.

        .DESCRIPTION
            This keyword allows you to invoke a task from within another task in the current build script.

        .PARAMETER TaskName
            The name of the task to execute.
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$TaskName
    )

    Assert $TaskName ($PBLocalizedData.Err_InvalidTaskName)

    $taskKey = $TaskName.ToLower()

    if ($CurrentContext.Aliases.Contains($taskKey)) 
    {
        $TaskName = $CurrentContext.Aliases."$taskKey".Name
        $taskKey = $taskName.ToLower()
    }

    $CurrentContext = $BuildEnv.Context.Peek()

    Assert ($CurrentContext.Tasks.Contains($taskKey)) -ErrorMessage ($PBLocalizedData.Err_TaskNameDoesNotExist -f $TaskName)

    if ($CurrentContext.ExecutedTasks.Contains($taskKey)) 
    { 
        return 
    }

    Assert (-not $CurrentContext.CallStack.Contains($taskKey)) -ErrorMessage ($PBLocalizedData.Err_CircularReference -f $TaskName)

    $CurrentContext.CallStack.Push($taskKey)

    $task = $CurrentContext.Tasks.$taskKey

    $preconditionIsValid = & $task.Precondition

    if (-not $preconditionIsValid) 
    {
        WriteColoredOutput ($PBLocalizedData.PreconditionWasFalse -f $TaskName) -ForegroundColor Cyan
    } 
    else 
    {
        if ($taskKey -ne 'default') 
        {
            if ($task.PreAction -or $task.PostAction) 
            {
                Assert ($task.Action -ne $null) -ErrorMessage ($PBLocalizedData.Err_MissingActionParameter -f $TaskName)
            }

            if ($task.Action) 
            {
                try 
                {
                    foreach ($childTask in $task.DependsOn) 
                    {
                        Invoke-Task $childTask
                    }

                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    $CurrentContext.CurrentTaskName = $TaskName

                    & $CurrentContext.TaskSetupScriptBlock

                    if ($task.PreAction) 
                    {
                        & $task.PreAction
                    }

                    if ($CurrentContext.Setting.TaskNameFormat -is [scriptblock]) 
                    {
                        & $currentContext.Setting.TaskNameFormat $TaskName
                    } 
                    else 
                    {
                        WriteColoredOutput ($CurrentContext.Setting.TaskNameFormat -f $TaskName) -ForegroundColor Cyan
                    }

                    foreach ($reqVar in $task.RequiredVariables) 
                    {
                        Assert ((Test-Path "Variable:$reqVar") -and ((Get-Variable $reqVar).Value -ne $null)) -ErrorMessage ($PBLocalizedData.RequiredVarNotSet -f $reqVar, $TaskName)
                    }

                    & $task.Action

                    if ($task.PostAction) 
                    {
                        & $task.PostAction
                    }

                    & $CurrentContext.TaskTearDownScriptBlock
                    $task.Duration = $stopwatch.Elapsed
                } 
                catch 
                {
                    if ($task.ContinueOnError) 
                    {
                        Write-Output $PBLocalizedData.Divider
                        WriteColoredOutput ($PBLocalizedData.ContinueOnError -f $TaskName, $_) -ForegroundColor Yellow
                        Write-Output $PBLocalizedData.Divider
                        $task.Duration = $stopwatch.Elapsed
                    }  
                    else 
                    {
                        WriteColoredOutput ($_ | Out-String) -ForegroundColor Red
                        Die '' 'InvokeTaskError' -NoWill
                    }
                }
            } 
            else 
            {
                # no action was specified but we still execute all the dependencies
                foreach ($childTask in $task.DependsOn) 
                {
                    Invoke-Task $childTask
                }
            }
        } 
        else 
        {
            foreach ($childTask in $task.DependsOn) 
            {
                Invoke-Task $childTask
            }
        }

        Assert (& $task.PostCondition) -ErrorMessage ($PBLocalizedData.PostconditionFailed -f $TaskName)
    }

    $poppedTaskKey = $CurrentContext.CallStack.Pop()
    Assert ($poppedTaskKey -eq $taskKey) -ErrorMessage ($PBLocalizedData.Err_CorruptCallStack -f $taskKey, $poppedTaskKey)

    $CurrentContext.ExecutedTasks.Push($taskKey)
}

function Task
{
    <#
        .SYNOPSIS
            Defines a build task to be executed by Builder.

        .DESCRIPTION
            Use within a build script. This keyword creates a 'task' object that will be used by the Builder engine to execute 
            a build task. 
            
            NOTE: You must defined a task called 'default'.

        .PARAMETER Action
            A script block containing the statements to execute for the task.

        .PARAMETER ContinueOnError
            If this switch parameter is set then the task will not cause the build to fail when an error occurs while running the task.

        .PARAMETER Depends
            An array of task names that this task depends on. These tasks will be executed before the current task is executed.

        .PARAMETER Description
            A description of the task for documentation purposes.

        .PARAMETER Name
            The name of the task.

        .PARAMETER Alias
            An alternative name for the task.
            
        .PARAMETER PostAction
            A script block to be executed after the `Action` scriptblock. 
            
            NOTE: This parameter is silently ignored if the `Action` script block is undefined.

        .PARAMETER Postcondition
            A script block that is executed to determine if the task completed its job correctly.
            
            An exception is thrown if the script block returns `$false`.

        .PARAMETER PreAction
            A scriptblock to be executed before the `Action` script block.
            
            NOTE: This parameter is silently ignored if the `Action` script block is undefined.

        .PARAMETER Precondition
            A script block that is executed to determine whether the task should be is executed or skipped.
            
            This script block should return either `$true` or `$false`.

        .PARAMETER RequiredVariables
            An array of names of variables that must be set to run this task.
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [string]$Name,

        [Parameter(Position = 2, Mandatory = $false)]
        [scriptblock]$Action,

        [Parameter(Mandatory = $false)]
        [scriptblock]$PreAction,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$PostAction,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Precondition = { $true },

        [Parameter(Mandatory = $false)]
        [scriptblock]$Postcondition = { $true },

        [Parameter(Mandatory = $false)]
        [switch]$ContinueOnError,

        [Parameter(Mandatory = $false)]
        [string[]]$Depends = @(),
 
        [Parameter(Mandatory = $false)]
        [string[]]$RequiredVariables = @(),

        [Parameter(Mandatory = $false)]
        [string]$Description,

        [Parameter(Mandatory = $false)]
        [string]$Alias
    )

    if ($Name -eq 'default') 
    {
        Assert (-not $Action) -ErrorMessage ($PBLocalizedData.Err_DefaultTaskCannotHaveAction)
    }

    $newTask = @{
        Name = $Name
        DependsOn = $Depends
        PreAction = $PreAction
        Action = $Action
        PostAction = $PostAction
        Precondition = $Precondition
        Postcondition = $Postcondition
        ContinueOnError = $ContinueOnError
        Description = $Description
        Duration = [System.TimeSpan]::Zero
        RequiredVariables = $RequiredVariables
        Alias = $Alias
    }

    $taskKey = $Name.ToLower()

    $CurrentContext = $BuildEnv.Context.Peek()

    Assert (-not $CurrentContext.Tasks.ContainsKey($taskKey)) -ErrorMessage ($PBLocalizedData.Err_DuplicateTaskName -f $Name)

    $CurrentContext.Tasks.$taskKey = $newTask

    if ($Alias)
    {
        $aliasKey = $Alias.ToLower()

        Assert (-not $CurrentContext.Aliases.ContainsKey($aliasKey)) -ErrorMessage ($PBLocalizedData.Err_DuplicateAliasName -f $Alias)

        $CurrentContext.Aliases.$aliasKey = $newTask
    }
}

function Say
{
    <#
        .SYNOPSIS
            Prints a text output.

        .DESCRIPTION
            Use this command within a build script to print a text output.

        .PARAMETER Message
            The text to print.

        .PARAMETER Divider
            Prints text that represents a dividing line:

            ++++++++

        .PARAMETER NewLine
            Prints an empty line (line break).

        .PARAMETER LineCount
            Use together with the `NewLine` parameter to output multiple line breaks.

        .PARAMETER VerboseLevel
            Defines the verbose level of the output text. If the verbose level defined is higher than 
            the output verbose level setting, the text is ignored (unless the `Force` parameter is used).

        .PARAMETER ForegroundColor
            Specifies the color of the output text. This parameter is silently ignored if the output medium 
            does not support color output.

        .PARAMETER Force
            Ensures that the text is displayed, regardless of its verbose level.
    #>

    [CmdletBinding(DefaultParameterSetName = 'NormalSet')]
    Param(
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'NormalSet')]
        [string]$Message,

        [Parameter(Mandatory = $true, ParameterSetName = 'DividerSet')]
        [switch]$Divider,

        [Parameter(Mandatory = $true, ParameterSetName = 'NewLineSet')]
        [switch]$NewLine,

        [Parameter(Mandatory = $false, ParameterSetName = 'NewLineSet')]
        [ValidateRange(1, [Int]::MaxValue)]
        [int]$LineCount = 1,

        [Parameter(Mandatory = $false, ParameterSetName = 'NormalSet')]
        [ValidateRange(0, 6)]
        [Alias('v')]
        [int]$VerboseLevel = 1,

        [Parameter(Mandatory = $false, ParameterSetName = 'NormalSet')]
        [Alias('fg')]
        [System.ConsoleColor]$ForegroundColor = 'Yellow',

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # configured verbose level = 0 --> no output except errors
    if ((-not $Force) -and ($BuildEnv.Context.Peek().Setting.VerboseLevel -eq 0))
    {
        return
    }

    # this works even if $Host is not around
    $dividerMaxLength = [Math]::Max(70, $Host.UI.RawUI.WindowSize.Width - 1)
 
    if ($PSCmdlet.ParameterSetName -eq 'DividerSet')
    {
        Write-Output ''
        WriteColoredOutput ('+' * $dividerMaxLength) -ForegroundColor Cyan
        Write-Output ''
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'NewLineSet')
    {
        for ($i = 0; $i -lt $LineCount; $i++)
        {
            Write-Output ''
        }
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'NormalSet')
    {
        # suppress output if verbose level > configured verbose level
        if ((-not $Force) -and ($VerboseLevel -gt $BuildEnv.Context.Peek().Setting.VerboseLevel))
        {
            return
        }

        WriteColoredOutput $Message -ForegroundColor $(
            if ($VerboseLevel -eq 0) { 'Red' }
            elseif ($VerboseLevel -eq 1) { $ForegroundColor }
            elseif ($VerboseLevel -eq 2) { 'Green' }
            elseif ($VerboseLevel -eq 3) { 'Magenta' }            
            elseif ($VerboseLevel -eq 4) { 'DarkMagenta' }            
            else { 'Gray' }
        )
    }
}

function Die
{
    <#
        .SYNOPSIS
            Terminates the build script with an error message.

        .DESCRIPTION
            Use this command in a build script to raise a terminating exception.

        .PARAMETER Message
            The error message to display.

        .PARAMETER ErrorCode
            The error code to return.

        .PARAMETER NoWill
            If one or more `will` block is present in the build script, these script blocks will 
            be executed in order before the terminating exception is raised. This parameter 
            overrides this behavior and terminates the build script immediately.

            If no `will` block is defined, this parameter does not have any effect.
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 1)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Message,

        [Parameter(Mandatory = $false, Position = 2)]
        [string]$ErrorCode = 'BuildError',

        [Parameter(Mandatory = $false)]
        [switch]$NoWill
    )

    if ($NoWill)
    {
        # Do no execute wills (if any) and die instantly
    }
    else
    {
        #$currentContext = $BuildEnv.Context.Peek()
        $currentTaskName = $CurrentContext.CallStack.Peek()

        if ($CurrentContext.Will)
        {
            foreach ($willBlock in $CurrentContext.Will)
            {
                . $willBlock $currentTaskName
            }
        }
    }

    if ($Message -eq '') 
    { 
        $Message = $PBLocalizedData.UnknownError 
    }

    $errRecord = New-Object 'System.Management.Automation.ErrorRecord' -ArgumentList $Message, $ErrorCode, 'InvalidOperation', $null
    $PSCmdlet.ThrowTerminatingError($errRecord)
}

function Get-BuildScriptTasks
{
    <#
        .SYNOPSIS
            Returns metadata on tasks.

        .DESCRIPTION
            This command parses the build script specified and returns metadata about all the tasks defined.

        .PARAMETER BuildFile
            The path to the build script to evaluate tasks metadata.
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $false)]
        [string]$BuildFile
    )

    if (-not $BuildFile) 
    {
        $BuildFile = $BuildEnv.DefaultSetting.BuildFileName
    }

    try
    {
        ExecuteInBuildFileScope {
            Param($CurrentContext, $Module)

            return GetTasksFromContext $CurrentContext
        } -BuildFile $BuildFile -Module ($MyInvocation.MyCommand.Module) 
    } 
    finally 
    {
        CleanupEnvironment
    }
}

function Invoke-Builder 
{
    <#
        .SYNOPSIS
            Runs a build script.

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
            `$BuildEnv.BuildSuccess` is `$false`. Calling Builder from 'cmd.exe' with 'build.cmd' will give you that behaviour.



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
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $false)]
        [string]$BuildFile,

        [Parameter(Position = 2, Mandatory = $false)]
        [string[]]$TaskList = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$Docs,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},

        [Parameter(Mandatory = $false)]
        $Properties = @{},
        
        [Parameter(Mandatory = $false)]
        [Alias('Init')]
        [scriptblock]$Initialization = {},

        [Parameter(Mandatory = $false)]
        [switch]$NoLogo,

        [Parameter(Mandatory = $false)]
        [switch]$DetailDocs,

        [Parameter(Mandatory = $false)]
        [switch]$TimeReport
    )

    try 
    {
        if (-not $NoLogo) 
        {
            $logoText = @(
                ('Builder {0}' -f $BuildEnv.Version)
                'Copyright (c) 2018 Lizoc Inc. All rights reserved.'
                ''
            ) -join [Environment]::NewLine
            Write-Output $logoText
        }

        if (-not $BuildFile) 
        {
          $BuildFile = $BuildEnv.DefaultSetting.BuildFileName
        }
        elseif (-not (Test-Path $BuildFile -PathType Leaf) -and 
            (Test-Path $BuildEnv.DefaultSetting.BuildFileName -PathType Leaf)) 
        {
            # if the $config.buildFileName file exists and the given "buildfile" isn 't found assume that the given
            # $buildFile is actually the target Tasks to execute in the $config.buildFileName script.
            $taskList = $BuildFile.Split(', ')
            $BuildFile = $BuildEnv.DefaultSetting.BuildFileName
        }

        ExecuteInBuildFileScope -BuildFile $BuildFile -Module ($MyInvocation.MyCommand.Module) -ScriptBlock {
            Param($CurrentContext, $Module)            

            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            if ($Docs -or $DetailDocs) 
            {
                WriteDocumentation -Detail:$DetailDocs
                return
            }
            
            foreach ($key in $Parameters.Keys) 
            {
                if (Test-Path "Variable:\$key") 
                {
                    Set-Item -Path "Variable:\$key" -Value $Parameters.$key -WhatIf:$false -Confirm:$false | Out-Null
                } 
                else 
                {
                    New-Item -Path "Variable:\$key" -Value $Parameters.$key -WhatIf:$false -Confirm:$false | Out-Null
                }
            }
            
            # The initial dot (.) indicates that variables initialized/modified in the propertyBlock are available in the parent scope.
            foreach ($propertyBlock in $CurrentContext.Properties) 
            {
                . $propertyBlock
            }
            
            foreach ($key in $Properties.Keys) 
            {
                if (Test-Path "Variable:\$key") 
                {
                    Set-Item -Path "Variable:\$key" -Value $Properties.$key -WhatIf:$false -Confirm:$false | Out-Null
                }
            }
            
            # Simple dot sourcing will not work. We have to force the script block into our
            # module's scope in order to initialize variables properly.
            . $Module $Initialization
            
            # Execute the list of tasks or the default task
            if ($taskList) 
            {
                foreach ($task in $taskList) 
                {
                    Invoke-Task $task
                }
            } 
            elseif ($CurrentContext.Tasks.Default) 
            {
                Invoke-Task default
            } 
            else 
            {
                Die $PBLocalizedData.Err_NoDefaultTask 'NoDefaultTask'
            }
            
            $outputMessage = @(
                ''
                $PBLocalizedData.BuildSuccess
                ''
            ) -join [Environment]::NewLine

            WriteColoredOutput $outputMessage -ForegroundColor Green
            
            $stopwatch.Stop()
            if ($TimeReport) 
            {
                WriteTaskTimeSummary $stopwatch.Elapsed
            }
        }

        $BuildEnv.BuildSuccess = $true
    } 
    catch 
    {
        $currentConfig = GetCurrentConfigurationOrDefault
        if ($currentConfig.VerboseError) 
        {
            $errMessage = @(
                ('[{0}] {1}' -f (Get-Date).ToString('hhmm:ss'), $PBLocalizedData.ErrorHeaderText)
                ''
                ('{0}: {1}' -f $PBLocalizedData.ErrorLabel, (ResolveError $_ -Short))
                $PBLocalizedData.Divider
                (ResolveError $_)  # this will have enough blank lines appended
                $PBLocalizedData.Divider
                $PBLocalizedData.VariableLabel
                $PBLocalizedData.Divider
                (Get-Variable -Scope Script | Format-Table | Out-String)
            ) -join [Environment]::NewLine
        } 
        else 
        {
            # ($_ | Out-String) gets error messages with source information included.
            $errMessage = '[{0}] {1}: {2}' -f (Get-Date).ToString('hhmm:ss'), $PBLocalizedData.ErrorLabel, (ResolveError $_ -Short)
        }

        $BuildEnv.BuildSuccess = $false

        # if we are running in a nested scope (i.e. running a build script from within another build script) then we need to re-throw the exception
        # so that the parent script will fail otherwise the parent script will report a successful build
        $inNestedScope = ($BuildEnv.Context.Count -gt 1)
        if ($inNestedScope) 
        {
            Die $_
        } 
        else 
        {
            if (-not $BuildEnv.RunByUnitTest) 
            {
                WriteColoredOutput $errMessage -ForegroundColor Red
            }
        }
    } 
    finally 
    {
        CleanupEnvironment
    }
}


#######################################################################
#  Private module functions
#######################################################################

function WriteColoredOutput 
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Message,

        [Parameter(Mandatory = $true, Position = 2)]
        [System.ConsoleColor]$ForegroundColor
    )

    $currentConfig = GetCurrentConfigurationOrDefault
    if ($currentConfig.ColoredOutput -eq $true) 
    {
        if (($Host.UI -ne $null) -and 
            ($Host.UI.RawUI -ne $null) -and 
            ($Host.UI.RawUI.ForegroundColor -ne $null)) 
        {
            $previousColor = $Host.UI.RawUI.ForegroundColor
            $Host.UI.RawUI.ForegroundColor = $ForegroundColor
        }
    }

    Write-Output $message

    if ($previousColor -ne $null) 
    {
        $Host.UI.RawUI.ForegroundColor = $previousColor
    }
}

function ExecuteInBuildFileScope 
{
    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $true)]
        [string]$BuildFile, 

        [Parameter(Mandatory = $true)]
        $Module
    )
    
    # Execute the build file to set up the tasks and defaults
    Assert (Test-Path $BuildFile -PathType Leaf) -ErrorMessage ($PBLocalizedData.Err_BuildFileNotFound -f $BuildFile)

    $BuildEnv.BuildScriptFile = Get-Item $BuildFile
    $BuildEnv.BuildScriptDir = $BuildEnv.BuildScriptFile.DirectoryName
    $BuildEnv.BuildSuccess = $false

    $BuildEnv.Context.Push(@{
        'TaskSetupScriptBlock' = {}
        'TaskTearDownScriptBlock' = {}
        'ExecutedTasks' = New-Object System.Collections.Stack
        'CallStack' = New-Object System.Collections.Stack
        'OriginalEnvPath' = $env:Path
        'OriginalDirectory' = Get-Location
        'OriginalErrorActionPreference' = $global:ErrorActionPreference
        'Tasks' = @{}
        'Aliases' = @{}
        'Properties' = @()
        'Will' = @()
        'Includes' = New-Object System.Collections.Queue
        'Setting' = CreateConfigurationForNewContext -BuildFile $BuildFile
    })

    LoadConfiguration $BuildEnv.BuildScriptDir

    Set-Location $BuildEnv.BuildScriptDir

    LoadModules

    . $BuildEnv.BuildScriptFile.FullName

    $CurrentContext = $BuildEnv.Context.Peek()

    ConfigureBuildEnvironment

    while ($CurrentContext.Includes.Count -gt 0) 
    {
        $includeFilename = $CurrentContext.Includes.Dequeue()
        . $includeFilename
    }

    & $ScriptBlock $CurrentContext $Module
}

function WriteDocumentation
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [switch]$Detail
    )

    $currentContext = $BuildEnv.Context.Peek()

    if ($currentContext.Tasks.Default) 
    {
        $defaultTaskDependencies = $currentContext.Tasks.Default.DependsOn
    } 
    else
    {
        $defaultTaskDependencies = @()
    }
    
    $docs = GetTasksFromContext $currentContext | where {
        $_.Name -ne 'default'
    } | ForEach-Object {
        $isDefault = $null
        if ($defaultTaskDependencies -contains $_.Name) 
        { 
            $isDefault = $true 
        }
        
        Add-Member -InputObject $_ 'Default' $isDefault -Passthru
    }

    if ($Detail) 
    {
        $docs | sort 'Name' | Format-List -Property Name, Alias, Description, @{
            Label = 'Depends On'
            Expression = { $_.DependsOn -join ', '}
        }, Default
    } 
    else 
    {
        $docs | sort 'Name' | Format-Table -AutoSize -Wrap -Property Name, Alias, @{
            Label = 'Depends On'
            Expression = { $_.DependsOn -join ', ' }
        }, Default, Description
    }
}

function ResolveError
{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        $ErrorRecord = $Error[0],

        [Parameter(Mandatory = $false)]
        [switch]$Short
    )

    Process 
    {
        if ($_ -eq $null) 
        { 
            $_ = $ErrorRecord 
        }
        $ex = $_.Exception

        if (-not $Short) 
        {
            $errMessage = @(
                ''
                'ErrorRecord:{0}ErrorRecord.InvocationInfo:{1}Exception:'
                '{2}'
                ''
            ) -join [Environment]::NewLine

            $formattedErrRecord = $_ | Format-List * -Force | Out-String
            $formattedInvocationInfo = $_.InvocationInfo | Format-List * -Force | Out-String
            $formattedException = ''

            $i = 0
            while ($ex -ne $null) 
            {
                $i++
                $formattedException += @(
                    ("$i" * 70)
                    ($ex | Format-List * -Force | Out-String)
                    '' 
                ) -join [Environment]::NewLine

                $ex = $ex | SelectObjectWithDefault -Name 'InnerException' -Value $null
            }

            return $errMessage -f $formattedErrRecord, $formattedInvocationInfo, $formattedException
        }

        $lastException = @()
        while ($ex -ne $null) 
        {
            $lastMessage = $ex | SelectObjectWithDefault -Name 'Message' -Value ''
            $lastException += ($lastMessage -replace [Environment]::NewLine, '')

            if ($ex -is [Data.SqlClient.SqlException]) 
            {
                $lastException = '(Line [{0}] Procedure [{1}] Class [{2}] Number [{3}] State [{4}])' -f $ex.LineNumber, $ex.Procedure, $ex.Class, $ex.Number, $ex.State
            }
            $ex = $ex | SelectObjectWithDefault -Name 'InnerException' -Value $null
        }
        $shortException = $lastException -join ' --> '

        $header = $null
        $current = $_
        $header = (($_.InvocationInfo | SelectObjectWithDefault -Name 'PositionMessage' -Value '') -replace [Environment]::NewLine, ' '),
            ($_ | SelectObjectWithDefault -Name 'Message' -Value ''),
            ($_ | SelectObjectWithDefault -Name 'Exception' -Value '') | where { -not [String]::IsNullOrEmpty($_) } | select -First 1

        $delimiter = ''
        if ((-not [String]::IsNullOrEmpty($header)) -and
            (-not [String]::IsNullOrEmpty($shortException)))
        { 
            $delimiter = ' [<<==>>] ' 
        }

        return '{0}{1}Exception: {2}' -f $header, $delimiter, $shortException
    }
}

function LoadModules 
{
    $currentConfig = $BuildEnv.Context.Peek().Setting
    if ($currentConfig.Modules) 
    {
        $scope = $currentConfig.ModuleScope
        $global = [string]::Equals($scope, 'global', [StringComparison]::CurrentCultureIgnoreCase)

        $currentConfig.Modules | ForEach-Object {
            Resolve-Path $_ | ForEach-Object {
                # "Loading module: $_"
                $module = Import-Module $_ -PassThru -DisableNameChecking -Global:$global -Force

                if (-not $module) 
                {
                    Die ($PBLocalizedData.Err_LoadingModule -f $_.Name) 'LoadModuleError'
                }
            }
        }

        Write-Output ''
    }
}

function LoadConfiguration 
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = $PSScriptRoot
    )

    $pbConfigFilePath = Join-Path $ConfigPath -ChildPath "Builder-Config.ps1"

    if (Test-Path $pbConfigFilePath -PathType Leaf) 
    {
        try 
        {
            $config = GetCurrentConfigurationOrDefault
            . $pbConfigFilePath
        } 
        catch 
        {
            Die ($PBLocalizedData.Err_LoadConfig + ': ' + $_) 'LoadConfigError'
        }
    }
}

function GetCurrentConfigurationOrDefault() 
{
    if ($BuildEnv.Context.Count -gt 0) 
    {
        $BuildEnv.Context.Peek().Setting
    } 
    else 
    {
        $BuildEnv.DefaultSetting
    }
}

function CreateConfigurationForNewContext 
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $false)]
        [string]$BuildFile
    )

    $previousConfig = GetCurrentConfigurationOrDefault

    $config = New-Object PSObject -Property @{
        BuildFileName = $previousConfig.BuildFileName
        EnvPath = $previousConfig.EnvPath
        TaskNameFormat = $previousConfig.TaskNameFormat
        VerboseError = $previousConfig.VerboseError
        ColoredOutput = $previousConfig.ColoredOutput
        Modules = $previousConfig.Modules
        ModuleScope = $previousConfig.ModuleScope
        VerboseLevel = $previousConfig.VerboseLevel
    }

    if ($BuildFile) 
    {
        $config.BuildFileName = $BuildFile
    }

    $config
}

function ConfigureBuildEnvironment 
{
    $envPathDirs = @($BuildEnv.Context.Peek().Setting.EnvPath) | where { ($_ -ne $null) -and ($_ -ne '') }

    if ($envPathDirs)
    {
        $envPathDirs | ForEach-Object { 
            Assert (Test-Path $_ -PathType Container) -ErrorMessage ($PBLocalizedData.Err_EnvPathDirNotFound -f $_)
        }
        
        $newEnvPath = @($env:Path.Split([System.IO.Path]::PathSeparator), $envPathDirs) | select -Unique

        $env:Path = $newEnvPath -join [System.IO.Path]::PathSeparator
    }

    # if any error occurs in a PS function then "stop" processing immediately
    # this does not effect any external programs that return a non-zero exit code
    $global:ErrorActionPreference = 'Stop'
}

function CleanupEnvironment 
{
    if ($BuildEnv.Context.Count -gt 0) 
    {
        $currentContext = $BuildEnv.Context.Peek()
        $env:Path = $currentContext.OriginalEnvPath
        Set-Location $currentContext.OriginalDirectory
        $global:ErrorActionPreference = $currentContext.OriginalErrorActionPreference
        [void]$BuildEnv.Context.Pop()
    }
}

function SelectObjectWithDefault
{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $true)]
        [psobject]$InputObject,

        [Parameter(ValueFromPipeline = $false)]
        [string]$Name,

        [Parameter(ValueFromPipeline = $false)]
        $Value
    )

    Process 
    {
        if ($_ -eq $null) 
        { 
            $Value 
        }
        elseif ($_ | Get-Member -Name $Name) 
        {
            $_."$Name"
        }
        elseif (($_ -is [Hashtable]) -and ($_.Keys -contains $Name)) 
        {
            $_."$Name"
        }
        else 
        { 
            $Value 
        }
    }
}

function GetTasksFromContext 
{
    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        $CurrentContext
    )

    $CurrentContext.Tasks.Keys | ForEach-Object {
        $task = $CurrentContext.Tasks."$_"

        New-Object PSObject -Property @{
            Name = $task.Name
            Alias = $task.Alias
            Description = $task.Description
            DependsOn = $task.DependsOn
        }
    }
}

function WriteTaskTimeSummary 
{
    [CmdletBinding()]
    Param(
        [Parameter(Position = 1, Mandatory = $true)]
        $Duration
    )

    if ($BuildEnv.Context.Count -gt 0) 
    {
        Write-Output $PBLocalizedData.Divider
        Write-Output $PBLocalizedData.BuildTimeReportTitle
        Write-Output $PBLocalizedData.Divider

        $list = @()
        $currentContext = $BuildEnv.Context.Peek()
        while ($currentContext.ExecutedTasks.Count -gt 0) 
        {
            $taskKey = $currentContext.ExecutedTasks.Pop()
            $task = $currentContext.Tasks.$taskKey
            if ($taskKey -eq 'default') 
            {
                continue
            }
            $list += New-Object PSObject -Property @{
                Name = $task.Name
                Duration = $task.Duration
            }
        }
        [Array]::Reverse($list)
        $list += New-Object PSObject -Property @{
            Name = 'Total'
            Duration = $Duration
        }

        # using "out-string | where-object" to filter out the blank line that format-table prepends
        $list | Format-Table -AutoSize -Property Name, Duration | Out-String -Stream | where { $_ }
    }
}


#######################################################################
#  Main
#######################################################################

$scriptDir = Split-Path $MyInvocation.MyCommand.Path
$manifestPath = Join-Path $scriptDir -ChildPath 'Builder.psd1'
$manifest = Test-ModuleManifest -Path $manifestPath -WarningAction $(
    if ($PSVersionTable.PSVersion.Major -ge 3) { 'Ignore' } 
    else { 'SilentlyContinue' }
)

$script:BuildEnv = @{}

$BuildEnv.Version = $manifest.Version.ToString()
$BuildEnv.Context = New-Object System.Collections.Stack   # holds onto the current state of all variables
$BuildEnv.RunByUnitTest = $false                          # indicates that build is being run by internal unit tester

# contains default configuration, can be overriden in Builder-Config.ps1 in directory with Builder.psm1 or in directory with current build script
$BuildEnv.DefaultSetting = New-Object PSObject -Property @{
    BuildFileName = 'default.ps1'
    EnvPath = $null
    TaskNameFormat = $PBLocalizedData.DefaultTaskNameFormat
    VerboseError = $false
    ColoredOutput = $true
    Modules = $null
    ModuleScope = ''
    VerboseLevel = 2
} 

$BuildEnv.BuildSuccess = $false     # indicates that the current build was successful
$BuildEnv.BuildScriptFile = $null   # contains a System.IO.FileInfo for the current build script
$BuildEnv.BuildScriptDir = ''       # contains a string with fully-qualified path to current build script
$BuildEnv.ModulePath = $PSScriptRoot

LoadConfiguration

Export-ModuleMember -Function @(
    'Invoke-Builder', 'Invoke-Task', 'Get-BuildScriptTasks',
    'Task', 'PrintTask', 'TaskSetup', 'TaskTearDown', 
    'Properties', 'Include', 'Will', 'EnvPath', 'Assert', 'Exec', 'Say', 'Die'
) -Variable @(
    'BuildEnv'
)
