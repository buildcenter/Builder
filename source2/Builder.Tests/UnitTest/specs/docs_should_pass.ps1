task default -depends CheckDocs

task CheckDocs {
    $doc = Invoke-Builder .\nested\docs.ps1 -Docs -NoLogo | Out-String

    $expectedDoc = @"

Name             Alias Depends On                         Default Description        
----             ----- ----------                         ------- -----------        
Compile                CompileSolutionA, CompileSolutionB    True                    
CompileSolutionA                                                  Compiles solution A
CompileSolutionB                                                                     
IntegrationTests                                                                     
Test                   UnitTests, IntegrationTests           True                    
UnitTests        ut                                                                  



"@

    assert ($doc -eq $expectedDoc) "Unexpected doc content: $doc"
}
