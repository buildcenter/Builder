.SYNOPSIS
    终止搭建脚本的执行，并引发错误提示。

.DESCRIPTION
    在搭建脚本里使用这个命令，可以引发错误提示，并终止执行脚本。

.PARAMETER Message
    报错的文字内容。

.PARAMETER ErrorCode
    报错的错误代码。

.PARAMETER NoWill
    如果搭建脚本中定义了一个或多个`will`脚本块，这些脚本块将按顺序执行，全部执行完毕后才会引发错误提示并终止运行。你可以使用这个参数覆盖上述行为，以
    实现立即终止脚本的执行。

    如果脚本中未定义任何`will`脚本块，该参数则不会产生任何影响。