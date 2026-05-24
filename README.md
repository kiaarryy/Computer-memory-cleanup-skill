# Computer Memory Cleanup Skill · Windows C 盘审计 / 安全清理计划

![GitHub stars](https://img.shields.io/github/stars/kiaarryy/Computer-memory-cleanup-skill?style=flat-square)
![License](https://img.shields.io/github/license/kiaarryy/Computer-memory-cleanup-skill?style=flat-square)
![Skill](https://img.shields.io/badge/Skill-Agent-111111?style=flat-square)
![Windows](https://img.shields.io/badge/Windows-C%20Drive-0078D4?style=flat-square)
![Codex](https://img.shields.io/badge/Codex-Supported-222222?style=flat-square)
![Read Only](https://img.shields.io/badge/Audit-Read%20Only-2E7D32?style=flat-square)

> English version: [README.en.md](./README.en.md)

一个适配 Codex 和其他本地 AI coding agent 的 Windows C 盘空间审计 skill。它把一次真实的本地清理流程沉淀成可复用工作流：先只读定位 C 盘大户，再区分缓存、云同步副本、应用状态、用户数据和可隔离目录，最后给出可验证、可回退的清理方案。

这个 skill 特别强调安全边界：内置脚本只审计，不删除、不移动、不释放 OneDrive 本地副本。真正的清理动作必须由 agent 在用户确认后逐步执行。

## 项目概览

下面用四张图概括这个 skill 要解决的问题、工作方式和安全边界：

| 封面 | 找出空间大户 |
|------|--------------|
| ![Computer Memory Cleanup cover](./docs/social/carousel-01-cover.png) | ![Find storage hogs](./docs/social/carousel-02-storage-hogs.png) |

| 安全工作流 | GitHub CTA |
|------------|------------|
| ![Safer cleanup workflow](./docs/social/carousel-03-workflow.png) | ![Try the skill](./docs/social/carousel-04-cta.png) |

## 30 秒开始

把这段话发给有 shell 权限的 Codex / 本地 Agent：

```text
帮我安装 computer-memory-cleanup skill。请把 https://github.com/kiaarryy/Computer-memory-cleanup-skill 克隆到临时目录，然后把其中的 computer-memory-cleanup 文件夹复制到 $env:USERPROFILE\.codex\skills\computer-memory-cleanup。安装后运行 quick_validate.py 验证，并用 scripts\audit-c-drive.ps1 -Drive C: -TopN 10 做一次只读审计。
```

已经安装过的话，可以用这段话更新：

```text
帮我更新 computer-memory-cleanup skill。请进入本地仓库执行 git pull，然后把 computer-memory-cleanup 文件夹同步到 $env:USERPROFILE\.codex\skills\computer-memory-cleanup，最后运行 quick_validate.py。
```

安装后直接对 Agent 说：

```text
Use $computer-memory-cleanup to audit my Windows C drive and propose a safe cleanup plan.
```

也可以试这些请求：

```text
帮我检查 C 盘为什么越来越满，不要删除文件，只给出证据和清理计划。
```

```text
帮我看 Codex、Xmind、OneDrive、Chrome 和 Temp 哪些目录占空间最大。
```

```text
我的 C 盘快满了，请按风险等级列出可以安全处理、需要应用内清理、只能隔离移动的路径。
```

## 能力

- 只读审计 C/E 盘空间、用户目录、AppData、Codex、Xmind、OneDrive、Chrome/Google、Docker、Temp 等常见空间来源。
- 输出候选路径大小、Top N 大目录、路径类型和安全建议标签。
- 将“逻辑大小”和“实际可释放空间”分开看待，避免误判 OneDrive/Google Drive 占用。
- 复用安全流程处理 Xmind 大缓存：关闭应用、解析路径、确认目标盘空间、移动到 dated quarantine、验证恢复空间。
- 复用安全流程处理 OneDrive：使用 Files On-Demand / Free up space / `attrib +U -P`，不手动删除云同步文件。
- 明确禁止递归删除、通配符删除、清空用户目录、删除归档和项目输出。

## 适合 / 不适合

适合：

- Windows C 盘剩余空间过低，需要先查明具体原因。
- 本地 Codex、IDE、Xmind、OneDrive、浏览器缓存、Docker 或 Temp 目录增长异常。
- 用户希望 agent 给出可执行但保守的清理计划。
- 需要把一次本地清理过程沉淀成可复用排查流程。

不适合：

- 一键删除垃圾文件。
- 自动清空缓存目录。
- 自动删除 OneDrive/Google Drive/Dropbox 同步文件。
- 自动决定哪些用户文档、研究输出、归档备份可以删除。

## 常见使用场景

| 任务 | 推荐方式 |
|------|---------|
| C 盘空间预警 | 先运行只读审计脚本，输出磁盘余量和 Top N 目录 |
| Xmind 缓存异常大 | 关闭 Xmind，采用隔离移动而非删除 |
| OneDrive 目录很大 | 使用 Files On-Demand 释放本地副本，不删除云文件 |
| Chrome/Google 目录很大 | 用浏览器或 Google Drive 设置清理，保留用户配置 |
| Codex 目录增长 | 优先看 sessions/logs/cache，默认保留 skills、automations、memory |
| Docker 占用变大 | 先列出 containers/images/volumes，再决定是否 prune |
| Temp 目录增长 | 优先使用 Windows Storage Sense 或具体 stale file 清单 |

## 为什么不是“一键清理”

- C 盘里的“大文件”经常不是垃圾，而是用户数据、云同步占位、应用数据库、研究输出或历史归档。
- 对 OneDrive 同步目录执行删除，可能意味着删除云端文件。
- 对 AppData 整目录清理，可能破坏登录状态、应用配置、数据库和最近文件。
- 低风险清理需要证据链：清理前空间、目标路径、动作类型、清理后空间和回退方案。

## 平台支持

| 平台 | 状态 | 说明 |
|------|------|------|
| Codex | 支持 | 推荐环境，可读写本地文件并运行 PowerShell |
| Claude Code / Cursor | 可用 | 需要能访问 Windows 文件系统和 shell |
| 普通 Chatbot | 不推荐 | 没有本地文件系统时无法做真实审计 |
| macOS / Linux | 非主线 | skill 的安全思想可复用，但脚本和路径面向 Windows |

## 安装

### 方式一：安装到本机 Codex skills

```powershell
git clone https://github.com/kiaarryy/Computer-memory-cleanup-skill.git
Copy-Item -Recurse -LiteralPath .\Computer-memory-cleanup-skill\computer-memory-cleanup -Destination "$env:USERPROFILE\.codex\skills\computer-memory-cleanup"
```

验证：

```powershell
$env:PYTHONUTF8=1
python "$env:USERPROFILE\.codex\skills\.system\skill-creator\scripts\quick_validate.py" "$env:USERPROFILE\.codex\skills\computer-memory-cleanup"
```

### 方式二：从本仓库直接运行审计脚本

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\computer-memory-cleanup\scripts\audit-c-drive.ps1 -Drive C: -TopN 15
```

### 方式三：让 Agent 安装

> 帮我安装 `computer-memory-cleanup` 这个 Codex skill。请按下面步骤做：
>
> 1. 克隆 `https://github.com/kiaarryy/Computer-memory-cleanup-skill.git`
> 2. 确保 `$env:USERPROFILE\.codex\skills` 存在
> 3. 把仓库里的 `computer-memory-cleanup` 文件夹复制到 `$env:USERPROFILE\.codex\skills\computer-memory-cleanup`
> 4. 运行 `quick_validate.py` 验证 skill
> 5. 运行 `audit-c-drive.ps1 -Drive C: -TopN 10` 做一次只读试验

## 触发方式

安装后可以使用这些表达：

- `Use $computer-memory-cleanup to audit my Windows C drive and propose a safe cleanup plan.`
- `帮我检查 C 盘空间，不要删除文件。`
- `帮我找出 AppData 里面最大的目录。`
- `帮我判断 Xmind file-cache 能不能安全处理。`
- `帮我释放 OneDrive 本地副本，但不要删除云端文件。`
- `帮我检查 Codex 本地缓存是不是导致 C 盘变满。`

## 使用流程

Skill 会引导 Agent 按这个顺序工作：

1. 只读审计：检查磁盘余量、用户目录、AppData 和候选路径。
2. 证据排序：按目录大小和风险类型排序，不直接下结论。
3. 风险分类：区分系统/应用缓存、云同步副本、应用状态、用户资料和可隔离目录。
4. 方案制定：从收益最大、风险最低的项目开始。
5. 用户确认：任何移动、释放、删除前都要确认具体路径和动作。
6. 执行后验证：重新检查 C 盘剩余空间和源/目标路径状态。
7. 留出回退：对不确定的应用缓存使用 quarantine，不直接删除。

详细说明见 [computer-memory-cleanup/SKILL.md](./computer-memory-cleanup/SKILL.md)。

## 安全模型

| 类型 | 默认策略 |
|------|----------|
| Windows Temp | 建议用 Storage Sense 或具体 stale file 清单 |
| Chrome / Google | 用应用设置清缓存，保留 profile |
| OneDrive / Google Drive | 只释放本地副本，不手动删除同步文件 |
| Xmind file-cache | 用户确认后隔离移动，观察后再决定是否删除隔离副本 |
| Docker | 先列出对象，再决定是否 prune |
| `.codex` | 默认保留 sessions、skills、automations、memories |
| 用户文档 / 项目输出 / 归档 | 默认保护，不主动清理 |

## 示例请求

```text
帮我运行 computer-memory-cleanup 的只读审计脚本，输出 C 盘和 AppData 最大的 10 个目录。
```

```text
我看到 Xmind 占了很多空间，请先确认进程状态、路径和 E 盘空间，再给出隔离移动计划。
```

```text
请检查 OneDrive 本地副本是否可以释放。不要删除同步文件，只使用 Files On-Demand 相关方法。
```

```text
请判断 .codex 目录是不是 C 盘变满的主因，只做审计，不清理历史会话。
```

## 目录结构

```text
Computer-memory-cleanup/
|-- agent.md
|-- README.md
|-- README.en.md
|-- LICENSE
|-- .gitignore
`-- computer-memory-cleanup/
    |-- SKILL.md
    |-- agents/
    |   `-- openai.yaml
    `-- scripts/
        `-- audit-c-drive.ps1
```

## 核心原则

1. 证据先于动作。
2. 可回退优先于直接删除。
3. 应用内清理优先于手动改目录。
4. 云同步释放优先于云文件删除。
5. 低风险高收益优先。
6. 每一步都要有验证结果。

## Roadmap

- 增加可选 JSON 输出，方便 agent 自动解析审计结果。
- 增加 Windows Storage Sense / Docker / browser cache 的只读检查辅助脚本。
- 增加安装脚本，但继续保持清理动作默认禁用。
- 补充更多真实清理案例和 before/after 报告模板。

## FAQ

**这个 skill 会删除文件吗？**

不会。内置脚本只读审计。任何删除、移动或释放本地副本都需要用户明确确认。

**为什么 OneDrive 显示 24 GB，但释放后只多了几 GB？**

OneDrive 文件可能是云占位文件。目录逻辑大小不等于本地实际占用。

**可以自动清理 Xmind file-cache 吗？**

不建议自动删除。推荐关闭 Xmind 后移动到 dated quarantine，确认 Xmind 正常后再手动处理隔离副本。

**可以直接删 `.codex\sessions` 吗？**

默认不建议。它可能包含历史会话和诊断线索。除非用户明确要清理 Codex 历史，否则只做审计。

## License

MIT © 2026 Zhineng Jin
