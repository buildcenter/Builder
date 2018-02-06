#Requires -Version 2.0

if ($PSVersionTable.PSVersion.Major -ge 3)
{
    $script:IgnoreError = 'Ignore'
}
else
{
    $script:IgnoreError = 'SilentlyContinue'
}


#######################################################################
#  Public Module Functions
#######################################################################

function Expand-PSTemplate
{
    <#
        .SYNOPSIS
            Render a text template using PowerShell templating syntax.

        .DESCRIPTION
            Surround your script with '{{' and '}}'; any text outside will be interpreted as literal text.

            You need to use the `DataBinding` parameter to define custom variables and functions.

        .PARAMETER Template
            A text template written using PowerShell templating syntax.

        .PARAMETER DataBinding
            A hashtable containing variables and custom functions.

        .EXAMPLE
            Expand-PSTemplate @'
            hello world!
            '@

            hello world!

            DESCRIPTION
            -----------
            If the template does not contain any script, it is displayed as is.

        .EXAMPLE
            @{
                foo = 'bar'
            } | Expand-PSTemplate 'hello {{ $foo }}'

            hello bar

            DESCRIPTION
            -----------
            Keys in the `DataBinding` hashtable can generally be used as ordinary variables within the template.

            You need to ensure that the value can be converted to a string type.

        .EXAMPLE
            @{
                foo = 'bar'
                concat = [scriptblock]{
                    [cmdletbinding()]
                    param(
                        [parameter(mandatory = $true, valuefrompipeline = $true)]
                        [string]$inputObject,
                        
                        [parameter(position = 1)]
                        [string]$otherObject
                    )
                    
                    return ('{0}{1}' -f $inputObject, $otherObject)
                }
            } | Expand-PSTemplate 'hello {{ $foo | concat 'guy' }}'

            hello barguy

            DESCRIPTION
            -----------
            You can define custom functions by creating [scriptblock] entries in the `DataBinding` hashtable.

        .EXAMPLE
            @{
                'cars' = @('honda', 'ford', 'bmw')
                'fruits' = @{
                    'apple' = 'red'
                    'banana' = 'yellow'
                }
            } | Expand-PSTemplate @'
            Cars at index 0 is {{ $cars[0] }}.
            Here are all the cars:
            {{ $cars | % { }}
            * {{ $_ }}{{ } }}

            The color of fruit apple is {{ $fruits.apple }}
            Here are all the fruits and their colors:
            {{ $fruits.Keys | % { }}
            * {{ $_ }} = {{ $fruits."$_" }}{{ } }}

            DESCRIPTION
            -----------
            Use the `ForEach-Object` (or `%` alias) to loop through collections.
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$Template,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [hashtable]$DataBinding
    )

    # separate scriptblocks from common vars
    $templateVars = @{}
    $templateFuncs = @()

    foreach ($dataKey in $DataBinding.Keys)
    {
        if ($DataBinding."$dataKey" -is [scriptblock])
        {
            $scriptDef = @()
            $scriptDef += 'function {0}' -f $dataKey
            $scriptDef += $DataBinding."$dataKey".ToString()
            $templateFuncs += ($scriptDef -join [Environment]::NewLine)
        }
        else
        {
            $templateVars."$dataKey" = $DataBinding."$dataKey"
        }
    }

    # shorthand helper
    $enc = [System.Text.Encoding]::UTF8

    # this will be invoke-expression-ed
    $evalScript = [System.Text.StringBuilder]::new()

    $evalHeader = @(
        'Param('
        '    [Parameter(Mandatory, Position = 1)]'
        '    [hashtable]$Data'
        ')'
        ''
        'foreach ($dataKey in $Data.Keys)'
        '{'
        '    if (Test-Path "Variable:\$dataKey")'
        '    {'
        '        Set-Item -Path "Variable:\$dataKey" -Value $Data.$dataKey -WhatIf:$false -Confirm:$false | Out-Null'
        '    }'
        '    else'
        '    {'
        '        New-Item -Path "Variable:\$dataKey" -Value $Data.$dataKey -WhatIf:$false -Confirm:$false | Out-Null'
        '    }'
        '}'
    ) -join [Environment]::NewLine

    $evalScript.AppendLine($evalHeader) | Out-Null

    # hard-code the delims to mustache
    $delimStart = '{{'
    $delimEnd = '}}'

    $ps = Select-Substring -InputObject $Template -Preceding $delimStart -Succeeding $delimEnd -PassThru

    # force to array
    if (($ps -ne $null) -and ($ps.Count -eq $null))
    {
        $ps  = @($ps)
    }

    # template does not require processing
    if ($ps.Count -eq 0)
    {
        return $Template
    }

    # generate the main script
    for ($i = 0; $i -lt $ps.Count; $i++)
    {
        if ($i -eq 0) 
        { 
            $payload = $Template.Substring(0, $ps[0].Preceding.Index) 
        }
        else
        {
            $payload = $Template.Substring($ps[$i - 1].Succeeding.Index + $delimEnd.Length, $ps[$i].Preceding.Index - $ps[$i - 1].Succeeding.Index - $delimEnd.Length)
        }

        # add preceding payload
        if ($payload)
        {
            $payloadEnc = [Convert]::ToBase64String($enc.GetBytes($payload), [Base64FormattingOptions]::None)
            $evalScript.AppendLine('[System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("{0}"))' -f $payloadEnc) | Out-Null
        }

        # add ps command
        if ($ps[$i].Substring)
        {
            $evalScript.AppendLine($ps[$i].Substring) | Out-Null
        }

        # add last payload
        if ($i -eq ($ps.Count - 1))
        {
            $payload = $Template.Substring($ps[$i].Succeeding.Index + $delimEnd.Length)
            if ($payload)
            {
                $payloadEnc = [Convert]::ToBase64String($enc.GetBytes($payload), [Base64FormattingOptions]::None)
                $evalScript.AppendLine('[System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("{0}"))' -f $payloadEnc) | Out-Null
            }
        }
    }

    # create ps runspace
    $initialSessionState = [initialsessionstate]::CreateDefault2()
    $runspace = [runspacefactory]::CreateRunspace($initialSessionState)
    $psInstance = [powershell]::Create()
    $psInstance.Runspace = $runspace
    $runspace.Open()

    # add the custom funcs
    if ($templateFuncs.Count -gt 0)
    {
        $templateFuncs | ForEach-Object {
            Write-Verbose "Add function: $_"
            [void]$psInstance.AddStatement().AddScript($_)
        }
    }

    # add the main script
    Write-Verbose ("Main: " -f $evalScript.ToString())
    [void]$psInstance.AddStatement().AddScript($evalScript.ToString()).AddArgument($templateVars)

    # generate
    $result = $psInstance.Invoke()
    $psInstance.Dispose()
    $runspace.Dispose()

    # return result
    $result -join ''
}

