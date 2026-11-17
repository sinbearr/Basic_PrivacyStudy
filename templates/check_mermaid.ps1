<#
.SYNOPSIS
  Markdown 파일의 ```mermaid 블록 안에서 쌍따옴표로 감싸지 않은 노드 텍스트와 엣지 라벨을 찾습니다.
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\templates\check_mermaid.ps1
  powershell -ExecutionPolicy Bypass -File .\templates\check_mermaid.ps1 -Path .\chapters
#>
param([string]$Path = ".")

$nodePattern = '\b[A-Za-z][A-Za-z0-9_]*(\[\[|\[\(|\(\(|\(\[|\{\{|\[|\{|\(|>)(?!["\[\{\(])'
$edgePattern = '(-->|---|==>|-\.->)\|(?!")'
$found = 0

Get-ChildItem -Path $Path -Recurse -Filter *.md | ForEach-Object {
    $file = $_.FullName
    $inMermaid = $false
    $lineNo = 0
    foreach ($line in [System.IO.File]::ReadAllLines($file, [System.Text.Encoding]::UTF8)) {
        $lineNo++
        if ($line -match '^\s*```mermaid') { $inMermaid = $true; continue }
        if ($inMermaid -and $line -match '^\s*```') { $inMermaid = $false; continue }
        if (-not $inMermaid) { continue }
        if ($line -match '^\s*(classDef|class|style|linkStyle|%%|flowchart|graph|sequenceDiagram|direction)\b') { continue }
        # 쌍따옴표 안의 글자는 지우고 나머지 구조만 검사합니다.
        $stripped = [regex]::Replace($line, '"[^"]*"', '""')
        if ($stripped -match $nodePattern -or $stripped -match $edgePattern) {
            $found++
            Write-Output ("{0}:{1}: {2}" -f $file, $lineNo, $line.Trim())
        }
    }
}

if ($found -eq 0) { Write-Output "OK: 따옴표 누락이 의심되는 Mermaid 줄이 없습니다." }
else { Write-Output ("총 {0}줄을 확인하세요." -f $found); exit 1 }
