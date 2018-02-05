$toolsDir = $PSScriptRoot
$repoDir = Resolve-Path (Join-Path $toolsDir -ChildPath '..') | select -expand Path
$sourceDir = Join-Path $repoDir -ChildPath 'Source'
$workingDir = Join-Path $repoDir -ChildPath 'Working'
$repoName = Split-Path $repoDir -Leaf
$releaseDir = Join-Path $repoDir -ChildPath 'Releases'
$credDir = Join-Path $repoDir -ChildPath 'Credentials'

$nugetApiKey = Get-Content (Join-Path $credDir -ChildPath 'powershell_gallery_nuget_apikey.txt')
#Import-LocalizedData -BindingVariable manifestData -BaseDirectory (Join-Path $workingDir -ChildPath 'Builder') -FileName 'Builder.psd1'

# Possible issues:
# - PSModule name may already be taken in PSGallery
# - PowerShellGet requires NuGet.exe (PowerShellGet will prompt)
# - warns about Tags, ReleaseNotes, LicenseUri, ProjectUri (seems to be a bug with Publish-Module)
$publishModuleParams = @{
    Path = (Join-Path $workingDir -ChildPath 'Builder')
    NuGetApiKey = $nugetApiKey
    Repository = 'PSGallery'
    #ReleaseNotes = $manifestData.PrivateData.PSData.ReleaseNotes
    #Tags = $manifestData.PrivateData.PSData.Tags
    #LicenseUri = $manifestData.PrivateData.PSData.LicenseUri
    #ProjectUri = $manifestData.PrivateData.PSData.ProjectUri
}
Publish-Module @publishModuleParams
