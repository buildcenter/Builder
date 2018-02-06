Conditional tasks
=================
You can add preconditions to your tasks. A task that does not satisfy its precondition will be skipped.

```powershell
task default -depends A, B, C

task A {
  "TaskA"
}

task B -precondition { $false } {
  "TaskB"
}

task C -precondition { $true } {
  "TaskC"
}
```

Here task A and C will run, but not B.

