# Localized	2/1/2018 2:06 PM (GMT)	410:2.92.0533	Message.psd1
# Builder PBLocalizedData.zh-CN

ConvertFrom-StringData @'

# ---- [ Localized Data ] ---------------------------------------------

Err_InvalidTaskName = 任务的名称不得为“null”或者空字符串。
Err_TaskNameDoesNotExist = 任务不存在：{0}
Err_CircularReference = 任务存在循环引用：{0}
Err_MissingActionParameter = 使用“PreAction”或“PostAction”参数时必须同时指定“Action”参数：{0}
Err_CorruptCallStack = 调用堆栈已损坏（预值“{0}”，但实值为“{1}”）。
Err_EnvPathDirNotFound = 指定的环境路径不存在，或者不是文件系统的文件夹：{0}
Err_BadCommand = 执行命令时发生了错误：{0}
Err_DefaultTaskCannotHaveAction = 任务“default”不得定义“Action”。
Er_DuplicateTaskName = 任务已定义：{0}
Err_DuplicateAliasName = 别名已定义：{0}
Err_InvalidIncludePath = 未找到文件，无法插入文件内容：{0}
Err_BuildFileNotFound = 无法找到搭建文件：{0}
Err_NoDefaultTask = 需要一个名为“default”的任务。
Err_LoadingModule = 加载模块时发生了错误：{0}
Err_LoadConfig = 加载搭建设置时发生了错误：{0}
RequiredVarNotSet = 执行任务“{1}”前必须设定变量“{0}”。
PostconditionFailed = 任务的事后条件判断为失败：{0}
PreconditionWasFalse = 前提条件为“false”，任务将不被执行：{0}
ContinueOnError = 执行任务“{0}”时发生了错误：{1}
BuildSuccess = 搭建成功！
RetryMessage = 第{0}/{1}次尝试失败，在{2}秒后再次尝试...
BuildTimeReportTitle = 搭建用时报告
Divider = ----------------------------------------------------------------------
ErrorHeaderText = 发生了一个错误。详情如下：
ErrorLabel = 错误
VariableLabel = 脚本变量：
DefaultTaskNameFormat = 执行{0}
UnknownError = 发生了一个未知的错误。

# ---- [ /Localized Data ] --------------------------------------------
'@
