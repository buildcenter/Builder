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
