will {
    say 'I get executed when a task dies with a will!'
}

will {
	say ('You can have multiple wills that gets executed in order. Caller is "{0}".' -f $args[0])
}

task default -depends Finish

task Starter {
	say 'I gets executed.'
}

task Compile -depends Starter -ContinueOnError {
	die 'I will trigger the wills and continue on to the next task.'
	say ('Something went wrong in {0} if you can see me!' -f 'Compile')
}

task Pack -depends Compile {
	die 'This failure should trigger the wills and stop anything further.'
	say ('Something went wrong in {0} if you can see me!' -f 'Pack')
}

task Finish -depends Pack {
	say ('Something went wrong in {0} if you can see me!' -f 'Finish')
}
