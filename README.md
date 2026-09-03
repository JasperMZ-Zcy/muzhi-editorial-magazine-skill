# Editorial Magazine Explainer Producer

一套面向教育培训赛道的知识口播视频制作 Skill。

它从选题、定稿文案、证据和最终口播开始，把整条片整理成可审核、可生产的语义镜头：哪些内容该交给WAN、MiniMax或其他图生视频，哪些数字和关系必须用本地组件准确演示，什么时候直接展示官方材料，解释文字何时出现，字幕放在哪里，返工时哪些东西绝对不能动。目标不是“给每句话配一张图”，而是让观众有时间看清、理解并记住。

> A Codex skill for producing editorial-magazine explainer videos in education and training. It turns narration and timed captions into readable semantic scenes, combining deterministic motion graphics, optional Google Flow clips, strong caption hierarchy, revision locks, and evidence-based QA.

![《考研统考名额》成片画面总览](examples/assets/quota-overview.jpg)

当前候选版本：`2.0.0`　许可证：[MIT](LICENSE)　已验证环境：Windows、PowerShell、Codex

## 它解决什么问题

教育知识视频最容易出现的，不是“画面不够多”，而是画面没有真正帮观众理解：

- 一句口播切一套动画，前一个画面还没看懂，下一个已经来了；
- 整张插画只做推拉，动作很多，语义没有推进；
- 名额、比例、步骤和因果关系交给生成模型，数字看起来对，实际口径错；
- 解释文字只是把字幕换几个字再说一遍；
- 手机、图表和气泡明明有信息槽，后期文字却漂在组件上方，像临时贴上去的卡片；
- “把动画放大”被执行成全片统一缩放，结果有的镜头仍然小，有的已经出画、漂移或挡住主视觉；
- 字幕为了塞下一行被压得很小，或者上移后挡住人物和核心动作；
- 用户只要求放大主体，返工却顺手改了 Flow、声音、字幕或时间线；
- 最终检查只靠“我看过了”，没有证据说明到底检查了什么。
- 导演只分语义群，没有把整条口播做成可审核的故事板；正式动画生成后才发现镜头碎、时长不够、转场生硬。
- 图生视频承担了学校名、数字和表格，或者先生成空卡再贴一层漂浮文字，画面和信息像两张皮。
- 一条几秒的生成视频被明显慢放、停住或循环，硬撑更长口播。
- 每条片默认沿用上一条BGM，音乐没有根据当前主题重新设计。

这个 Skill 把这些问题放进一条有审核点、有锁定项、有机器校验的制作流程里。

## 适合什么内容

- 升学规划、考研、高考、留学和职业教育；
- 课程知识、方法论、政策解读和数据口径说明；
- 需要人物、物件、数字、步骤、因果或对比关系的知识口播；
- 已有录音和 SRT，希望直接进入分镜与制作；
- 希望少量使用生成视频，但保留字幕、数字和节奏控制权的团队。

它不适合纯电影短片、MV、真人口型驱动、直播切片或只需要自动套模板的批量视频。

## 核心做法

```text
定稿文案 / 证据包 / 最终口播音频
        ↓
锁定真实母钟、字幕与当天生产时钟
        ↓
选择一条用户已批准母版作为黄金基准
        ↓
人话版导演理解：承诺、观众问题、答案/证据/案例/笑点
        ↓
完整9:16导演故事板：不凑镜头，逐段选择表现路线
        ↓
每条片生成新BGM，拼出从头到尾的有声动态分镜
        ↓
15—20秒最难段真实完成度样片
        ↓
故事板、动态分镜和样片都通过后才批量生产
        ↓
人物/笑点走图生视频；数据走MG/VOX；证据走真实材料或来源图表
        ↓
组件内原生文字、正式合成、完整粗剪、全片QA、母版和发布包
```

几个最重要的原则：