function Select-Substring
{
    <#
        .SYNOPSIS
            Search for a substring that has the specified text appearing before and after it.

        .DESCRIPTION
            Using regex to seaech for indeterminate length patterns can have a big performance hit when text length increases. This command uses loops and substring indexes internally to allow faster searches for long strings.

            To obtain the position of each preceding, succeeding, and substring positions, use the 'PassThru' switch.

        .Example
            Select-Substring -InputObject "a !banana, and an !apple," -Before 'a', '!' -After ','
            #banana
            #apple
    #>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
        [string]$InputObject,
    
        [Parameter(Mandatory = $true, Position = 2)]
        [Alias('Before')]
        [string[]]$Preceding,
    
        [Parameter(Mandatory = $true, Position = 3)]
        [Alias('After')]
        [string[]]$Succeeding,

        [Parameter(Mandatory = $false)]
        [Switch]$CaseSensitive,

        [Parameter(Mandatory = $false)]
        [ValidateSet('FixedExactlyOnce')]
        [string]$OrderBy = 'FixedExactlyOnce',

        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )

    Begin
    {
        function GetIndexOfTags([Int]$startIndex)
        {
            if (-not $CaseSensitive) 
            { 
                $searchData = $InputObject.ToLower() 
            }
            else 
            { 
                $searchData = $InputObject 
            }

            $lastCursor = $startIndex

            $startTags = @()
            foreach ($stag in $Preceding)
            {
                if (-not $CaseSensitive) 
                { 
                    $stag = $stag.ToLower() 
                }
                $thisCursor = $searchData.IndexOf($stag, $lastCursor)
                
                if ($thisCursor -eq -1) 
                { 
                    return $null 
                }
                else
                {
                    $startTags += [PSCustomObject]@{
                        'Value' = $InputObject.Substring($thisCursor, $stag.Length)
                        'Index' = $thisCursor
                        'Length' = $stag.Length
                    }

                    $lastCursor = $thisCursor + $stag.Length
                }
            }

            $endTags = @()
            foreach ($stag in $Succeeding)
            {
                if (-not $CaseSensitive) 
                { 
                    $stag = $stag.ToLower() 
                }
                $thisCursor = $searchData.IndexOf($stag, $lastCursor)
                
                if ($thisCursor -eq -1) 
                { 
                    return $null 
                }
                else
                {
                    $endTags += [PSCustomObject]@{
                        'Value' = $InputObject.Substring($thisCursor, $stag.Length)
                        'Index' = $thisCursor
                        'Length' = $stag.Length
                    }

                    $lastCursor = $thisCursor + $stag.Length
                }
            }

            return [PSCustomObject]@{
                'Preceding' = $startTags
                'Succeeding' = $endTags
                'Substring' = ''
            }
        }
    }

    Process
    {
        $startCursor = 0
        $output = @()
        while ($true)
        {
            $result = GetIndexOfTags($startCursor)
            if ($result -eq $null) { break }

            $result.Substring = $InputObject.Substring(
                $result.Preceding[-1].Index + $result.Preceding[-1].Length, 
                $result.Succeeding[0].Index - $result.Preceding[-1].Index - $result.Preceding[-1].Length)

            $output += $result
            $startCursor = $result.Succeeding[-1].Index + $result.Succeeding[-1].Length
        }
    }

    End
    {
        if ($PassThru) 
        { 
            $output 
        }
        else
        {
            $output | ForEach-Object { $_.Substring }
        }
    }
}

Export-ModuleMember -Function @(
    'Expand-PSTemplate'
)
