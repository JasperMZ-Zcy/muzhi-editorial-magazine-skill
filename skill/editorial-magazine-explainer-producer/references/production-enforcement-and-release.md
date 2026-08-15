# 生产强制合同与 Gate 3.5 发布包

## 四层规则优先级

每个项目必须把要求分成四层并写入 `production-enforcement.json`：

1. `immutable_core`：母钟、字幕准确、Gate 2 真暂停、语义动画、图层退场、字幕可读、语音优先配乐、完整 QA、发布另授权；任何项目不得削弱。
2. `project_style`：本条片的配色、人物、背景、镜头家族、数据图表和声音档案；只能在核心规则之上具体化。
3. `additive_requirements`：用户本轮新增要求；默认只做加法，不能用“新增风格”抵消核心规则。
4. `revision_scope`：返工唯一允许修改项；范围外内容继续锁定。

若后层与前层冲突，停止并取得用户对具体冲突的明确批准。不得默默降级固定规程。

## 分阶段强制调用

- 启动：运行旧项目合同校验器，建立 `production-enforcement.json`，声明四层规则和第一个未完成 Gate。
- Gate 2：逐镜填满语义、五个时间锚点、六阶段生命周期、文字职责、三块包围盒与证据；运行生产校验器。失败就停止，不渲染。
- 正式制作：动作按 `actionCue` 进入，解释按 `textCue` 进入，结论按 `resultCue` 落稳，旧层最迟在 `exitCue` 完全退出。
- 声音：分别保存人声、旁链后 BGM、最终混音；测全片、普通段、密集段和 CTA 段，不能只看总响度。
- Gate 3：绑定最终编码文件、连续区段证据、完整观看记录、桌面副本和真实哈希；布尔值没有证据文件不算通过。
- Gate 3.5：成片通过后制作发布包，仍不获得平台发布权。

正式模式必须运行：

```powershell
python "<SKILL_ROOT>\scripts\validate_production_enforcement.py" --manifest <PROJECT_ROOT>\artifacts\production-enforcement.json
```

`schema_version` 低于 `2.0`、`mode` 不是 `production`、证据缺失或任何硬规则失败，均不得进入下一 Gate。旧 manifest 只允许历史读取，不能解锁新生产或返工。

## 每镜最小机器合同

每镜至少包含：

- `semantic.subject/action/object/turn/result/audience_takeaway`；
- `timing.sceneStart/actionCue/textCue/resultCue/exitCue`，且动作不得早于关键词允许窗口；
- `lifecycle.enter/settle/act_or_receive/yield/resolve/exit`；
- `layout.main_visual_bbox/explanation_bbox/caption_bbox`、最小间距、安全区、主视觉填充和遮挡数；
- `text.caption/highlight/explanation/form/role`，说明高亮是完整关键词还是逐字高亮；
- `layers.previous_exited_before_next_main/lingering_layer_count`；
- 至少一个真实证据文件和 SHA-256。

解释文字不是字幕的第二份抄写。必需解释不得因为避让被删除；它可以是印章、报刊短栏、侧注、阶梯、路径、对比栏、局部揭示等，但不得全片只用同一张卡片或长期悬浮顶部标题。孤立的大号“一/二/三”只有在数字本身就是语义对象并经逐镜批准时才允许。

## 声音硬门槛

牧之远见知识口播的默认起点：人声约 `-16 LUFS`；旁链后 BGM 全片约 `-36 至 -30 LUFS`，通常比人声低约 `14–22 dB`。密集段可再退、CTA 可克制，但任何段落不能因为总响度合格而实质听不见。最终以清晰口播、可感知氛围和人工完整试听同时通过为准。

人声、BGM 和最终混音必须分轨保存并记录样本数、时长、哈希和漂移。只改画面时音频漂移必须为 0；只改配乐时画面、字幕、Flow 和时间线必须锁定。

## Gate 3.5 发布包

用户确认成片后，建立单层发布目录并生成：

1. 正式发布母版（复制，不重编码）；
2. 三平台共用封面 PNG 与 JPG；
3. 可直接复制的视频标题 TXT；
4. 可直接复制的简介与恰好五个话题 TXT；
5. 置顶评论 TXT；
6. 发布前检查清单 TXT；
7. 版本、文件大小和 SHA-256 TXT；
8. `gate35-release-manifest.json`。

封面主信息置于中心安全区，文字本地排版，不依赖生图模型生成中文。发布母版与 Gate 3 母版哈希必须一致。Gate 3.5 的状态只能是 `release_ready_not_published`；登录、上传、定时和发布仍属于 Gate 4，必须另获授权。

## 必须通过的负向测试

校验器必须拒绝：旧 schema、缺少退出、旧层滞留、孤立大号序号、常驻顶部标题、必要解释缺失、解释复述字幕、全片单一卡片、主视觉过小、字幕与主视觉距离过大、任意层遮挡、动作抢拍、Flow 漂移、人声时长漂移、BGM 不可感知、总响度合格但 BGM 分段失败、没有 Gate 2 整套批准、未经授权发布。