1. 不按字幕逐句换场。一个主构图可以承接多句相关口播，核心结果要留出可辨认时间。
2. 字幕负责原话；解释文字负责判断、分类、因果或结论；对象标签只负责识别当前物件。
3. WAN、MiniMax、Google Flow等图生视频负责人物、情境、笑点、空间和非数据语义；精确数字、公式、名单、步骤和政策正文留在本地MG/VOX、真实材料或来源图表里。
4. Flow、本地组件和整幅插画分别管理，不能全片统一缩放。
5. 手机、图表、名单、气泡等内部文字必须绑定到真实父组件，匹配内部区域、透视、遮罩和运动；不能用漂浮卡片代替。
6. 本地组件以放大 8%–12%为常规目标、约 4%–15%为逐镜微调区间；安全区、主次和观看舒适度高于机械数字。
7. 每轮返工先保留回退版，再写清允许改什么、禁止改什么。
8. Gate 3 不只打勾。资产、组件内文字、最终包围盒、字幕位置、保护区和锁定指纹都要有可核验记录。
9. 重点片必须先过人话版导演理解、完整视觉故事板、全片有声动态分镜和15—20秒真实完成度样片；任一项未批准，禁止批量生图、图生视频和整片合成。
10. 像PPT、像廉价AI、画风混乱、动画僵硬，任何一项命中都立即停止扩量；机器QA不能替代人工审美。
11. 一条片只保留一个导演、一个时间线owner和最多一个技术/资产助手，不允许多个视觉方向并行重做。
12. 文字实现固定分成三类：组件内`InsetText`、独立暖纸`Callout`和品牌收尾`BrandText`；禁止人物/视频/浅纸上的裸白解释字、突兀黑色伪UI遮罩和品牌slogan与普通字幕重复。
13. 完整粗剪按每个实际画面段的进入、核心、退出三种状态做横向审计；最终有`N`段就至少检查`3N`帧。历史项目的19段/57帧只是例子，不是固定配额，也不能只挑好看的画面。
14. 生图容器只在内部信息槽稳定时承载本地文字；同一容器连续两轮出现错位、字号失衡或边框不匹配，立即改为原生组件，不再靠移动坐标反复试错。
15. 不预设章节数、镜头数或单段固定时长。一个可理解画面段可以在同一构图内连续完成多次解释动作；观众看懂以后再切。
16. 单条图生视频连续使用默认不得超过10.0秒；素材短于口播必须提前设计真实续接或替代路线，禁止慢放、尾帧停死、循环或静态闪图补时长。素材回收后直接用FFprobe检查真实视频流和时长。
17. 官方公告、招生目录、复试细则、录取名单和原始数据优先使用真实材料；允许根据已核验数据重画图表，但画面下方必须标出可读来源。真实材料必须经过同一`design.md`的证据载体和转场，不能突然全屏硬贴浏览器或PDF界面。
18. 每条正式片都要按本条主题重新制作或新取得一首无歌词BGM，并记录音乐简报、供应商任务/许可、曲目身份、文件哈希和音频指纹；新曲要检查全部历史项目的BGM登记册，不只和上一条比较。
19. 正常项目从定稿文案、证据和最终口播全部锁定后开始计时，以当天完成母版和发布包为目标；各Gate按效果放行，不按固定分钟降低质量。

当前v2.0.0候选回归：导演故事板43类负向用例、动态素材时长15类、生产总合同40类、真实样片5类全部正确拒绝；旧项目合同自检继续通过。

## 真实案例

### 《考研统考名额》

162.057 秒，21 个稳定镜头，133 条字幕；包含 7 段 Google Flow、12 个本地组件镜头和 2 张整幅插画。

这个案例展示了三种画面的明确分工：Flow 负责“十月才发现”和“走错赛道”等有机情境；本地组件负责 `10 → 2 → 1`、`20 - 12 - 2 - 1 = 5` 等精确口径；整幅插画只做边框内部的轻微放大。字幕朝中心安全区移动，同时逐镜避让人物、动作和解释文字。

![《考研统考名额》六个代表画面](examples/assets/quota-overview.jpg)

### 《如果说不清楚考研要解决什么，先别考》

86.9 秒。这个案例经历了四轮有边界的返工：先把过密主构图压缩成稳定场景，补齐空白气泡和票据，去掉复述字幕的解释文字；再恢复人声档案和背景音乐，删除镜号与内部制作标记；最后只放大本地组件并重做单行字幕边界，Flow 和时间线保持不动。

