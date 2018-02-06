Param(
	[Parameter()]
	[switch]$Publish
)

# Hardcoded settings. Do not touch!!!
# The repo must be 1 level above this build script.
$toolsDir = $PSScriptRoot
$repoDir = Resolve-Path (Join-Path $toolsDir -ChildPath '..') | select -expand Path
$repoName = Split-Path $repoDir -Leaf

# Special directorys. Make sure folders are in lower case for compat with Linux systems.
$docsDir = Join-Path $repoDir -ChildPath 'docs'
$sourceDir = Join-Path $repoDir -ChildPath 'source'
$workingDir = Join-Path $repoDir -ChildPath 'working'
$releaseDir = Join-Path $repoDir -ChildPath 'releases'
$credDir = Join-Path $repoDir -ChildPath 'credentials'
$packageCommonFiles = @(
	"icon.png"
	"LICENSE.txt"
	"README.md"
	"THIRD-PARTY-LICENSE.txt"
)

dir (Join-Path $toolsDir -ChildPath '*.psm1') | ForEach-Object {
    Write-Output ("Importing add-on module: Tools/{0}" -f $_.Name)
    ipmo $_.FullName -Force
}

# create release and working dir
@($releaseDir, $workingDir) | ForEach-Object {
    if (-not (Test-Path $_))
    {
        Write-Output ('Creating directory: {0}' -f $_.Substring($repoDir.Length))
        md $_ -Force | Out-Null
    }
    else
    {
        if (Test-Path $_ -PathType Leaf)
        {
            throw ("You need to remove the file '{0}'" -f $_)
        }
    }
}

# copy all from source to working folder
Write-Output 'Mirror source to working folder'
Invoke-Robocopy -SourcePath $sourceDir -DestinationPath $workingDir -Mirror -Verbose

Write-Output 'Preparing templating data'
$tmplData = ConvertFrom-Json (Get-Content -Path (Join-Path $toolsDir -ChildPath 'projectInfo.json') -Raw)
$tmplDataHash = @{}
$tmplData | Get-Member -MemberType NoteProperty | select -expand Name | ForEach-Object {
    $tmplDataHash."$_" = $tmplData."$_"
}
# dynamic vars
$tmplDataHash.repoDir = $repoDir

Write-Output 'Importing template language helper functions'
[Management.Automation.Language.Parser]::ParseInput((Get-Content -Path (Join-Path $toolsDir -ChildPath 'template_helpers.ps1') -Raw), [ref]$null, [ref]$null).FindAll({
    param($ast)
    $ast -is [System.Management.Automation.Language.FunctionDefinitionAst]
}, $false) | ForEach-Object {
    $tmplDataHash."$($_.Name)" = [scriptblock]::Create($_.Body.Extent.Text)
}

Write-Output 'Generating from templates'
dir (Join-Path $workingDir -ChildPath '*.pstmpl') -Recurse -File | ForEach-Object {
    $tmplFilePath = $_.FullName
    $tmplFileName = $_.Name
    $tmplFileDir = $_.Directory.FullName
    $tmplText = Get-Content $tmplFilePath -Raw

    $outputName = $tmplFileName.Substring(0, $tmplFileName.Length - '.pstmpl'.Length)
    $outputPath = Join-Path $tmplFileDir -ChildPath $outputName

    $tmplDataHash.tmplFile = $tmplFilePath
    $tmplDataHash.pwd = $tmplFileDir
    
    Write-Output ('* {0} -> {1}' -f $tmplFilePath.Substring($workingDir.Length), $outputPath.Substring($workingDir.Length))
    $outContent = $tmplDataHash | Expand-PSTemplate -Template $tmplText
    $outContent | Set-Content -Path $outputPath -Encoding UTF8
}

Write-Output 'Removing templates'
dir (Join-Path $workingDir -ChildPath '*.pstmpl') -Recurse -File | ForEach-Object {
    Write-Output ('* {0}' -f $_.FullName.Substring($workingDir.Length))
    del $_
}

# ---------------------------

$allProjects = dir $workingDir -Directory | where { $_.Name -notlike '*.Tests' } | select -expand FullName

# en-US and en are special
$allCultures = [System.Globalization.CultureInfo]::GetCultures([System.Globalization.CultureTypes]::AllCultures).Name | where { 
    ($_ -ne '') -and
    ($_ -ne $null) -and
    ($_ -ne 'en-US') -and 
    ($_ -ne 'en') 
}

