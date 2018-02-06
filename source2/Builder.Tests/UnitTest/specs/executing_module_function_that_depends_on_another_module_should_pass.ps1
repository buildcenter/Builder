task default -depends test

task test {
    Invoke-Builder modules\default.ps1
}