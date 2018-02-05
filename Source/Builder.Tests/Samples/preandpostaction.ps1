task default -depends Test

task Test -depends Compile, Clean -preaction { "Pre-Test" } -action { 
  "Test"
} -postaction { "Post-Test" }

task Compile -depends Clean { 
  "Compile"
}

task Clean { 
  "Clean"
}