foreach ($projectDir in $allProjects)
{
    $projectName = Split-Path $projectDir -Leaf

    Write-Output ('Building project: {0}' -f $projectName)

    @("$projectName.psd1", "$projectName.psm1") | ForEach-Object {
        if (-not (Test-Path (Join-Path $workingDir -ChildPath "$projectName/$_") -PathType Leaf))
        {
            Write-Warning ("The project cannot be built by this script because is not a PowerShell module: {0}" -f $projectName)
            continue
        }
    }

    # regen en-US\{projectName}-Help.xml based on cbh
    Write-Output ('* Creating default MAML help file')
    ipmo (Join-Path $workingDir -ChildPath $projectName) -DisableNameChecking -Force
    $exportCmd = Get-Command -Module $projectName | select -expand Name
    ConvertTo-Maml -Command $exportCmd -Compress -OutFile (Join-Path $workingDir -ChildPath "$projectName/en-US/$projectName-Help.xml")
    # use en-US as en
    copy (Join-Path $workingDir -ChildPath "$projectName/en-US") (Join-Path $workingDir -ChildPath "$projectName/en") -Recurse

    Write-Output ('* Analyzing syntax tree: {0}' -f "$projectName.psm1")
    $scriptText = Get-Content -Path (Join-Path $workingDir -ChildPath "$projectName/$projectName.psm1") -Raw
    $scriptTokens = $null
    $scriptErrors = $null
    $scriptAst =  [Management.Automation.Language.Parser]::ParseInput($scriptText, [ref]$scriptTokens, [ref]$scriptErrors)
    $cbhTokens = $scriptTokens | where { 
        ($_.Kind -eq 'Comment') -and 
        ($_.Extent.Text -match '([\t\s]*)(\.SYNOPSIS)([\t\s]*)([\r\n]+)') 
    }

    $allParams = $scriptAst.FindAll({ 
        param($ast) 
        $ast -is [System.Management.Automation.Language.ParamBlockAst]
    }, $true)

    $allCommands = @{}

    $allParams | ForEach-Object {
        $paramDef = $_
        $commandName = $paramDef.Parent.Parent.Name
        $codeStub = @()
        $codeStub += $(
            if ($paramDef.Parent.Parent.IsFilter) { 'filter {0}' -f $commandName }
            elseif ($paramDef.Parent.Parent.IsWorkflow) { 'workflow {0}' -f $commandName }
            elseif ($paramDef.Parent.Parent.IsConfiguration) { 'configuration {0}' -f $commandName }
            else { 'function {0}' -f $commandName }
        )
        $codeStub += '{'
        $codeStub += '<# .EXTERNALHELP help.xml #>'
        $paramDef.Attributes | ForEach-Object {
            $codeStub += $_.Extent.Text
        }
        $codeStub += $paramDef.Extent.Text
        $codeStub += '}'

        $allCommands."$commandName" = $codeStub
    }

    Write-Output ('* Modifying module file to use external help')
    $newScript = [System.Text.StringBuilder]::new()
    for ($i = 0; $i -lt $cbhTokens.Count; $i++)
    {
        Write-Output ('** Processing {0}/{1} comment-based help entries' -f ($i + 1), $cbhTokens.Count)
        if ($i -eq 0)
        {
            $newScript.Append($scriptText.Substring(0, $cbhTokens[$i].Extent.StartOffset)) | Out-Null
        }

        $newScript.Append("# .EXTERNALHELP $projectName-Help.xml") | Out-Null

        if ($i -lt ($cbhTokens.Count - 1))
        {
            $newScript.Append($scriptText.Substring($cbhTokens[$i].Extent.EndOffset, $cbhTokens[$i + 1].Extent.StartOffset - $cbhTokens[$i].Extent.EndOffset)) | Out-Null
        }
        else
        {
            $newScript.Append($scriptText.Substring($cbhTokens[$i].Extent.EndOffset)) | Out-Null
        }
    }

    Write-Output ('** Writing to {0}.psm1' -f $projectName)
    $newScript.ToString() | Set-Content -Path (Join-Path $workingDir -ChildPath "$projectName/$projectName.psm1")

    # regen other cultures
    foreach ($cultureCode in $allCultures)
    {
        $localizeDir = Join-Path $workingDir -ChildPath "$projectName/$cultureCode"
        if (-not (Test-Path $localizeDir -PathType Container))
        {
            continue
        }

        Write-Output ('* Processing globalization resource: {0}' -f $cultureCode)

        $outMamlPath = Join-Path $localizeDir -ChildPath "$projectName-Help.xml"
        $commandHelpTopics = dir (Join-Path $localizeDir -ChildPath "$projectName-Help_*.md") -File
        if (-not $commandHelpTopics)
        {
            Write-Warning ("No file found that matches the wildcard pattern: {0}" -f "$projectName-Help_*.md")
            continue
        }

        $commandHelp = @{}
        $commandHelpTopics | ForEach-Object {
            $commandName = $_.BaseName.Substring("$repoName-Help_".Length)
            $commandText = Get-Content -Path $_.FullName -Encoding UTF8
            $commandHelp."$commandName" = $commandText -join [Environment]::NewLine
        }

        $localizeEvalStub = @()

        $commandHelp.Keys | ForEach-Object {
            if ($_ -in $allCommands.Keys)
            {
                Write-Output ('** Generating comment-based help stub: {0}' -f $_)

                $addToStub = $allCommands."$_"
                $addToStub[2] = '<#' + [Environment]::NewLine + $commandHelp."$_" + [Environment]::NewLine + '#>'

                $localizeEvalStub += $addToStub -join [Environment]::NewLine
            }
        }

        $commandHelp.Keys | ForEach-Object {
            $localizeEvalStub += "Get-Help $_ -Full"
        }

        Write-Output ('** Writing MAML file')
        $evalScript = [scriptblock]::Create(($localizeEvalStub -join [Environment]::NewLine))
        $helpObjects= $evalScript.Invoke()
        ConvertTo-Maml -HelpInfo $helpObjects -Compress -OutFile $outMamlPath

        Write-Output ('** Removing files: {0}' -f "$projectName-Help_*.md")
        $commandHelpTopics | ForEach-Object {
            del $_ -Force
        }
    }
}

