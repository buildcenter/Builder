properties {
  $testMessage = 'Executed Test!'
  $compileMessage = 'Executed Compile!'
  $cleanMessage = 'Executed Clean!'
}

task default -depends Test

task Test -depends Compile, Clean { 
  $testMessage
}

task Compile -depends Clean { 
  $compileMessage
}

task Clean { 
  $cleanMessage
}

task ? -description "Helper to display task info" {
	# To trigger this task:
	#   .\build.cmd ..\Builder.Tests\Samples\default.ps1 ?
	WriteDocumentation
}
