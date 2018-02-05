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
