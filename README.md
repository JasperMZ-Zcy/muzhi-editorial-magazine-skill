# 牧之远见·二维杂志语义图解视频 Skill

这是 `editorial-magazine-explainer-producer` 的私有发行仓库。它把已经验收的二维杂志插画视频流程固化为可迁移的 Codex Skill，包括：真实口播母钟、SRT、全量 Gate 2 审核、独立语义组件、解释文字、Google Flow 分阶段交接、青年明亮音、背景音乐、返工锁定、全片 QA、桌面哈希交付和发布闭环。

## 仓库包含与不包含的内容

仓库包含 Skill 指令、合同模板、校验器、环境检查器和安装脚本。

仓库不包含：知识库正文、视频工程、口播、图片、Flow 成片、字体、音乐、平台账号、Cookies、令牌或任意电脑的绝对路径。这些内容继续通过各自的工作区与同步方式管理。

## 新电脑安装

先在新电脑安装 Git、GitHub CLI 和 Codex，并让 GitHub CLI 登录到有权访问本私有仓库的账号：

```powershell
gh auth login -h github.com -p https -w
```

然后在 PowerShell 执行：

```powershell
$repo = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'CodexSkills\muzhi-editorial-magazine-skill'
New-Item -ItemType Directory -Path (Split-Path $repo -Parent) -Force | Out-Null
gh repo clone JasperMZ-Zcy/muzhi-editorial-magazine-skill $repo
& "$repo\install.ps1"
```

安装器会询问一次“创业之路”工作区根目录，自动生成只保存在本机的 `config/local.json`，并创建当前用户桌面的 `牧之远见-视频预览` 目录。默认安装位置是当前用户的 `.codex\skills\editorial-magazine-explainer-producer`；若设置了 `CODEX_HOME`，则使用该目录。

如果已知工作区路径，可以无交互安装：

```powershell
& "$repo\install.ps1" -WorkspaceRoot 'E:\Workspaces\创业之路' -NonInteractive
```

也可以先设置跨工具通用的工作区环境变量：

```powershell
[Environment]::SetEnvironmentVariable('MUZHI_WORKSPACE_ROOT', 'E:\Workspaces\创业之路', 'User')
```

重新打开终端后，安装器和 Skill 都会优先识别它。

## 更新

保留上述仓库目录时，更新只需：

```powershell
$repo = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'CodexSkills\muzhi-editorial-magazine-skill'
& "$repo\update.ps1"
```

更新脚本只接受快进更新；安装前会校验发行清单。已安装的旧版会整体移动到 `.codex\skill-backups`，本机 `config/local.json` 会被保留。因此更新失败时仍有完整回退副本。

## 环境检查

安装结束后会检查 Python、FFmpeg/FFprobe、Node.js/npm、Git 和 GitHub CLI，只报告缺项，不会擅自安装软件。也可以随时手动运行：

```powershell
& "$env:USERPROFILE\.codex\skills\editorial-magazine-explainer-producer\scripts\check_environment.ps1"
```

## 发布边界

本仓库为私有工作流资产。不要公开仓库，不要把本机配置、账号凭据、平台数据、知识库或用户素材提交进来。