# --------------------------

$releaseVersion = $tmplDataHash.moduleVersion
if ($tmplDataHash.prerelease -eq 'True')
{
    $releaseVersionDir = Join-Path $releaseDir -ChildPath "v$releaseVersion-prerelease"
}
else
{
    $releaseVersionDir = Join-Path $releaseDir -ChildPath "v$releaseVersion"
}

if (Test-Path $releaseVersionDir)
{
    rd $releaseVersionDir -Recurse -Force
}

md $releaseVersionDir | Out-Null

dir $workingDir -Directory | ForEach-Object {
    Write-Output ('Generating package: {0}' -f $_.Name)
    $pkgItemPaths = @()
    $packageCommonFiles | ForEach-Object {
        $pkgItemPaths += Join-Path $repoDir -ChildPath $_
    }
    $pkgItemPaths += $_.FullName

    $psManifestPath = (Join-Path $workingDir -ChildPath ('{0}/{0}.psd1' -f $_.Name))
    if (Test-Path $psManifestPath -PathType Leaf)
    {
        $psManifest = Test-ModuleManifest -Path $psManifestPath
        $pkgVersion = $psManifest.Version.ToString()
        $pkgFileName = '{0}.{1}.zip' -f $_.Name, $pkgVersion
    }
    else
    {
        $pkgFileName = '{0}.zip' -f $_.Name
    }

    Compress-Archive -Path $pkgItemPaths -DestinationPath (Join-Path $releaseVersionDir -ChildPath $pkgFileName)
}

if ($Publish)
{
	Write-Output ('Publishing module to PSGallery: Builder')
	$nugetApiKey = Get-Content (Join-Path $credDir -ChildPath 'powershell_gallery_nuget_apikey.txt')

	# Possible issues:
	# - PSModule name may already be taken in PSGallery
	# - PowerShellGet requires NuGet.exe (PowerShellGet will prompt)
	$publishModuleParams = @{
	    Path = (Join-Path $workingDir -ChildPath 'Builder')
	    NuGetApiKey = $nugetApiKey
	    Repository = 'PSGallery'
	}
	Publish-Module @publishModuleParams
}
