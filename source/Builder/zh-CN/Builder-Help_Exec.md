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
