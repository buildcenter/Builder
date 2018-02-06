envpath (Join-Path $env:ProgramFiles -ChildPath 'Windows NT\Accessories')

task default -depends ShowWordpad

task ShowWordpad {
  wordpad.exe
}