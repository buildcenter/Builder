Examples and Unit Test
======================
This package contains the unit test for module `Builder`.

It also has some sample build scripts under 'Samples/' to help you get started.



Installation
============
This is not a module package, so just download to your private home folder to play with:

```
wget https://get.lizoc.com/builder.tests.zip -OutFile $env:TEMP\builder.tests.zip
Expand-Archive $env:TEMP\builder.tests.zip $env:USERPROFILE\pbtests
del $env:TEMP\builder.tests.zip
# run unit tests
ipmo Builder
. $env:USERPROFILE\pbtests\AllTests.ps1
# also check out 'samples/' for some sample scripts.
```
