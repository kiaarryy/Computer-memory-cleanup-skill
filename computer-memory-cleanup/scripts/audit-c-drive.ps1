param(
    [ValidatePattern('^[A-Za-z]:$')]
    [string]$Drive = 'C:',

    [ValidateRange(1, 100)]
    [int]$TopN = 15,

    [string]$UserProfilePath = $env:USERPROFILE
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function ConvertTo-Gigabytes {
    param([Nullable[Int64]]$Bytes)
    if ($null -eq $Bytes) {
        return $null
    }
    return [math]::Round(($Bytes / 1GB), 2)
}

function Get-DirectoryLogicalSize {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $total = [int64]0
    $files = Get-ChildItem -LiteralPath $Path -Force -Recurse -File -ErrorAction SilentlyContinue
    foreach ($file in $files) {
        $total += [int64]$file.Length
    }
    return $total
}

function Get-PathGuidance {
    param([string]$Path)
    $lower = $Path.ToLowerInvariant()

    if ($lower -like '*onedrive*') {
        return 'Cloud sync: use Files On-Demand / Free up space; do not manually delete synced files.'
    }
    if ($lower -like '*xmind*file-cache*' -or $lower -like '*xmind*') {
        return 'App cache: close Xmind first; prefer dated quarantine move, then verify app state.'
    }
    if ($lower -like '*\temp*') {
        return 'Temporary data: prefer Windows Storage Sense or app-managed cleanup.'
    }
    if ($lower -like '*\google*' -or $lower -like '*\chrome*' -or $lower -like '*drivefs*') {
        return 'Browser/cloud cache: use app settings; preserve profiles and synced data.'
    }
    if ($lower -like '*\docker*') {
        return 'Docker data: inspect containers/images/volumes before prune.'
    }
    if ($lower -like '*\.codex*') {
        return 'Codex state: low priority; preserve sessions, skills, and automations unless requested.'
    }
    if ($lower -like '*\.vscode*') {
        return 'IDE state: inspect extensions/cache; do not remove the whole profile.'
    }
    return 'Inspect before action; treat user data and app state as protected.'
}

function New-SizeRecord {
    param([Parameter(Mandatory = $true)][string]$Path)
    $exists = Test-Path -LiteralPath $Path
    $bytes = $null
    if ($exists) {
        $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
        if ($null -ne $item) {
            if ($item.PSIsContainer) {
                $bytes = Get-DirectoryLogicalSize -Path $Path
            }
            else {
                $bytes = [int64]$item.Length
            }
        }
    }

    [pscustomobject]@{
        Path          = $Path
        Exists        = $exists
        LogicalSizeGB = ConvertTo-Gigabytes -Bytes $bytes
        Guidance      = Get-PathGuidance -Path $Path
    }
}

function Get-ChildDirectorySizes {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][int]$Limit
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return @()
    }

    $records = @()
    $children = Get-ChildItem -LiteralPath $Path -Force -Directory -ErrorAction SilentlyContinue
    foreach ($child in $children) {
        $bytes = Get-DirectoryLogicalSize -Path $child.FullName
        $records += [pscustomobject]@{
            Path          = $child.FullName
            LogicalSizeGB = ConvertTo-Gigabytes -Bytes $bytes
            Guidance      = Get-PathGuidance -Path $child.FullName
        }
    }

    return $records | Sort-Object -Property LogicalSizeGB -Descending | Select-Object -First $Limit
}

$driveLetter = $Drive.ToUpperInvariant()
$diskIds = @($driveLetter)
if ($driveLetter -eq 'C:' -and (Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='E:'" -ErrorAction SilentlyContinue)) {
    $diskIds += 'E:'
}

Write-Host '== Disk summary =='
$diskRows = @()
foreach ($diskId in $diskIds) {
    $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$diskId'" -ErrorAction SilentlyContinue
    if ($null -ne $disk) {
        $diskRows += [pscustomobject]@{
            DeviceID = $disk.DeviceID
            SizeGB   = ConvertTo-Gigabytes -Bytes ([int64]$disk.Size)
            FreeGB   = ConvertTo-Gigabytes -Bytes ([int64]$disk.FreeSpace)
            FreePct  = [math]::Round((($disk.FreeSpace / $disk.Size) * 100), 1)
        }
    }
}
$diskRows | Format-Table -AutoSize

$candidatePaths = @()
if ($UserProfilePath) {
    $candidatePaths += $UserProfilePath
    $candidatePaths += Join-Path $UserProfilePath 'AppData'
    $candidatePaths += Join-Path $UserProfilePath '.codex'
    $candidatePaths += Join-Path $UserProfilePath '.vscode'
    $candidatePaths += Join-Path $UserProfilePath 'Downloads'
    $candidatePaths += Join-Path $UserProfilePath 'Documents'
}
if ($env:APPDATA) {
    $candidatePaths += Join-Path $env:APPDATA 'Xmind'
    $candidatePaths += Join-Path $env:APPDATA 'Tencent'
    $candidatePaths += Join-Path $env:APPDATA 'Code'
}
if ($env:LOCALAPPDATA) {
    $candidatePaths += Join-Path $env:LOCALAPPDATA 'Google'
    $candidatePaths += Join-Path $env:LOCALAPPDATA 'Google\Chrome'
    $candidatePaths += Join-Path $env:LOCALAPPDATA 'Google\DriveFS'
    $candidatePaths += Join-Path $env:LOCALAPPDATA 'Temp'
    $candidatePaths += Join-Path $env:LOCALAPPDATA 'Docker'
    $candidatePaths += Join-Path $env:LOCALAPPDATA 'pip\Cache'
    $candidatePaths += Join-Path $env:LOCALAPPDATA 'npm-cache'
}

if ($UserProfilePath -and (Test-Path -LiteralPath $UserProfilePath)) {
    $oneDriveDirs = Get-ChildItem -LiteralPath $UserProfilePath -Force -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like 'OneDrive*' } |
        Select-Object -ExpandProperty FullName
    $candidatePaths += $oneDriveDirs
}

$candidatePaths = $candidatePaths | Where-Object { $_ } | Sort-Object -Unique

Write-Host ''
Write-Host '== Candidate path sizes =='
$candidateRecords = @()
foreach ($path in $candidatePaths) {
    $candidateRecords += New-SizeRecord -Path $path
}
$candidateRecords |
    Sort-Object -Property LogicalSizeGB -Descending |
    Format-Table -AutoSize

Write-Host ''
Write-Host "== Top $TopN folders under user profile =="
Get-ChildDirectorySizes -Path $UserProfilePath -Limit $TopN | Format-Table -AutoSize

if ($env:APPDATA) {
    Write-Host ''
    Write-Host "== Top $TopN folders under AppData\Roaming =="
    Get-ChildDirectorySizes -Path $env:APPDATA -Limit $TopN | Format-Table -AutoSize
}

if ($env:LOCALAPPDATA) {
    Write-Host ''
    Write-Host "== Top $TopN folders under AppData\Local =="
    Get-ChildDirectorySizes -Path $env:LOCALAPPDATA -Limit $TopN | Format-Table -AutoSize
}

Write-Host ''
Write-Host 'Read-only audit complete. No files were deleted, moved, compacted, or released.'
