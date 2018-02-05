will {
    say 'I am a will in a sub build script'
}

task default -depends SubFinish

task SubFinish {
	say 'I am a sub build script'
	die 'I died on purpose to trigger a sub will'
	say ('Something went wrong in {0} if you can see me!' -f 'SubFinish')
}
