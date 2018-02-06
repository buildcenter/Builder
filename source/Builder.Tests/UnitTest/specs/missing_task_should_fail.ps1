task default -depends Test

task Test -depends Compile, Clean { 
  say "Running test"
}
