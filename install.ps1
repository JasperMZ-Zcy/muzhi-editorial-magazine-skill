[CmdletBinding()]
param(
    [string]$CodexHome = "",
    [string]$WorkspaceRoot = "",
    [switch]$NonInteractive,
    [switch]$SkipEnvironmentCheck
)

$ErrorActionPreference = 'Stop'
$skillName = 'editorial-magazine-explainer-producer'
$repoRoot = [IO.Path]::GetFullPath($PSScriptRoot)
$sourceRoot = Join-Path $repoRoot "skill\$skillName"
$manifestPath = Join-Path $repoRoot 'release-manifest.json'

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    $parent = Split-Path -Parent $Path
    if ($parent) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    [IO.File]::WriteAllText($Path, $Content, [Text.UTF8Encoding]::new($false))
}

function Resolve-MuzhiWorkspace {
    param([string]$Candidate)
    if ([string]::IsNullOrWhiteSpace($Candidate)) {
        return $null
    }
    if (-not (Test-Path -LiteralPath $Candidate -PathType Container)) {
        throw "工作区目录不存在：$Candidate"
    }
    $resolved = (Resolve-Path -LiteralPath $Candidate).Path
    if ((Split-Path -Leaf $resolved) -eq 'OpenMontage') {
        $resolved = Split-Path -Parent $resolved
    }
    $openMontage = Join-Path $resolved 'OpenMontage'
    $entry = Join-Path $resolved 'AI_START_HERE.md'
    if (-not (Test-Path -LiteralPath $openMontage -PathType Container)) {
        throw "所选目录不是有效工作区，缺少 OpenMontage：$resolved"
    }
    if (-not (Test-Path -LiteralPath $entry -PathType Leaf)) {
        throw "所选目录不是有效工作区，缺少 AI_START_HERE.md：$resolved"
    }
    return [IO.Path]::GetFullPath($resolved)
}

function Find-MuzhiWorkspace {
    $cursor = Get-Item -LiteralPath (Get-Location).Path
    while ($null -ne $cursor) {
        $openMontage = Join-Path $cursor.FullName 'OpenMontage'
        $entry = Join-Path $cursor.FullName 'AI_START_HERE.md'
        if ((Test-Path -LiteralPath $openMontage -PathType Container) -and (Test-Path -LiteralPath $entry -PathType Leaf)) {
            return $cursor.FullName
        }
        $cursor = $cursor.Parent
    }
    $documentsCandidate = Join-Path ([Environment]::GetFolderPath('MyDocuments')) '创业之路'
    if ((Test-Path -LiteralPath (Join-Path $documentsCandidate 'OpenMontage') -PathType Container) -and
        (Test-Path -LiteralPath (Join-Path $documentsCandidate 'AI_START_HERE.md') -PathType Leaf)) {
        return $documentsCandidate
    }
    return $null
}

