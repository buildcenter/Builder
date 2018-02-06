<#
    PostAction only runs if Action doesn't fail.
#>

task default -depends Test

task Test -depends Compile, Clean -PreAction { "Pre test" } -Action {
    assert $false "This fails."
} -PostAction { "I never gets executed" }

task Compile -depends Clean {
    "Compile"
}

task Clean {
    "Clean"
}
