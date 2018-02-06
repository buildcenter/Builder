function ConvertFrom-Maml
{
    [CmdletBinding(DefaultParameterSetName = 'ByString')]
    Param(
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'ByString')]
        [string]$MAML,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByPath')]
        [string]$Path
    )

    if ($PSCmdlet.ParameterSetName -eq 'ByPath')
    {
        $MAML = (Get-Content -Path $Path) -join [Environment]::NewLine
    }

    $xmlObj = [xml]$MAML

    $outResult = @{}

    $xmlObj.helpItems.command | ForEach-Object {
        $commandName = $_.details.name

        $synopsis = @($_.details.description.para | ForEach-Object { $_ })

        $description = @($_.description.para | ForEach-Object { $_ })

        $role = $_.role
        $component = $_.component
        $functionality = $_.functionality
        
        $commandParams = @{}
        $_.parameters.parameter | ForEach-Object {
            $commandParams."$($_.name)" = @($_.description.para | ForEach-Object { $_ })
        }

        $notes = @()
        for ($i = 0; $i -lt $_.alertSet.alert.para.Count; $i++)
        {
            $notes += $_.alertSet.alert.para[$i]
        }

        $links = @()
        $_.relatedLinks.navigationLink | ForEach-Object {
            $links += @{
                text = $_.linkText
                url = $_.uri
            }
        }

        $examples = @{}
        for ($i = 0; $i -lt $_.examples.example.Count; $i++)
        {
            $examples."example_$i" = @{}

            $egCode = $_.examples.example[$i].code

            $egRemark = @()
            if (($_.examples.example[$i].remarks.para.Count -ge 1) -and 
                ($_.examples.example[$i].remarks.para[0] -ne ''))
            {
                if (($_.examples.example[$i].remarks.para[0] -eq '') -or 
                    ($_.examples.example[$i].remarks.para[0] -eq $null))
                {
                    $_.examples.example[$i].remarks.para | where { $_ -ne '' } | ForEach-Object {
                        $egRemark += $_
                    }
                }
                else
                {
                    $remarkFirstPara = $_.examples.example[$i].remarks.para[0].Split([Environment]::NewLine)

                    if (($remarkFirstPara.Count -ge 2) -and 
                        ($remarkFirstPara[0] -eq 'DESCRIPTION') -and 
                        ($remarkFirstPara[1] -match '^-----*$'))
                    {
                        if ($remarkFirstPara.Count -ne 2)
                        {
                            @(2..($remarkFirstPara.Count - 1)) | ForEach-Object {
                                $egRemark += $remarkFirstPara[$_]
                            }
                        }
                    }
                    else
                    {
                        $remarkFirstPara | ForEach-Object {
                            $egRemark += $_
                        }
                    }

                    if ($_.examples.example[$i].remarks.para.Count -gt 1)
                    {
                        for ($k = 1; $k -lt $_.examples.example[$i].remarks.para.Count; $k++)
                        {
                            if ($_.examples.example[$i].remarks.para[$k])
                            {
                                $egRemark += $_.examples.example[$i].remarks.para[$k]
                            }
                        }
                    }
                }
            }

            $examples."example_$i" = @{
                code = $egCode
                remarks = @($egRemark)
            }
        }

        $outText = @()

        $outText += '.SYNOPSIS'
        $outText += ($synopsis | ForEach-Object { (' ' * 4) + $_ }) -join ([Environment]::NewLine * 2)
        $outText += ''

        if ($role)
        {
            $outText += '.ROLE'
            $outText += '    ' + $role
            $outText += ''
        }

        if ($component)
        {
            $outText += '.COMPONENT'
            $outText += '    ' + $component
            $outText += ''
        }

        if ($functionality)
        {
            $outText += '.FUNCTIONALITY'
            $outText += '    ' + $functionality
            $outText += ''
        }

        $outText += '.DESCRIPTION'
        $outText += ($description | ForEach-Object { (' ' * 4) + $_ }) -join ([Environment]::NewLine * 2)
        $outText += ''
        $commandParams.Keys | sort | ForEach-Object {
            if ($commandParams."$_")
            {
                $outText += '.PARAMETER ' + $_
                $outText += ($commandParams."$_" | ForEach-Object { (' ' * 4) + $_ }) -join ([Environment]::NewLine * 2)
                $outText += ''
            }
        }

        $examples.Keys | sort | ForEach-Object {
            $outText += '.EXAMPLE'
            if ($examples."$_".code)
            {
                $outText += ($examples."$_".code.Split([Environment]::NewLine) | ForEach-Object { (' ' * 4) + $_ }) -join ([Environment]::NewLine)
            }
            if ($examples."$_".remarks)
            {
                $outText += ''
                $outText += '    DESCRIPTION'
                $outText += '    -----------'
                $outText += ($examples."$_".remarks | ForEach-Object { (' ' * 4) + $_ }) -join ([Environment]::NewLine * 2)
            }
            $outText += ''
            $outText += ''
            $outText += ''
        }

        if ($notes.Count -gt 0)
        {
            $outText += '.NOTE'
            $outText += ($notes | ForEach-Object { (' ' * 4) + $_ }) -join ([Environment]::NewLine * 2)
            $outText += ''
        }

        $links | ForEach-Object {
            if ($_.text -or $_.url)
            {
                $outText += '.LINK'
            }
            if ($_.text)
            {
                $outText += '    ' + ($_.text)
            }
            if ($_.url)
            {
                $outText += '    ' + ($_.url)
            }
            if ($_.text -or $_.url)
            {
                $outText += ''
            }
        }

        $outResult."$commandName" = @{
            synopsis = $synopsis
            description = $description
            role = $role
            component = $component
            functionality = $functionality
            parameters = $commandParams
            notes = $notes
            links = $links
            examples = $examples
            text = $outText -join [Environment]::NewLine
        }
    }

    $outResult
}

