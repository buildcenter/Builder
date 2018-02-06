task default -depends Compile, Test

task Compile -depends CompileSolutionA, CompileSolutionB

task Test -depends UnitTests, IntegrationTests

task CompileSolutionA -description 'Compiles solution A' {}

task CompileSolutionB {}

task UnitTests -alias 'ut' {}

task IntegrationTests {}
