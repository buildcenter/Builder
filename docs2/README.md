Getting started
===============
Builder is a human friendly build automation solution. If you are looking for better control over your build process beyond what your IDE churns out, but don't want to deal with the XML drama, this is just the tool!

Nothing beats an example:

*Your regular MSBuild csproject*

```xml
<?xml version="1.0" encoding="utf-16"?>
<Project Sdk="Microsoft.NET.Sdk">
	<Target Name="Compile">
		<Message Text="I am compiling!" />  
	</Target>  
	<Target Name="Finish" DependsOnTargets="Compile">
		<Message Text="All done!" />  
	</Target>  
</Project
```

*turns into this...*

```powershell
task default -depends Finish

task Compile {
	say 'I am compiling!'
}

task Finish -depends Compile {
	say 'All done!'
}
```


Basics
------
Similar to build toolchains such as Ant, NAnt, Rake or MSBuild, Builder works by automatically resolving the run order of interdependent scripts we call "tasks". 

Take the example above:
- default depends on Finish
- Compile depends on nothing
- Finish depends on Compile

Builder is hardcoded to look for the 'default' task. It will resolve the build order as follows:
1. Compile
2. Finish


So why Builder?
------------------
Existing toolchains work great, except when you open up the make file with a text editor and sees the angular brackets. Sure, a good IDE will take most of the pain away, but you lose flexibility and fine control.

Builder offers a domain specific language (DSL) specifically designed for build jobs. It also brings in the full power of Powershell and .NET, which is a step up from writing bash scripts and make files. Don't think that this is a Windows/.NET ecosystem thing though, because Builder itself is totally toolchain neutral, so it doesn't really matter what your build platform or programming language is!


Show me the money
-----------------
There isn't a ton of API/documentation, because this is the kind of stuff that is best learnt by examples.

Just look through the build scripts under (../Source/Builder.Tests/Samples)[Source/Builder.Tests/Samples]. It doesn't take more than 15 minutes to become a build automation wizard :D


