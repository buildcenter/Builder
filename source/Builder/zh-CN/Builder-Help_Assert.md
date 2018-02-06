.SYNOPSIS
    一个帮助实施“合同式设计”的断言检测帮助工具。

.DESCRIPTION
    在核实前提假设时，利用断言取代代码中的多层`if`声明，可以使代码更加精简易懂。

.PARAMETER Condition
    需要判断的布尔条件。若判断为“false”则引发错误提示。

.PARAMETER ErrorMessage
    自定义`Condition`参数判断为“false”时报错的文字内容。

.PARAMETER NoWill
    报错时不要引发任何遗嘱（如有）。

.EXAMPLE
    assert $false "This always throws an exception"

.EXAMPLE
    assert (($i % 2) -eq 0) "$i is not an even number"

    DESCRIPTION
    -----------
    如果`$i`不是偶数，这个声明就会引发错误提示。

    注：为避免语法错误，你可能需要将条件用括弧包起来。
