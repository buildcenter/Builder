task default -depends TaskA

task TaskA -depends TaskB {
	"Task - A"
}

task TaskB -depends TaskC -ContinueOnError {
	"Task - B"
	throw "I failed on purpose!"
}

task TaskC -depends TaskD -ContinueOnError {
	"Task - C"
	die "I died on purpose!"
}

task TaskD {
	"Task - D"
}
