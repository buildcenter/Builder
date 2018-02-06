task default -depends A, B

task A {
}

task B {
	"inside task B before calling task C"
	Invoke-Task C
	"inside task B after calling task C"
}

task C {
	"i am task c"
}