function ConvertTo-Maml
{
    [CmdletBinding(DefaultParameterSetName = 'ByNameSet')]
    Param(
        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'ByNameSet')]
        [string[]]$Command,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByObjectSet')]
        [pscustomobject[]]$HelpInfo,

        [Parameter()]
        [switch]$Compress,

        [Parameter()]
        [string]$OutFile
    )

    <#
    https://stackoverflow.com/questions/1091945/what-characters-do-i-need-to-escape-in-xml-documents
    
    XML escape char table:
         "   &quot;
         '   &apos;
         <   &lt;
         >   &gt;
         &   &amp;
    
    W3C spec:
        Text         escape ", ' and > is optional
        Attrib       escape > is optional. escape ' is optional if quote is in " and vice verse.
        Comment      do not escape any!
        CDATA        do not escape any!
        Processing   do not escape any!
    
    MSXML spec:
        Text         does not escape ' and "
        Attrib       quote is always in ". Does not escape ' 
    #>

    function EscXmlText
    {
        Param(
            [Parameter(Mandatory, Position = 1)]
            [string]$Text
        )

        # replace & first!
        $Text.Replace(
            '&', '&amp;'
        ).Replace(
            '<', '&lt;'
        ).Replace(
            '>', '&gt;'
        )
    }

    function EscXmlAttrib
    {
        Param(
            [Parameter(Mandatory, Position = 1)]
            [string]$Text
        )

        $Text.Replace(
            '&', '&amp;'
        ).Replace(
            '<', '&lt;'
        ).Replace(
            '>', '&gt;'
        ).Replace(
            '"', '&quot;'
        )
    }

    <#
    Reference
    ---------
    https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comment_based_help?view=powershell-5.1&viewFallbackFrom=powershell-Microsoft.PowerShell.Core
    https://msdn.microsoft.com/en-us/library/bb525433(v=vs.85).aspx
    https://info.sapien.com/index.php/scripting/scripting-help/parameter-attributes-in-powershell-help

    TODO #notimplemented
    - parameter variablelength
    - parameter alias
    - FORWARDHELPTARGETNAME
    - FORWARDHELPCATEGORY
    - REMOTEHELPRUNSPACE
    #>

    $outMaml = @()

    $outMaml += '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    $outMaml += '<helpItems schema="maml">'

    if ($PSCmdlet.ParameterSetName -eq 'ByNameSet')
    {
        $HelpInfo = @()

        foreach ($commandItem in $Command)
        {
            $HelpInfo += Get-Help $commandItem -Full
        }
    }

    foreach ($helpResult in $HelpInfo)
    {
        if (-not $helpResult)
        {
            continue
        }

        $outMaml += '  <command:command xmlns:maml="http://schemas.microsoft.com/maml/2004/10" xmlns:command="http://schemas.microsoft.com/maml/dev/command/2004/10" xmlns:dev="http://schemas.microsoft.com/maml/dev/2004/10">'
        $outMaml += '    <command:details>'
        $outMaml += '      <command:name>{0}</command:name>' -f (EscXmlText $helpResult.Name)
        $outMaml += '      <maml:description>'
        if ($helpResult.details.description)
        {
            $helpResult.details.description | ForEach-Object {
                if ($_.Text)
                {
                    $outMaml += '        <maml:para>{0}</maml:para>' -f (EscXmlText $_.Text)
                }
            }
        }
        else
        {
            $outMaml += '        <maml:para />'
        }
        $outMaml += '      </maml:description>'
        $outMaml += '      <maml:copyright>'
        $outMaml += '        <maml:para />'
        $outMaml += '      </maml:copyright>'
        $outMaml += '      <command:verb>{0}</command:verb>' -f $(if ($helpResult.Name -like '*-*') { EscXmlText ($helpResult.Name.Split('-')[0]) } else { '' })
        $outMaml += '      <command:noun>{0}</command:noun>' -f $(if ($helpResult.Name -like '*-*') { EscXmlText ($helpResult.Name.Substring($helpResult.Name.IndexOf('-') + 1)) } else { '' })
        $outMaml += '      <dev:version />'
        $outMaml += '    </command:details>'

        $outMaml += '    <maml:description>'
        $helpResult.description | where { $_ -ne $null } | ForEach-Object {
            if ($_.Text)
            {
                $_.Text.Split([Environment]::NewLine) | where { $_ -ne '' } | ForEach-Object {
                    $outMaml += '      <maml:para>{0}</maml:para>' -f (EscXmlText $_)
                }
            }
        }
        
        $outMaml += '    </maml:description>'

        $outMaml += '    <command:syntax>'
        $helpResult.syntax.syntaxItem | ForEach-Object {
            $outMaml += '      <command:syntaxItem>'
            $outMaml += '        <command:name>{0}</command:name>' -f (EscXmlText $_.name)
            $_.parameter | where { $_ -ne $null } | ForEach-Object {
                $paramRequired = $(if ($_.required) { $_.required } else { 'false' })
                $paramGlobbing = $(if ($_.globbing) { $_.globbing } else { 'false' })

                $outMaml += '        <command:parameter require="{0}" globbing="{1}" pipelineInput="{2}" position="{3}">' -f (EscXmlAttrib $paramRequired), (EscXmlAttrib $paramGlobbing), (EscXmlAttrib $_.pipelineInput), (EscXmlAttrib $_.position)
                $outMaml += '          <maml:name>{0}</maml:name>' -f (EscXmlText $_.Name)
                if ($_.parameterValue)
                {
                    $outMaml += '          <command:parameterValue required="{0}">{1}</command:parameterValue>' -f (EscXmlAttrib $paramRequired), (EscXmlText $_.parameterValue)
                }
                $outMaml += '        </command:parameter>'
            }
            $outMaml += '      </command:syntaxItem>'
        }
        $outMaml += '    </command:syntax>'

        $outMaml += '    <command:parameters>'
        $helpResult.parameters.parameter | where { $_ -ne $null } | ForEach-Object {
            $paramRequired = $(if ($_.required) { $_.required } else { 'false' })
            $paramGlobbing = $(if ($_.globbing) { $_.globbing } else { 'false' })

            $outMaml += '      <command:parameter required="{0}" globbing="{1}" pipelineInput="{2}" position="{3}">' -f (EscXmlAttrib $paramRequired), (EscXmlAttrib $paramGlobbing), (EscXmlAttrib $_.pipelineInput), (EscXmlAttrib $_.position)
            $outMaml += '        <maml:name>{0}</maml:name>' -f (EscXmlText $_.name)
            $outMaml += '        <maml:description>'
            if ($_.description.Text)
            {
                $_.description.Text.Split([Environment]::NewLine) | where { $_ -ne '' } | ForEach-Object {
                    $outMaml += '          <maml:para>{0}</maml:para>' -f (EscXmlText $_)
                }
            }
            $outMaml += '        </maml:description>'
            $outMaml += '        <command:parameterValue required="{0}">{1}</command:parameterValue>' -f (EscXmlAttrib $_.required), (EscXmlText $_.type.name)
            $outMaml += '        <dev:type>'
            $outMaml += '          <maml:name>{0}</maml:name>' -f (EscXmlText $_.type.name)
            $outMaml += '          <maml:uri />'
            $outMaml += '        </dev:type>'
            if ($_.defaultValue)
            {
                $outMaml += '        <dev:defaultValue>{0}</dev:defaultValue>' -f (EscXmlText $_.defaultValue)
            }
            <#
            $outMaml += '<dev:possibleValues>'
            $outMaml += '  <dev:possibleValue>'
            $outMaml += '    <dev:value></dev:value>'
            $outMaml += '    <maml:description>'
            $outMaml += '      <maml:para></maml:para>'
            $outMaml += '    </maml:description>'
            $outMaml += '  </dev:possibleValue>'
            $outMaml += '/<dev:possibleValues>'
            #>
            $outMaml += '      </command:parameter>'
        }
        $outMaml += '    </command:parameters>'

        $outMaml += '    <command:inputTypes>'
        if ($helpResult.inputTypes.inputType.type.name)
        {
            # String[], PSObject[]
            # http://somewhere/optional
            #
            # This is a description.
            # 
            # Another line.
            #
            # --------------------
            #
            # Int[]
            # Some other lines.

            $inputTypeRawText = $helpResult.inputTypes.inputType.type.name.Split([Environment]::NewLine) | where { $_ -ne '' }
            $inputTypeSection = @()
            for ($i = 0; $i -lt $inputTypeRawText.Count; $i++)
            {
                if ($inputTypeRawText[$i] -notmatch '^-----*$')
                {
                    $inputTypeSection += $inputTypeRawText[$i]

                    if ($i -ne ($inputTypeRawText.Count - 1))
                    {
                        continue
                    }
                }

                if ($inputTypeSection.Count -eq 0)
                {
                    continue
                }

                $typeName = $inputTypeSection[0]
                $typeUrl = $null
                $typeDesc = @()

                if ($inputTypeSection.Count -gt 1)
                {
                    if (($inputTypeSection[1] -like 'http://*') -or 
                        ($inputTypeSection[1] -like 'https://*'))
                    {
                        $typeUrl = $inputTypeSection[1]
                    }
                    else
                    {
                        $typeDesc += $inputTypeSection[1]
                    }
                }

                if ($inputTypeSection.Count -gt 2)
                {
                    @(2..($inputTypeSection.Count - 1)) | ForEach-Object {
                        $typeDesc += $inputTypeSection[$_]
                    }
                }

                $outMaml += '      <command:inputType>'
                $outMaml += '        <dev:type>'
                $outMaml += '          <maml:name>{0}</maml:name>' -f (EscXmlText $typeName)
                if ($typeUrl -eq $null)
                {
                    $outMaml += '          <maml:uri />'
                }
                else
                {
                    $outMaml += '          <maml:uri>{0}</maml:uri>' -f (EscXmlText $typeUrl)
                }
                $outMaml += '          <maml:description>'
                $outMaml += '            <maml:para></maml:para>'
                $typeDesc | ForEach-Object {
                    $outMaml += '            <maml:para>{0}</maml:para>' -f (EscXmlText $_)
                }
                $outMaml += '          </maml:description>'
                $outMaml += '        </dev:type>'
                $outMaml += '      </command:inputType>'

                # reset section content holder
                $inputTypeSection = @()
            }
        }
        else
        {
            $outMaml += '      <command:inputType>'
            $outMaml += '        <dev:type>'
            $outMaml += '          <maml:name>None</maml:name>'
            $outMaml += '          <maml:uri />'
            $outMaml += '          <maml:description>'
            $outMaml += '            <maml:para></maml:para>'
            $outMaml += '          </maml:description>'
            $outMaml += '        </dev:type>'
            $outMaml += '      </command:inputType>'
        }
        $outMaml += '    </command:inputTypes>'

        $outMaml += '    <command:returnValues>'
        if ($helpResult.returnValues.returnValue.type.name)
        {
            # String[], PSObject[]
            # http://somewhere/optional
            #
            # This is a description.
            # 
            # Another line.
            #
            # --------------------
            #
            # Int[]
            # Some other lines.

            $returnTypeRawText = $helpResult.returnValues.returnValue.type.name.Split([Environment]::NewLine) | where { $_ -ne '' }
            $returnTypeSection = @()
            for ($i = 0; $i -lt $returnTypeRawText.Count; $i++)
            {
                if ($returnTypeRawText[$i] -notmatch '^-----*$')
                {
                    $returnTypeSection += $returnTypeRawText[$i]

                    if ($i -ne ($returnTypeRawText.Count - 1))
                    {
                        continue
                    }
                }

                if ($returnTypeSection.Count -eq 0)
                {
                    continue
                }

                $typeName = $returnTypeSection[0]
                $typeUrl = $null
                $typeDesc = @()

                if ($returnTypeSection.Count -gt 1)
                {
                    if (($returnTypeSection[1] -like 'http://*') -or 
                        ($returnTypeSection[1] -like 'https://*'))
                    {
                        $typeUrl = $returnTypeSection[1]
                    }
                    else
                    {
                        $typeDesc += $returnTypeSection[1]
                    }
                }

                if ($returnTypeSection.Count -gt 2)
                {
                    @(2..($returnTypeSection.Count - 1)) | ForEach-Object {
                        $typeDesc += $returnTypeSection[$_]
                    }
                }

                $outMaml += '      <command:returnValue>'
                $outMaml += '        <dev:type>'
                $outMaml += '          <maml:name>{0}</maml:name>' -f (EscXmlText $typeName)
                if ($typeUrl -eq $null)
                {
                    $outMaml += '          <maml:uri />'
                }
                else
                {
                    $outMaml += '          <maml:uri>{0}</maml:uri>' -f (EscXmlText $typeUrl)
                }
                $outMaml += '          <maml:description>'
                $outMaml += '            <maml:para></maml:para>'
                $typeDesc | ForEach-Object {
                    $outMaml += '            <maml:para>{0}</maml:para>' -f (EscXmlText $_)
                }
                $outMaml += '          </maml:description>'
                $outMaml += '        </dev:type>'
                $outMaml += '      </command:returnValue>'

                # reset section content holder
                $returnTypeSection = @()
            }
        }
        else
        {
            $outMaml += '      <command:returnValue>'
            $outMaml += '        <dev:type>'
            $outMaml += '          <maml:name>None</maml:name>'
            $outMaml += '          <maml:uri />'
            $outMaml += '          <maml:description>'
            $outMaml += '            <maml:para></maml:para>'
            $outMaml += '          </maml:description>'
            $outMaml += '        </dev:type>'
            $outMaml += '      </command:returnValue>'
        }
        $outMaml += '    </command:returnValues>'

        <#
        $outMaml += '    <command:terminatingErrors />'
        $outMaml += '    <command:nonTerminatingErrors />'
        #>

        if ($helpResult.Role)
        {
            $outMaml += '    <command:role>{0}</command:role>' -f (EscXmlText $helpResult.Role)
        }

        if ($helpResult.Component)
        {
            $outMaml += '    <command:component>{0}</command:component>' -f (EscXmlText $helpResult.Component)
        }

        if ($helpResult.Functionality)
        {
            $outMaml += '    <command:functionality>{0}</command:functionality>' -f (EscXmlText $helpResult.Functionality)
        }

        $outMaml += '    <maml:alertSet>'
        $outMaml += '      <maml:title></maml:title>'
        $outMaml += '      <maml:alert>'
        $helpResult.alertSet.alert | where { $_ -ne $null } | ForEach-Object {
            if ($_.Text)
            {
                $_.Text.Split([Environment]::NewLine) | where { $_ -ne '' } | ForEach-Object {
                    $outMaml += '        <maml:para>{0}</maml:para>' -f (EscXmlText $_)
                }
            }
        }
        $outMaml += '      </maml:alert>'
        $outMaml += '    </maml:alertSet>'

        $outMaml += '    <command:examples>'
        $helpResult.examples.example | where { $_ -ne $null } | ForEach-Object {
            $outMaml += '      <command:example>'
            $outMaml += '        <maml:title>{0}</maml:title>' -f (EscXmlText $_.title)
            $outMaml += '        <maml:introduction>'
            $_.introduction | ForEach-Object {
                if ($_.Text)
                {
                    $_.Text.Split([Environment]::NewLine) | where { $_ -ne '' } | ForEach-Object {
                        $outMaml += '          <maml:para>{0}</maml:para>' -f (EscXmlText $(if ($_.EndsWith(' ')) { $_ } else { $_ + ' ' }))
                    }
                }
            }
            $outMaml += '        </maml:introduction>'

            $codeRemarkBlock = @()
            if ($_.code)
            {
                $codeRemarkBlock += $_.code
            }
            $_.remarks | ForEach-Object {
                if ($_.Text)
                {
                    $_.Text.Split([Environment]::NewLine) | where { $_ -ne '' } | ForEach-Object {
                        $codeRemarkBlock += $_
                    }
                }
            }

            # Split by DESCRIPTION followed by -----
            $codeBlock = @()
            $remarkBlock = @()
            for ($i = 0; $i -lt $codeRemarkBlock.Count; $i++)
            {
                if (($codeRemarkBlock[$i] -eq 'DESCRIPTION') -and 
                    ($i -le ($codeRemarkBlock.Count - 2)) -and 
                    ($codeRemarkBlock[$i + 1] -match '^-----*$'))
                {
                    if ($i -eq ($codeRemarkBlock.Count - 2))
                    {
                        break
                    }

                    @(($i + 2)..($codeRemarkBlock.Count - 1)) | ForEach-Object {
                        $remarkBlock += $codeRemarkBlock[$_]
                    }
                    break
                }
                
                $codeBlock += $codeRemarkBlock[$i]
            }

            $outMaml += '        <dev:code>{0}</dev:code>' -f (EscXmlText ($codeBlock -join [Environment]::NewLine))
            $outMaml += '        <dev:remarks>'
            if ($remarkBlock.Count -gt 0)
            {
                # Need to put this in 1 para, otherwise there's a gap between them when rendered by ps :(
                $outMaml += '          <maml:para>DESCRIPTION{0}-----------{0}{1}</maml:para>' -f [Environment]::NewLine, $remarkBlock[0]
            }

            if ($remarkBlock.Count -gt 1)
            {
                @(1..($remarkBlock.Count - 1)) | ForEach-Object {
                    $outMaml += '          <maml:para>{0}</maml:para>' -f (EscXmlText $remarkBlock[$_])
                }
            }
            $outMaml += '          <maml:para></maml:para>'
            $outMaml += '          <maml:para></maml:para>'
            $outMaml += '          <maml:para></maml:para>'
            $outMaml += '        </dev:remarks>'

            $outMaml += '        <command:commandLines>'
            $outMaml += '          <command:commandLine>'
            $outMaml += '            <command:commandText />'
            $outMaml += '          </command:commandLine>'
            $outMaml += '        </command:commandLines>'
            $outMaml += '      </command:example>'
        }
        $outMaml += '    </command:examples>'

        $outMaml += '    <maml:relatedLinks>'
        $helpResult.relatedLinks.navigationLink | where { $_ -ne $null } | ForEach-Object {
            if ($_.linkText -or $_.uri)
            {
                $outMaml += '      <maml:navigationLink>'
                $outMaml += $(
                    if ($_.linkText)
                    {
                        '        <maml:linkText>{0}</maml:linkText>' -f (EscXmlText $_.linkText)
                    }
                    else
                    {
                        '        <maml:linkText />'
                    }
                )
                $outMaml += $(
                    if ($_.uri)
                    {
                        '        <maml:uri>{0}</maml:uri>' -f (EscXmlText $_.uri)
                    }
                    else
                    {
                        '        <maml:uri />'
                    }
                )
                $outMaml += '      </maml:navigationLink>'
            }
        }
        $outMaml += '    </maml:relatedLinks>'

        $outMaml += '  </command:command>'
    }

    $outMaml += '</helpItems>'

    if (-not $Compress)
    {
        if ($OutFile)
        {
            $outMaml | Set-Content -Path $OutFile -Encoding UTF8
        }
        else
        {
            $outMaml
        }
    }
    else
    {
        $outXml = [xml]$outMaml
        if ($OutFile)
        {
            $outXml.OuterXml | Set-Content -Path $OutFile -Encoding UTF8
        }
        else
        {
            $outXml.OuterXml
        }
    }
}

# -----------
# Export
# -----------
Export-ModuleMember -Function @(
    'ConvertFrom-Maml', 'ConvertTo-Maml'
)
