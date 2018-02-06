task default -depends CallExecutable

task CallExecutable {
	# this should return last exit code 1
	#	$global:LASTEXITCODE

	# These examples below will result in a failed build:
	#
	#     exec { cmd.exe /c "exit 1" }
	#     cmd.exe /c "exit 1" 2>&1
	#
	# But this will not:
	#
	cmd.exe /c "exit 1"
}