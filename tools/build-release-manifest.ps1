[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$skillName = 'editorial-magazine-explainer-producer'
$skillRoot = Join-Path $repoRoot "skill\$skillName"
$versionPath = Join-Path $repoRoot 'VERSION'
$manifestPath = Join-Path $repoRoot 'release-manifest.json'

if (-not (Test-Path -LiteralPath $skillRoot -PathType Container)) {
    throw "Skill 目录不存在：$skillRoot"
}
if (-not (Test-Path -LiteralPath $versionPath -PathType Leaf)) {
    throw "VERSION 不存在：$versionPath"
}

$version = (Get-Content -Raw -Encoding UTF8 -LiteralPath $versionPath).Trim()
$files = @(
    Get-ChildItem -Recurse -File -LiteralPath $skillRoot |
        Where-Object {
            $_.FullName -notmatch '[\\/]config[\\/]local\.json$' -and
            $_.FullName -notmatch '[\\/]__pycache__[\\/]' -and
            $_.Extension -ne '.pyc'
        } |
        Sort-Object FullName |
        ForEach-Object {
            $relative = $_.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
            [ordered]@{
                path = $relative
                sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash.ToLowerInvariant()
                bytes = $_.Length
            }
        }
)

$manifest = [ordered]@{
    schema_version = 1
    skill_name = $skillName
    version = $version
    generated_at_utc = [DateTime]::UtcNow.ToString('o')
    file_count = $files.Count
    files = $files
}

[IO.File]::WriteAllText(
    $manifestPath,
    ($manifest | ConvertTo-Json -Depth 6),
    [Text.UTF8Encoding]::new($false)
)
Write-Host "已生成发行清单：$manifestPath（$($files.Count) 个文件）"
