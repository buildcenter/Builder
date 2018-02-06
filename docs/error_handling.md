Error Handling
==============
By default, any error encountered inside a `task` block will terminate your build process (or when an external program returns non-zero exit code).

You can override this behavior using the `ContinueOnError` parameter, in which case it will continue on to the next available task.

Here's an example:

```powershell
task default -depends TaskA

task TaskA -depends TaskB {
	"Task A ran!"
}

task TaskB -depends TaskC -ContinueOnError {
	"Task B ran!"
	die "I failed on purpose!"
}

task TaskC {
	"Task C ran!"
}
```

When you run the above build script, you should get this output:

```
Executing task: TaskC
Task C ran!
Executing task: TaskB
Task B ran!
-----------------------------------------------------------------
Error in Task [TaskB] I failed on purpose!
-----------------------------------------------------------------
Executing task: TaskA
Task A ran!

Build Succeeded!
```


Last wills
----------
Wills are akin to the `finally` part of a `try catch finally` block. It is a script block that executes whenever an error occurs, just before the task or build script "dies".

Let's modify the example above:

```powershell
will {
	say ("Task '{0}' is about to die..." -f $1)
}

task default -depends TaskA

task TaskA -depends TaskB {
	"Task A ran!"
}

task TaskB -depends TaskC -ContinueOnError {
	"Task B ran!"
	die "I failed on purpose!"
}

task TaskC {
	"Task C ran!"
}
```

When you run the above build script, you should get this output:

```
Executing task: TaskC
Task C ran!
Executing task: TaskB
Task B ran!
Task 'TaskB' is about to die...
-----------------------------------------------------------------
Error in Task [TaskB] I failed on purpose!
-----------------------------------------------------------------
Executing task: TaskA
Task A ran!

Build Succeeded!
```

You can have multiple will blocks, in which case they will execute in the order they appear whenever an exception occurs.

*Tips*: you can let a task die without executing the will. Just use the `-NoWill` parameter.
