task default -depends CallExternalWithError

task CallExternalWithError {
  exec { cmd.exe /c "exit 1" }
}