![《如果说不清楚考研要解决什么，先别考》六个代表画面](examples/assets/purpose-overview.jpg)

前两条案例的逐图说明见 [examples/README.md](examples/README.md)。截图均来自已经发布并通过最终审核的编码母版，没有使用概念图替代成片。

### 《双非友好院校榜》

129.433 秒，22 个镜头，包含 7 段 Google Flow、14 个本地组件镜头和 1 张整幅插画。这个案例把一个很容易被忽略的后期问题固化进了 Skill：手机、网页、名单、图表、票据和气泡里的文字，必须真正写进组件内部；完成父层、透视、遮罩和运动绑定后，再把完整视觉组逐镜放大和居中。最终空白沟通容器、漂浮假卡、文字溢出、裁边、视觉漂移和主视觉遮挡均为 0。

### 《0854双非考研友好逆袭院校榜单》

327.616秒。最终母版、文字、声音和三平台发布包均通过，但前期因缺少完整导演故事板和有声动态分镜，曾出现风格漂移、镜头碎切、图生视频短于口播、空卡后贴字、数据动画不足和大量后置检查。v2.0.0据此新增导演故事板、语义表现路由、全片有声动态分镜、图生视频时长覆盖、官方来源/来源图表和每片新BGM硬门。

## 安装

### 独立模式：适合大多数公开用户

先安装 Git、Codex、Python、FFmpeg/FFprobe。Node.js 与 npm 用于 Remotion 合成，建议一并安装。

在 PowerShell 中执行：

```powershell
$repo = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'CodexSkills\muzhi-editorial-magazine-skill'
git clone https://github.com/JasperMZ-Zcy/muzhi-editorial-magazine-skill.git $repo
& "$repo\install.ps1" -Standalone -NonInteractive
```

独立模式不要求安装牧之远见的知识库或 OpenMontage。Skill 会使用仓库自带的合同、参考资料和校验器；制作具体项目时，只需要告诉 Codex 录音、SRT、文案和项目目录在哪里。

## 和教培动画素材库一起使用

