Include
=======
Use `include` to access functions that are in another script file.

Let's say this is the content of `build_utils.ps1`
```powershell
function foo {
	write-host hi
}

function bar {
	write-host bye
}
```

You can use `foo` and `bar` in your build script:

```powershell
include ".\build_utils.ps1"

task default -depends Compile

Task Compile {
	foo
	bar
}
```

*Tips*: You can have multiple `include` statements inside your build script.
