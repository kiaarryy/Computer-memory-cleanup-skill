---
name: computer-memory-cleanup
description: Audit Windows C drive storage pressure and produce safe cleanup plans. Use when Codex needs to inspect local disk usage, identify large Windows user-profile folders, Codex caches, Xmind caches, OneDrive local copies, browser caches, Docker data, Temp folders, or other C drive growth, and guide safe cleanup without destructive bulk deletion.
---

# Computer Memory Cleanup

## Overview

Use this skill to diagnose Windows C drive storage pressure with read-only evidence first, then propose low-risk cleanup actions. Treat user data, synced cloud files, generated research outputs, archives, and application state as protected until the user explicitly confirms a concrete action.

## Quick Start

Run the bundled audit script before recommending cleanup:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\audit-c-drive.ps1 -Drive C: -TopN 15
```

If running from outside the skill folder, use the absolute script path. The script is read-only: it reports disk summaries, candidate folder sizes, top user-profile folders, and cleanup guidance labels. It does not delete, move, compact, or release any files.

## Workflow

1. Inspect first. Check disk free space, user-profile size, AppData size, and candidate paths with the audit script or equivalent read-only PowerShell.
2. Rank evidence. Separate logical size from actual freed space for cloud placeholders such as OneDrive.
3. Classify each large path:
   - Safe to clear via system/app UI: Windows Temp, browser caches, update caches, app-managed caches.
   - Release local cloud copy: OneDrive or Google Drive files, using Files On-Demand or app settings.
   - Quarantine move only after confirmation: unusually large app caches such as Xmind `file-cache`.
   - Preserve by default: user documents, archives, outputs, project folders, `.codex` sessions, application databases.
4. Propose a staged plan. Start with the largest low-risk item, verify free space after each action, and keep reversible quarantine copies when moving app caches.
5. Report concrete evidence: before/after free space, exact paths, action taken or recommended, validation command, and remaining risk.

## Safety Rules

- Do not use recursive deletion, wildcard deletion, or cleanup loops for user folders.
- Do not delete OneDrive, Google Drive, Dropbox, or other synced folders manually. Use app-supported "free up space" behavior.
- Do not delete `.codex`, IDE, browser, or application profile directories wholesale. Inspect subdirectories and prefer app-managed cleanup.
- Do not treat logical cloud-file size as guaranteed reclaimable local disk space.
- Do not move an application cache until the relevant app is closed, the source and destination paths are resolved, and the destination disk has enough free space.
- Use quarantine moves instead of deletion for large app caches when correctness is uncertain. Keep the quarantine for a defined review period.

## Windows Cleanup Patterns

### Xmind large cache

When `AppData\Roaming\Xmind\Electron v3\vana\file-cache` or a similar Xmind cache dominates C drive usage:

1. Confirm Xmind is not running.
2. Resolve the source path and quarantine destination path.
3. Confirm the destination is on a drive with enough free space.
4. Move the cache folder to a dated quarantine directory, not to the recycle bin.
5. Verify the source is gone, the quarantine exists, and C drive free space increased.
6. Tell the user to open Xmind and check recent/cloud files before deleting the quarantine later.

### OneDrive local copies

For `OneDrive*` folders:

1. Prefer the OneDrive context menu "Free up space" or the equivalent Files On-Demand behavior.
2. If using PowerShell after user confirmation, use `attrib +U -P` on the OneDrive path to release local copies.
3. Do not delete files from the synced folder unless the user wants deletion from the cloud too.
4. Re-check disk free space because many files may already be placeholders.

### Browser, Docker, Temp, and Codex

- Chrome/Google: use browser settings or app-specific cache controls; preserve profile data.
- Docker: use Docker Desktop or explicit prune commands only after showing what will be removed.
- Temp: prefer Windows Storage Sense or a concrete list of stale files; avoid broad manual deletion.
- Codex: `.codex` is usually not the largest contributor. Preserve sessions, skills, automations, and logs unless the user specifically asks to prune them.

## Reporting Standard

Use concise operational output:

- Current disk free space and percent.
- Top large directories with sizes.
- Recommended actions grouped by risk and expected benefit.
- Exact commands only when they are read-only, reversible, or explicitly confirmed.
- Verification results after any user-approved action.
