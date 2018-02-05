What is Builder
===============
A general purpose build tool coordination system that runs in PowerShell.

You can use Builder to handle any compilation toolchain. If your build process can be 
expressed as a list of interdepending steps, you can write it as a builder script.



Getting Started
---------------
Builder uses a simple DSL makes it easier to express dependencies between tasks. Here is an 
example to show what I mean:

```
task default -depends finish

task finish -depends foo, bar {
    Write-Host 'My work here is done!'
}

task foo -depends bar {
    Write-Host 'I am foo'
}

task bar {
    Write-Host 'I am bar'
}
```

Output will look like this:

```
I am bar
I am foo
My work here is done!
```

Now that feels a lot more specialized (read shorter) than working in bash, right? It is so dead simple 
that you can [write your own build scripts](Docs/README.md) in minutes.



Installation
------------
The best option (if you are on Windows 10 or similar) is to use the 'Install-Package' command from 
PowerShell.

## Using 'Install-Package'

1. `Install-Package Builder`

2. `ipmo Builder`

3. `Get-Help about_Builder`, or `Get-Command -Module Builder`.

4. YOUR WORK HERE IS DONE.


## Manual portable installation

If that doesn't work for you, try installing it manually.

1. Download the latest release from [here](https://get.lizoc.com/builder.zip). You can 
   [click here](http://www.github.com/buildcenter/Builder/releases) for all available 
   releases.

2. Copy the 'Builder' folder in archive to Documents\WindowsPowerShell\Modules.
   So you get 'Documents\WindowsPowerShell\Modules\Builder\Builder.psd1', ...

3. Make sure your PowerShell policy allows running scripts (in an escalated terminal, type in: 
   `Set-ExecutionPolicy Unrestricted`).

4. The above steps can be automated:

```
wget https://get.lizoc.com/builder.zip -OutFile $env:TEMP\builder.zip
Expand-Archive $env:TEMP\builder.zip $env:PSModulePath.Split(';')[0]
del $env:TEMP\builder.zip
ipmo Builder
```



Examples and Unit Test
----------------------
Examples and unit tests are in a separate package:

```
Install-Package Builder.Tests
```

-or-

```
wget https://get.lizoc.com/builder.tests.zip -OutFile $env:TEMP\builder.tests.zip
Expand-Archive $env:TEMP\builder.tests.zip $env:PSModulePath.Split(';')[0]
```



Release Notes
-------------
You can find all the information about each release of Builder in 
[the releases section](http://www.github.com/buildcenter/Builder/releases).



How To Contribute
-----------------
Anyone can fork the main repository and submit patches. If you have found a bug, visit the 
[issues list](http://www.github.com/buildcenter/Builder/issues).



License
-----------------
The Builder project is released under the [MIT license](./LICENSE.txt).



Relationship with psake
-----------------------
This project is a hard fork of [psake](http://www.github.com/psake/psake) (*release version 4.5.0*) in 
2015. While we really liked psake, it is specifically designed for building .NET projects, and not 
directly applicable to lots of our needs.

Builder has been developed independently of psake since the original hard fork. There is currently 
no plan on submitting any pull request to the psake project authors.

See the [third party license](./THIRD-PARTY-LICENSE.txt) for all third party licensing information.