如果你已经做过几条视频，建议在进入制作前先查一次 [教培动画素材库](https://github.com/JasperMZ-Zcy/education-animation-asset-library)。

素材库负责把可拆分复用的组件、字幕结构、镜头规则、提示词骨架和制作合同收好，并保留来源、复用条件和公开边界；本 Skill 负责把这一条视频的录音、SRT、镜头、组件、字幕和最终验收做完整。

~~~text
先在教培动画素材库检索可复用的结构
        ↓
用本 Skill 结合新的事实、口播和叙事完成制作
        ↓
把这次新长出的通用组件、合同和规则再回填素材库
~~~

两者不会让视频机械复刻。素材库保存的是可复用的结构和经验；题目、证据、叙事、视觉判断和最终画面，仍然要为每条视频单独完成。

### 工作区模式：适合已有完整生产工作区的用户

如果你的工作区根目录同时包含 `AI_START_HERE.md` 与 `OpenMontage`，可以运行：

```powershell
& "$repo\install.ps1" -WorkspaceRoot 'E:\Workspaces\创业之路' -NonInteractive
```

安装器会把本机路径写入未纳入 Git 的 `config/local.json`。更换电脑、盘符或用户名时，不需要修改 Skill 正文。

### 安装后检查

```powershell
& "$env:USERPROFILE\.codex\skills\editorial-magazine-explainer-producer\scripts\check_environment.ps1"
python "$env:USERPROFILE\.codex\skills\editorial-magazine-explainer-producer\scripts\validate_editorial_project.py" --self-test
python "$env:USERPROFILE\.codex\skills\editorial-magazine-explainer-producer\scripts\validate_motion_pilot.py" --self-test
python "$env:USERPROFILE\.codex\skills\editorial-magazine-explainer-producer\scripts\test_director_storyboard.py"
python "$env:USERPROFILE\.codex\skills\editorial-magazine-explainer-producer\scripts\test_dynamic_asset_duration.py"
python "$env:USERPROFILE\.codex\skills\editorial-magazine-explainer-producer\scripts\test_production_enforcement.py"
```

看到 `SELF-TEST PASS` 后，重新打开一个 Codex 任务。

## 怎么开始第一条视频

可以直接说：

> 按杂志插画产线做。这是定稿文案、证据和最终口播音频。先告诉我你怎么理解整条片，再给完整9:16导演故事板和有声动态分镜；每段说明为什么用图生视频、MG/VOX、真实材料或来源图表。为本条重新做BGM。故事板、动态分镜和最难段真实样片通过前不要批量生产。

也可以从文案或已有项目开始：

> 用教育培训杂志插画风格做这篇政策解读。数字和表格要准确，Google Flow 只用在少量人物情境。先停在真实动态样片，样片过了再做完整粗剪。

Skill 会先确认目标、素材、审美、声音、Flow 使用范围、交付形式和审核方式，不会在信息不足时直接开始生成。

## Google Flow 如何协作

Flow不是固定供应商名称，而是“需要有机动作”的镜头类别。完整故事板和有声动态分镜先决定哪些段落真的需要图生视频；15—20秒真实完成度样片通过后，才为批准画面段准备生成材料。若工作区已经配置用户批准的自动供应商，由制作部门直接提交、续查、下载和验收，Google Flow作为手动回退：

- 每镜一张无字准备态参考图；
- 每镜一份独立完整提示词；
- 对应口播、建议时长、动作地标和回收命名；
- 禁止自动字幕、乱码、水印和源声音。

回收后保留原片，移除源音轨，统一规格，并按真实口播动作窗口进入时间线。数字、解释文字和字幕仍由本地控制。本地等待超时优先按原任务ID续查，不重复提交；伪UI可用固定遮罩修复，人物、手部、画风或核心动作损坏才整条重生。

## 更新与回退

```powershell
& "$repo\update.ps1"
```

更新只接受 Git 快进。安装前会核对发行清单与文件哈希；旧版整体保存在 `<CODEX_HOME>\skill-backups`，本机配置继续保留。

## 仓库内容

- `skill/editorial-magazine-explainer-producer/`：Skill 本体；
- `assets/templates/`：项目、逐镜、Flow、返工和 QA 合同模板；
- `assets/templates/director-storyboard.template.json`：导演理解、完整故事板、视觉路由、有声动态分镜和每片新BGM合同；
- `scripts/validate_director_storyboard.py`：故事板计划门与批量生产门校验器；
- `scripts/validate_dynamic_asset_duration.py`：按真实文件和FFprobe检查动态素材时长、续接、慢放、停死和循环；
- `scripts/fingerprint_bgm.py`：为新BGM生成原始哈希、音频特征指纹和滚动窗口指纹，供全项目登记册判重；
- `assets/templates/bgm-registry.template.json`：记录所有已通过/已发布项目的曲目身份、原始哈希和音频指纹，阻止隔片复用与改码复用；
- `scripts/validate_editorial_project.py`：只读合同与证据校验器；
- `scripts/validate_motion_pilot.py`：真实动态样片与批量生产放行校验器；
- `install.ps1` / `update.ps1`：安装、更新和回退；
- `examples/`：经过授权的已发布案例截图与说明。

仓库不包含项目工程、完整视频、口播音频、Flow 原片、字体、音乐、平台后台数据、账号、Cookie、令牌或任何电脑的本机配置。

## 参与改进

欢迎提交 Issue 或 Pull Request。比较有价值的反馈包括：

- 某类教育内容在哪个 Gate 最容易卡住；
- 字幕、解释文字或组件动画出现了什么具体可复现的问题；
- Windows 独立安装或升级失败的完整错误信息；
- 能够转成合同字段或负向测试的真实制作经验。

请不要在 Issue 中上传学生隐私、未发布课程、平台后台截图、账号信息或商业素材。

## 许可证

代码、Skill 指令、模板和文档采用 [MIT License](LICENSE)。案例截图用于说明本项目的实际输出效果，版权归牧之远见所有；请勿把案例画面单独打包、转售或冒充自己的作品。

Google Flow、Remotion、Codex 及相关名称属于各自权利人。本项目与这些产品的官方团队不存在隶属或背书关系。
