function Get-DotNetPath
{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory, Position = 1)]
        [string]$Framework,

        [Parameter()]
        [switch]$Force
    )

    # bitnessPart may be null
    if ($Framework -cmatch '^((?:\d+\.\d+)(?:\.\d+){0,1})(x86|x64){0,1}$') 
    {
        $versionPart = $matches[1]
        $bitnessPart = $matches[2]
    } 
    else 
    {
        die ('Invalid framework: {0}' -f $Framework) 'FrameworkFormatError'
    }

    $versions = $null
    $buildToolsVersions = $null

    # buildToolsVersions may be null
    switch ($versionPart) 
    {
        '1.0' { $versions = @('v1.0.3705') }
        '1.1' { $versions = @('v1.1.4322') }
        '2.0' { $versions = @('v2.0.50727') }
        '3.0' { $versions = @('v2.0.50727') }
        '3.5' { $versions = @('v3.5', 'v2.0.50727') }
        '4.0' { $versions = @('v4.0.30319') }

        {($_ -eq '4.5.1') -or ($_ -eq '4.5.2')} 
        {
            $versions = @('v4.0.30319')
            $buildToolsVersions = @('14.0', '12.0')
        }

        {($_ -eq '4.6') -or ($_ -eq '4.6.1')} 
        {
            $versions = @('v4.0.30319')
            $buildToolsVersions = @('14.0')
        }

        default 
        {
            die ("Unknown or unsupported framework version '{0}': {1}" -f $versionPart, $Framework) 'UnsupportedFramework'
        }
    }

    $bitness = 'Framework'
    if (($versionPart -ne '1.0') -and ($versionPart -ne '1.1'))
    {
        switch ($bitnessPart) 
        {
            'x86' 
            {
                $bitness = 'Framework'
                $buildToolsKey = 'MSBuildToolsPath32'
            }

            'x64' 
            {
                $bitness = 'Framework64'
                $buildToolsKey = 'MSBuildToolsPath'
            }

            { [string]::IsNullOrEmpty($_) } 
            {
                $ptrSize = [System.IntPtr]::Size
                switch ($ptrSize) 
                {
                    4 
                    {
                        $bitness = 'Framework'
                        $buildToolsKey = 'MSBuildToolsPath32'
                    }

                    8 
                    {
                        $bitness = 'Framework64'
                        $buildToolsKey = 'MSBuildToolsPath'
                    }

                    default 
                    {
                        Die ('Unknown system pointer size: {0}' -f $ptrSize) 'UnsupportedFrameworkPlatform'
                    }
                }
            }

            default 
            {
                Die ("Unknown operating system bit size '{0}': {1}" -f $bitnessPart, $Framework) 'UnsupportedFrameworkPlatform'
            }
        }
    }

    $frameworkDirs = @()
    if ($buildToolsVersions -ne $null) 
    {
        foreach ($ver in $buildToolsVersions) 
        {
            if (Test-Path "HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\$ver") 
            {
                $frameworkDirs += (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\MSBuild\ToolsVersions\$ver" -Name $buildToolsKey).$buildToolsKey
            }
        }
    }

    $frameworkDirs = $frameworkDirs + @(
        $versions | ForEach-Object { 
            Join-Path $env:windir -ChildPath "Microsoft.NET/$bitness/$_/" 
        }
    )

    for ($i = 0; $i -lt $frameworkDirs.Count; $i++) 
    {
        $dir = $frameworkDirs[$i]
        if ($dir -match '\$\(Registry:HKEY_LOCAL_MACHINE(.*?)@(.*)\)') 
        {
            $key = "HKLM:" + $matches[1]
            $name = $matches[2]
            $dir = (Get-ItemProperty -Path $key -Name $name)."$name"
            $frameworkDirs[$i] = $dir
        }
    }

    if (-not $Force)
    {
	    $frameworkDirs | ForEach-Object { 
	        Assert (Test-Path $_ -PathType Container) -ErrorMessage ('Framework was not installed: {0}' -f $_)
	    }
    }

    $frameworkDirs
}

envpath (Get-DotNetPath '4.0' -Force)

task default -depends EnvPathFunction 

task EnvPathFunction  {
	$msBuildVersion = msbuild /version
 	say $msBuildVersion[0].ToLowerInvariant()
	assert ($msBuildVersion[0].ToLowerInvariant().StartsWith("microsoft (r) build engine version")) "Failed to run msbuild: $msBuildVersion"
}
