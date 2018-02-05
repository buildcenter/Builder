.SYNOPSIS
    输出自定义的文本。

.DESCRIPTION
    在搭建脚本中，可以使用该命令输出文本。

.PARAMETER Message
    需输出的文本。

.PARAMETER Divider
    输出一段代表分隔符的文字：

    ++++++++

.PARAMETER NewLine
    输出一个空行（换行符）。

.PARAMETER LineCount
    与`NewLine`参数同时使用，可以输出多个空行。

.PARAMETER VerboseLevel
    定义输出文本的详细层级。如果层级高于设定的详细层级，则不会输出该文本（除非同时使用`Force`参数）。

.PARAMETER ForegroundColor
    设定输出文本的颜色。如果输出设备不支持颜色，这个参数不会产生任何影响。

.PARAMETER Force
    无论详细层级，保证文本必须输出。