function Assert-ReleaseIntegrity {
    if (-not (Test-Path -LiteralPath $sourceRoot -PathType Container)) {
        throw "发行包缺少 Skill 目录：$sourceRoot"
    }
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "发行包缺少 release-manifest.json，拒绝安装。"
    }
    $manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath $manifestPath | ConvertFrom-Json
    if ($manifest.skill_name -ne $skillName) {
        throw "发行清单中的 Skill 名称不匹配。"
    }
    $repoPrefix = $repoRoot.TrimEnd('\') + '\'
    $listedFiles = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $manifest.files) {
        $relative = [string]$entry.path
        [void]$listedFiles.Add($relative.Replace('\', '/'))
        $candidate = [IO.Path]::GetFullPath((Join-Path $repoRoot ($relative -replace '/', '\')))
        if (-not $candidate.StartsWith($repoPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            throw "发行清单包含越界路径：$relative"
        }
        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            throw "发行清单中的文件不存在：$relative"
        }
        $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $candidate).Hash.ToLowerInvariant()
        if ($actual -ne ([string]$entry.sha256).ToLowerInvariant()) {
            throw "发行文件哈希不匹配：$relative"
        }
    }
    foreach ($file in Get-ChildItem -Recurse -File -LiteralPath $sourceRoot) {
        $relative = $file.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
        if (-not $listedFiles.Contains($relative)) {
            throw "Skill 源目录含有未列入发行清单的文件，拒绝安装：$relative"
        }
    }
    return $manifest
}

$manifest = Assert-ReleaseIntegrity

if ([string]::IsNullOrWhiteSpace($CodexHome)) {
    if (-not [string]::IsNullOrWhiteSpace($env:CODEX_HOME)) {
        $CodexHome = $env:CODEX_HOME
    } else {
        $CodexHome = Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex'
    }
}
$CodexHome = [IO.Path]::GetFullPath($CodexHome)
$skillsRoot = Join-Path $CodexHome 'skills'
$destination = Join-Path $skillsRoot $skillName
$skillsPrefix = [IO.Path]::GetFullPath($skillsRoot).TrimEnd('\') + '\'
$destinationFull = [IO.Path]::GetFullPath($destination)
if (-not $destinationFull.StartsWith($skillsPrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw "安装目标越出 Codex skills 目录，拒绝安装：$destinationFull"
}

$existingConfigPath = Join-Path $destination 'config\local.json'
$existingConfig = $null
if (Test-Path -LiteralPath $existingConfigPath -PathType Leaf) {
    try {
        $existingConfig = Get-Content -Raw -Encoding UTF8 -LiteralPath $existingConfigPath | ConvertFrom-Json
    } catch {
        Write-Warning "现有本机配置无法解析，将重新配置：$existingConfigPath"
    }
}

$preserveExistingConfig = $false
if ([string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
    if (-not [string]::IsNullOrWhiteSpace($env:MUZHI_WORKSPACE_ROOT)) {
        $WorkspaceRoot = $env:MUZHI_WORKSPACE_ROOT
    } elseif ($null -ne $existingConfig -and -not [string]::IsNullOrWhiteSpace([string]$existingConfig.workspace_root)) {
        $WorkspaceRoot = [string]$existingConfig.workspace_root
        $preserveExistingConfig = $true
    } else {
        $WorkspaceRoot = Find-MuzhiWorkspace
    }
}

if ([string]::IsNullOrWhiteSpace($WorkspaceRoot) -and -not $NonInteractive) {
    $WorkspaceRoot = Read-Host '请输入“创业之路”工作区根目录（其中包含 OpenMontage 和 AI_START_HERE.md）'
}

$resolvedWorkspace = $null
if (-not [string]::IsNullOrWhiteSpace($WorkspaceRoot)) {
    $resolvedWorkspace = Resolve-MuzhiWorkspace -Candidate $WorkspaceRoot
} elseif ($NonInteractive) {
    Write-Warning '未配置工作区；Skill 已安装，但第一次制作视频前仍需配置工作区路径。'
}

New-Item -ItemType Directory -Path $skillsRoot -Force | Out-Null
$stagingRoot = Join-Path $CodexHome '.skill-install-staging'
New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null
$staging = Join-Path $stagingRoot ("$skillName-" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $staging -Force | Out-Null

Get-ChildItem -Force -LiteralPath $sourceRoot | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $staging -Recurse -Force
}

if ($preserveExistingConfig -and $null -ne $existingConfig) {
    New-Item -ItemType Directory -Path (Join-Path $staging 'config') -Force | Out-Null
    Copy-Item -LiteralPath $existingConfigPath -Destination (Join-Path $staging 'config\local.json') -Force
} elseif ($null -ne $resolvedWorkspace) {
    $desktopRoot = [Environment]::GetFolderPath('Desktop')
    $desktopReviewRoot = Join-Path $desktopRoot '牧之远见-视频预览'
    New-Item -ItemType Directory -Path $desktopReviewRoot -Force | Out-Null
    $config = [ordered]@{
        schema_version = 1
        skill_name = $skillName
        workspace_root = $resolvedWorkspace
        openmontage_root = Join-Path $resolvedWorkspace 'OpenMontage'
        knowledge_base_root = Join-Path $resolvedWorkspace 'OpenMontage\创业知识库'
        desktop_review_root = $desktopReviewRoot
        configured_at_utc = [DateTime]::UtcNow.ToString('o')
    }
    Write-Utf8NoBom -Path (Join-Path $staging 'config\local.json') -Content ($config | ConvertTo-Json -Depth 5)
} elseif ($null -ne $existingConfig) {
    New-Item -ItemType Directory -Path (Join-Path $staging 'config') -Force | Out-Null
    Copy-Item -LiteralPath $existingConfigPath -Destination (Join-Path $staging 'config\local.json') -Force
}

$backupPath = $null
$movedExisting = $false
try {
    if (Test-Path -LiteralPath $destination -PathType Container) {
        $backupRoot = Join-Path $CodexHome 'skill-backups'
        New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $backupPath = Join-Path $backupRoot "$skillName-$stamp"
        $suffix = 1
        while (Test-Path -LiteralPath $backupPath) {
            $backupPath = Join-Path $backupRoot "$skillName-$stamp-$suffix"
            $suffix += 1
        }
        Move-Item -LiteralPath $destination -Destination $backupPath
        $movedExisting = $true
    }
    Move-Item -LiteralPath $staging -Destination $destination
} catch {
    if ($movedExisting -and -not (Test-Path -LiteralPath $destination) -and $null -ne $backupPath) {
        Move-Item -LiteralPath $backupPath -Destination $destination
    }
    throw
}

$installedSkillPath = Join-Path $destination 'SKILL.md'
if (-not (Test-Path -LiteralPath $installedSkillPath -PathType Leaf)) {
    throw "安装完成后未找到 SKILL.md：$installedSkillPath"
}

Write-Host "安装完成：$destination" -ForegroundColor Green
Write-Host "版本：$($manifest.version)"
if ($null -ne $backupPath) {
    Write-Host "上一版本回退副本：$backupPath"
}

if (-not $SkipEnvironmentCheck) {
    $environmentCheck = Join-Path $destination 'scripts\check_environment.ps1'
    if (Test-Path -LiteralPath $environmentCheck -PathType Leaf) {
        & $environmentCheck
    }
}
