$ErrorActionPreference = 'Stop'
$base = Join-Path $PSScriptRoot 'fixtures\sample.sif'
$out = Join-Path $PSScriptRoot 'fixtures\variations'
New-Item -ItemType Directory -Path $out -Force | Out-Null

function New-Fixture([string]$name, [scriptblock]$change) {
    $xml = New-Object System.Xml.XmlDocument
    $xml.PreserveWhitespace = $true
    $xml.Load($base)
    & $change $xml
    $xml.Save((Join-Path $out "$name.sif"))
    Write-Host "Created $name.sif"
}

New-Fixture 'functional' {
    param($doc)
    $doc.SelectSingleNode("//WF_STEP[@NAME='Set Test Properties']").SetAttribute('BUSINESS_SERVICE_METHOD', 'NewMethod')
    $doc.SelectSingleNode("//WF_STEP_I_O_ARGUMENT[@NAME='O:Set Test Properties1']").SetAttribute('VALUE_SEARCH_SPECIFICATION', 'N')
    $doc.SelectSingleNode("//WF_STEP_BRANCH[@NAME='N']").SetAttribute('EXPRESSION', "Changed expression")
    $doc.SelectSingleNode("//WF_BRANCH_CRITERIA_VALUE[@NAME='N31']").SetAttribute('LO_CHAR1', 'N')
    $doc.SelectSingleNode("//WF_PROCESS_PROP[@NAME='Test Property 1']").SetAttribute('DATA_TYPE', 'NUMBER')
    $doc.SelectSingleNode('//WORKFLOW_PROCESS').SetAttribute('STATUS', 'IN_PROGRESS')
}

New-Fixture 'added-removed' {
    param($doc)
    $workflow = $doc.SelectSingleNode('//WORKFLOW_PROCESS')
    $step = $doc.CreateElement('WF_STEP')
    $step.SetAttribute('NAME', 'New Step')
    $step.SetAttribute('TYPE', 'TASK')
    [void]$workflow.AppendChild($step)
    $removed = $doc.SelectSingleNode("//WF_PROCESS_PROP[@NAME='Test Property 1']")
    [void]$removed.ParentNode.RemoveChild($removed)
    $removedBranch = $doc.SelectSingleNode("//WF_STEP_BRANCH[@NAME='Y']")
    [void]$removedBranch.ParentNode.RemoveChild($removedBranch)
}

New-Fixture 'audit-layout' {
    param($doc)
    $step = $doc.SelectSingleNode("//WF_STEP[@NAME='Start']")
    $step.SetAttribute('UPDATED_BY', 'ANOTHER_USER')
    $step.SetAttribute('LAYOUT', 'uninterpreted-test-layout')
}

New-Fixture 'duplicate-names' {
    param($doc)
    $step = $doc.SelectSingleNode("//WF_STEP[@NAME='Start']")
    [void]$step.ParentNode.AppendChild($step.CloneNode($true))
}

New-Fixture 'broken-reference' {
    param($doc)
    $branch = $doc.SelectSingleNode("//WF_STEP_BRANCH[@NAME='Go']")
    $branch.SetAttribute('TO_STEP_NAME', 'Missing Step')
    $branch.SelectSingleNode('WF_BRANCH_CONNECTOR').SetAttribute('TO_STEP_NAME', 'Missing Step')
}

New-Fixture 'conflicting-endpoint' {
    param($doc)
    $doc.SelectSingleNode("//WF_STEP_BRANCH[@NAME='Go']/WF_BRANCH_CONNECTOR").SetAttribute('TO_STEP_NAME', 'End 0')
}

Copy-Item -LiteralPath $base -Destination (Join-Path $out 'identical.sif') -Force
[System.IO.File]::WriteAllText((Join-Path $out 'invalid-xml.sif'), '<REPOSITORY><PROJECT></REPOSITORY>')
