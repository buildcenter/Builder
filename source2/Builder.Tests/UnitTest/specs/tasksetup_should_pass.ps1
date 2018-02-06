taskSetup {
	"executing task setup"
}

task default -depends Compile, Test, Deploy

task Compile {
	"Compiling"
}

task Test -depends Compile {
	"Testing"
}

task Deploy -depends Test {
	"Deploying"
}