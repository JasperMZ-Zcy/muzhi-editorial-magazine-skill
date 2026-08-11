[CmdletBinding()]
param(
    [string]$ConfigPath = "",
    [switch]$Json
)

$ErrorActionPreference = 'Stop'
$skillRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ConfigPath)) {
    $ConfigPath = Join-Path $skillRoot 'config\local.json'
}

function Get-ToolResult {
    param(
        [string]$Name,
        [string]$Command,
        [string[]]$VersionArgs,
        [bool]$Required
    )
    $available = $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
    $version = ''
    if ($available) {
        try {
            $version = ((& $Command @VersionArgs 2>&1) | Select-Object -First 1).ToString().Trim()
        } catch {
            $version = '已找到，但版本读取失败'
        }
    }
    [ordered]@{
        name = $Name
        command = $Command
        required = $Required
        available = $available
        version = $version
    }
}

$checks = @(
    Get-ToolResult -Name 'Python（合同校验）' -Command 'python' -VersionArgs @('--version') -Required $true
    Get-ToolResult -Name 'FFmpeg（视频与音频处理）' -Command 'ffmpeg' -VersionArgs @('-version') -Required $true
    Get-ToolResult -Name 'FFprobe（媒体质检）' -Command 'ffprobe' -VersionArgs @('-version') -Required $true
    Get-ToolResult -Name 'Node.js（Remotion）' -Command 'node' -VersionArgs @('--version') -Required $false
    Get-ToolResult -Name 'npm（Remotion）' -Command 'npm' -VersionArgs @('--version') -Required $false
    Get-ToolResult -Name 'Git（更新）' -Command 'git' -VersionArgs @('--version') -Required $false
    Get-ToolResult -Name 'GitHub CLI（可选）' -Command 'gh' -VersionArgs @('--version') -Required $false
)

$configStatus = [ordered]@{
    path = $ConfigPath
    exists = Test-Path -LiteralPath $ConfigPath -PathType Leaf
    valid = $false
    mode = ''
    workspace_root = ''
    openmontage_root = ''
    knowledge_base_root = ''
    desktop_review_root = ''
    desktop_review_exists = $false
}

if ($configStatus.exists) {
    try {
        $config = Get-Content -Raw -Encoding UTF8 -LiteralPath $ConfigPath | ConvertFrom-Json
        $configStatus.mode = [string]$config.mode
        if ([string]::IsNullOrWhiteSpace($configStatus.mode)) {
            $configStatus.mode = if ([string]::IsNullOrWhiteSpace([string]$config.workspace_root)) { 'standalone' } else { 'workspace' }
        }
        $configStatus.workspace_root = [string]$config.workspace_root
        $configStatus.openmontage_root = [string]$config.openmontage_root
        $configStatus.knowledge_base_root = [string]$config.knowledge_base_root
        $configStatus.desktop_review_root = [string]$config.desktop_review_root
        $configStatus.desktop_review_exists = Test-Path -LiteralPath $configStatus.desktop_review_root -PathType Container
        if ($configStatus.mode -eq 'standalone') {
            $configStatus.valid = $configStatus.desktop_review_exists
        } elseif ($configStatus.mode -eq 'workspace') {
            $configStatus.valid =
                (Test-Path -LiteralPath $configStatus.workspace_root -PathType Container) -and
                (Test-Path -LiteralPath $configStatus.openmontage_root -PathType Container) -and
                (Test-Path -LiteralPath $configStatus.knowledge_base_root -PathType Container) -and
                $configStatus.desktop_review_exists
        }
    } catch {
        $configStatus.valid = $false
    }
}

$result = [ordered]@{
    status = if (($checks | Where-Object { $_.required -and -not $_.available }).Count -eq 0 -and $configStatus.valid) { 'ready' } else { 'attention_required' }
    skill_root = $skillRoot
    tools = $checks
    local_config = $configStatus
}

if ($Json) {
    $result | ConvertTo-Json -Depth 6
    return
}

Write-Host '环境检查：' -ForegroundColor Cyan
foreach ($check in $checks) {
    $mark = if ($check.available) { '√' } else { '×' }
    $requirement = if ($check.required) { '必需' } else { '建议' }
    $detail = if ($check.available) { $check.version } else { '未找到' }
    Write-Host "[$mark] $($check.name)（$requirement）：$detail"
}
$configMark = if ($configStatus.valid) { '√' } else { '×' }
Write-Host "[$configMark] 本机运行模式与配置（$($configStatus.mode)）：$($configStatus.path)"
if (-not $configStatus.valid) {
    Write-Warning 'Skill 已安装，但环境或本机配置尚不完整；缺项不会被自动安装。'
}
