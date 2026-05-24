# Computer Memory Cleanup Skill

Codex skill for auditing Windows C drive storage pressure and planning safe cleanup. It was created from a real local cleanup workflow involving Xmind cache quarantine, OneDrive Files On-Demand, AppData inspection, and Codex cache triage.

The skill is intentionally conservative:

- It audits before recommending action.
- It treats user data, synced folders, archives, generated outputs, and app state as protected.
- Its bundled script is read-only.
- It does not provide automatic deletion, recursive cleanup, or bulk file removal.

## Repository layout

```text
.
|-- agent.md
|-- computer-memory-cleanup/
|   |-- SKILL.md
|   |-- agents/openai.yaml
|   `-- scripts/audit-c-drive.ps1
|-- LICENSE
|-- README.md
`-- .gitignore
```

## Install locally

Clone the repository, then copy the skill folder into your Codex skills directory:

```powershell
git clone https://github.com/kiaarryy/Computer-memory-cleanup-skill.git
Copy-Item -Recurse -LiteralPath .\Computer-memory-cleanup-skill\computer-memory-cleanup -Destination "$env:USERPROFILE\.codex\skills\computer-memory-cleanup"
```

Restart Codex or reload skills if needed.

## Use

Invoke the skill in Codex:

```text
Use $computer-memory-cleanup to audit my Windows C drive and propose a safe cleanup plan.
```

Run the read-only audit script directly:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\computer-memory-cleanup\scripts\audit-c-drive.ps1 -Drive C: -TopN 15
```

The script reports disk summaries, candidate folder sizes, top user-profile folders, and cleanup guidance labels. It does not delete, move, compact, or release files.

## Safety model

Recommended cleanup actions are staged by risk:

- Use app/system cleanup for Temp, browser caches, Windows update caches, and Docker data.
- Use OneDrive Files On-Demand or "Free up space" for synced folders.
- Use dated quarantine moves for unusually large application caches such as Xmind `file-cache`.
- Preserve `.codex`, project folders, app databases, archives, and user documents unless the user explicitly confirms a concrete action.

## Validation

Validate the skill structure:

```powershell
$env:PYTHONUTF8=1
python C:\Users\pc\.codex\skills\.system\skill-creator\scripts\quick_validate.py .\computer-memory-cleanup
```

Run the audit script:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\computer-memory-cleanup\scripts\audit-c-drive.ps1 -Drive C: -TopN 10
```
