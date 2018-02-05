function concat
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [AllowNull()]
        [string[]]$InputObject,

        [parameter(Position = 1)]
        [AllowEmptyString()]
        [string[]]$AppendWith = @('')
    )

    Begin
    {
        $appendText = $AppendWith -join ''
    }

    Process
    {
        if ($InputObject -eq $null)
        {
            $InputObject = ''
        }

        foreach ($inputItem in $InputObject)
        {
            if ($AppendWith)
            {
                '{0}{1}' -f $inputItem, $appendText
            }
            else
            {
                $inputItem
            }
        }
    }
}

function format
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string[]]$InputObject,

        [parameter(Mandatory, Position = 1)]
        [AllowEmptyString()]
        [string]$With
    )
    
    Process
    {
        if ($InputObject -eq $null)
        {
            $InputObject = ''
        }

        foreach ($inputItem in $InputObject)
        {
            if (-not $inputItem)
            {
                $With -f ''
            }
            else
            {
                $With -f $inputItem
            }
        }
    }
}

function include
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline = $true)]
        [string]$Path,

        [parameter()]
        [string]$Indent,

        [parameter()]
        [ValidateSet('Ascii', 'Unicode', 'UTF8')]
        [string]$Encoding
    )

    if ((-not $Indent) -and (-not $Encoding))
    {
        Get-Content -Path $Path -Raw
    }
    else
    {
        $getContentParam = @{
            Path = $Path
        }

        if ($Encoding)
        {
            $getContentParam.Encoding = $Encoding
        }

        (Get-Content @getContentParam | ForEach-Object {
            if ($Indent)
            {
                $Indent + $_
            }
            else
            {
                $_
            }
        }) -join [Environment]::NewLine
    }
}

function lowercase
{
    [CmdletBinding()]
    param(
        [parameter(Mandatory, ValueFromPipeline = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string[]]$InputObject
    )

    Process
    {
        if ($InputObject -eq $null)
        {
            $InputObject = ''
        }

        foreach ($inputItem in $InputObject)
        {
            if ($inputItem -ne $null)
            {
                $inputItem.ToLowerInvariant()
            }
            else
            {
                $null
            }
        }
    }
}

function replace
{
    [CmdletBinding(DefaultParameterSetName = 'ReplaceEntireStringSet')]
    param(
        [parameter(Mandatory, ValueFromPipeline = $true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string[]]$InputObject,

        [parameter(Mandatory, ParameterSetName = 'ReplaceNullSet')]
        [parameter(ParameterSetName = 'ReplaceSubstringSet')]
        [parameter(ParameterSetName = 'ReplaceEntireStringSet')]
        [AllowEmptyString()]
        [Alias('null')]
        [string]$NullOrEmpty,

        [parameter(Mandatory, Position = 1, ParameterSetName = 'ReplaceSubstringSet')]
        [string[]]$Substring,

        [parameter(Position = 2, ParameterSetName = 'ReplaceSubstringSet')]
        [parameter(ParameterSetName = 'ReplaceEntireStringSet')]
        [AllowEmptyString()]
        [string]$With = ''
    )

    Process
    {
        if ($InputObject -eq $null)
        {
            $InputObject = ''
        }

        foreach ($inputItem in $InputObject)
        {
            if ($PSBoundParameters.ContainsKey('NullOrEmpty') -and 
                (-not $inputItem))
            {
                $NullOrEmpty
                continue
            }

            if ($PSCmdlet.ParameterSetName -eq 'ReplaceSubstringSet')
            {
                if (-not $inputItem) 
                { 
                    '' 
                }
                else 
                {
                    $replaceResult = $inputItem
                    foreach ($SubstringItem in $Substring)
                    {
                        $replaceResult = $replaceResult.Replace($SubstringItem, $With) 
                    }
                    $replaceResult
                }
            }
            elseif ($PSCmdlet.ParameterSetName -eq 'ReplaceEntireStringSet')
            {
                $With
            }
            else
            {
                $inputItem
            }
        }
    }
}
