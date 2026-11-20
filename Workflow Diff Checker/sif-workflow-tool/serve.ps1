param([int]$Port = 8765)

$root = Split-Path -Parent $PSScriptRoot
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://127.0.0.1:$Port/")
$listener.Start()
Write-Host "Open http://127.0.0.1:$Port/sif-workflow-tool/index.html"
Write-Host "Press Ctrl+C to stop."
try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $path = $context.Request.Url.AbsolutePath
        $file = switch ($path) {
            "/sif-workflow-tool/index.html" { Join-Path $PSScriptRoot "index.html" }
            "/demo%20sif.xml" { Join-Path $root "demo sif.xml" }
            "/demo sif.xml" { Join-Path $root "demo sif.xml" }
            "/demo%20task%20sif.xml" { Join-Path $root "demo task sif.xml" }
            "/demo task sif.xml" { Join-Path $root "demo task sif.xml" }
            "/sif-workflow-tool/tests.html" { Join-Path $PSScriptRoot "tests.html" }
            "/sif-workflow-tool/fixtures/sample.sif" { Join-Path $PSScriptRoot "fixtures\sample.sif" }
            { $_ -match '^/sif-workflow-tool/fixtures/variations/(identical|functional|added-removed|audit-layout|duplicate-names|broken-reference|conflicting-endpoint|invalid-xml)\.sif$' } { Join-Path $PSScriptRoot ("fixtures\variations\" + [System.IO.Path]::GetFileName($path)) }
            default { $null }
        }
        try {
            if ($null -eq $file -or -not (Test-Path -LiteralPath $file -PathType Leaf)) {
                $context.Response.StatusCode = 404
            } else {
                $bytes = [System.IO.File]::ReadAllBytes($file)
                $context.Response.ContentType = if ($file.EndsWith(".html")) { "text/html; charset=utf-8" } else { "application/xml; charset=utf-8" }
                $context.Response.ContentLength64 = $bytes.Length
                $context.Response.OutputStream.Write($bytes, 0, $bytes.Length)
            }
        } finally {
            $context.Response.Close()
        }
    }
} finally {
    $listener.Stop()
    $listener.Close()
}
