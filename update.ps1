[CmdletBinding()]
param(
    [string]$CodexHome = "",
    [string]$WorkspaceRoot = "",
    [switch]$NonInteractive,
    [switch]$SkipEnvironmentCheck
)

$ErrorActionPreference = 'Stop'
$repoRoot = [IO.Path]::GetFullPath($PSScriptRoot)
$gitDirectory = Join-Path $repoRoot '.git'
if (-not (Test-Path -LiteralPath $gitDirectory -PathType Container)) {
    throw '当前目录不是通过 Git 克隆的仓库。请重新运行 README 中的新电脑安装命令。'
}

& git -C $repoRoot pull --ff-only
if ($LASTEXITCODE -ne 0) {
    throw 'GitHub 更新失败；没有改动已安装的 Skill。'
}

$installArgs = @{}
if (-not [string]::IsNullOrWhiteSpace($CodexHome)) { $installArgs.CodexHome = $CodexHome }
if (-not [string]::IsNullOrWhiteSpace($WorkspaceRoot)) { $installArgs.WorkspaceRoot = $WorkspaceRoot }
if ($NonInteractive) { $installArgs.NonInteractive = $true }
if ($SkipEnvironmentCheck) { $installArgs.SkipEnvironmentCheck = $true }
& (Join-Path $repoRoot 'install.ps1') @installArgs
