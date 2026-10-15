#requires -Version 5.1
[CmdletBinding()]
param(
    [ValidateSet('Setup','CheckOnly','AdminWorker')][string]$Mode = 'Setup',
    [string]$TargetSid,
    [int]$TargetSession = -1,
    [string]$RunId,
    [switch]$LibraryOnly
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$script:BuildHash = '388269FB4BFE915C17657CE626E7099EF53F12F7644A44B0DE3A15AF7CC617ED'
$script:InstallerHash = '295B2409A5CCA6AD643CF1AAA6B29C7AB98761FDD291B15D91C41F65504A2B2B'
$script:LogPath = $null

function Write-Step([int]$Number, [string]$Message) {
    Write-Host "`n[$Number/6] $Message" -ForegroundColor Cyan
}
function Write-SetupLog([string]$Message) {
    Write-Host $Message
    if ($script:LogPath) { Add-Content -LiteralPath $script:LogPath -Value $Message -Encoding UTF8 }
}
function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    return ([Security.Principal.WindowsPrincipal]::new($identity)).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}
function Assert-NativeProcess {
    if (-not ('GamingSetupNative' -as [type])) {
        Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class GamingSetupNative {
 [DllImport("kernel32.dll", CharSet=CharSet.Unicode)]
 public static extern int GetCurrentPackageFullName(ref uint length, StringBuilder name);
}
'@
    }
    [uint32]$length = 0
    if ([GamingSetupNative]::GetCurrentPackageFullName([ref]$length, $null) -ne 15700) {
        throw 'Run START-HERE.cmd directly from Gaming File Explorer, not from Codex or another packaged application.'
    }
}
function Get-GamingAccount {
    $accounts = @(Get-CimInstance Win32_UserAccount -Filter "LocalAccount=True AND Name='Gaming'")
    if ($accounts.Count -ne 1 -or $accounts[0].Disabled) { throw 'An enabled local Windows account named Gaming is required.' }
    $profiles = @(Get-CimInstance Win32_UserProfile | Where-Object { $_.SID -eq $accounts[0].SID })
    if ($profiles.Count -ne 1) { throw 'Sign into Gaming once to create its Windows profile, then run this setup there.' }
    return [pscustomobject]@{ Sid = [string]$accounts[0].SID; Profile = [IO.Path]::GetFullPath($profiles[0].LocalPath); Name = 'Gaming' }
}
function Assert-SafePath([string]$Path, [string]$Root) {
    $full = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    $base = [IO.Path]::GetFullPath($Root).TrimEnd('\')
    if ($full -ne $base -and -not $full.StartsWith($base + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path is outside the intended Gaming folder: $full"
    }
    $current = $full
    while ($current) {
        if (Test-Path -LiteralPath $current) {
            if ((Get-Item -LiteralPath $current -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                throw "Linked/junction paths are not supported by this automatic setup: $current"
            }
        }
        $parent = [IO.Path]::GetDirectoryName($current)
        if ($parent -eq $current) { break }
        $current = $parent
    }
    return $full
}
function Assert-UserContext($Account, [string]$CurrentSid, [bool]$Elevated, [string]$LocalAppData) {
    if ($CurrentSid -ne $Account.Sid) { throw 'Sign into the Gaming Windows account and double-click START-HERE.cmd there. No installation was changed.' }
    if ($Elevated) { throw 'Double-click START-HERE.cmd normally in Gaming. Do not choose Run as administrator; the patch step requests UAC itself.' }
    $expected = Join-Path $Account.Profile 'AppData\Local'
    if ([IO.Path]::GetFullPath($LocalAppData).TrimEnd('\') -ne $expected) { throw 'Unexpected app-data location. Start this from Gaming File Explorer.' }
}
function Assert-SessionOwner([string]$Sid, [int]$Session) {
    $shells = @(Get-CimInstance Win32_Process -Filter "Name='explorer.exe'" | Where-Object { $_.SessionId -eq $Session })
    foreach ($shell in $shells) {
        $owner = Invoke-CimMethod -InputObject $shell -MethodName GetOwnerSid
        if ($owner.ReturnValue -eq 0 -and $owner.Sid -eq $Sid) { return }
    }
    throw 'The requested Gaming desktop session is not active. Return to Gaming and run setup again.'
}
function Assert-Hash([string]$Path, [string]$Expected) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Required file missing: $Path" }
    if ((Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash -ne $Expected) { throw "File verification failed: $([IO.Path]::GetFileName($Path)). Use the complete verified kit." }
}
function Assert-Kit([string]$Directory) {
    Assert-Hash (Join-Path $Directory 'WandEnhancer.exe') $script:BuildHash
    Assert-Hash (Join-Path $Directory 'Wand-Setup.exe') $script:InstallerHash
    $manifest = Get-Content -LiteralPath (Join-Path $Directory 'build-info.json') -Raw | ConvertFrom-Json
    if ($manifest.version -ne '2.1.3.0' -or $manifest.sha256 -ne $script:BuildHash) { throw 'Enhancer build manifest does not match this setup.' }
    $signature = Get-AuthenticodeSignature -LiteralPath (Join-Path $Directory 'Wand-Setup.exe')
    if ($signature.Status -ne 'Valid' -or $signature.SignerCertificate.Subject -notmatch 'WeMod LLC') { throw 'Official installer signature is not valid.' }
}
function Find-GamingInstall([string]$Profile) {
    $candidates = @()
    foreach ($brand in 'Wand','WeMod') {
        $root = Join-Path $Profile "AppData\Local\$brand"
        [void](Assert-SafePath $root $Profile)
        if (-not (Test-Path -LiteralPath $root)) { continue }
        foreach ($dir in @(Get-ChildItem -LiteralPath $root -Directory -Filter 'app-*')) {
            [void](Assert-SafePath $dir.FullName $root)
            $versionText = $dir.Name.Substring(4)
            $version = $null
            if (-not [Version]::TryParse($versionText, [ref]$version)) { throw "Unsupported/beta installation detected: $versionText. This kit targets stable 12.63.0." }
            foreach ($exeName in 'Wand.exe','WeMod.exe') {
                if (Test-Path -LiteralPath (Join-Path $dir.FullName $exeName)) {
                    $candidates += [pscustomobject]@{ Root=$root; Directory=$dir.FullName; Version=$version; VersionText=$versionText; ExeName=$exeName; Brand=[IO.Path]::GetFileNameWithoutExtension($exeName) }
                    break
                }
            }
        }
    }
    if ($candidates.Count -eq 0) { return $null }
    $latest = $candidates | Sort-Object Version -Descending | Select-Object -First 1
    if ($latest.Version -ne [Version]'12.63.0') { throw "Wand $($latest.VersionText) was found. This kit is verified for 12.63.0 only; no patch was applied. Request a compatibility check." }
    if (-not (Test-Path -LiteralPath (Join-Path $latest.Directory 'resources\app.asar'))) { throw 'Wand installation is incomplete. Repair official Wand in Gaming first.' }
    return $latest
}
function Assert-NoWandProcesses {
    $busy = @(Get-Process -Name Wand,WeMod,WandAuxiliaryService,WeModAuxiliaryService,WandEnhancer -ErrorAction SilentlyContinue)
    if ($busy.Count) { throw 'Exit Wand and Wand Enhancer in ALL signed-in Windows accounts, including tray icons, then retry. Setup will not stop another account''s processes.' }
}
function Get-Selection([string]$Root) {
    $path = Join-Path $Root 'enhancer.json'
    [void](Assert-SafePath $path $Root)
    if (Test-Path -LiteralPath $path) {
        $saved = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
        if ($saved.PSObject.Properties['CustomScriptPaths'] -and @($saved.CustomScriptPaths).Count) { throw 'Custom renderer scripts need manual review; this automatic setup will not load them as administrator.' }
        $types = @($saved.PatchTypes | ForEach-Object { [int]$_ })
        if (-not $types.Count -or @($types | Where-Object { $_ -notin 1,2,8,16 }).Count) { throw 'Unknown or empty existing enhancer selection. Review it manually before automated setup.' }
        return [pscustomobject]@{ Types=$types; AutoApply=[bool]$saved.AutoApplyAfterUpdate }
    }
    return [pscustomobject]@{ Types=@(1,8,16); AutoApply=$true }
}
function Assert-NoLinkedFiles([string]$Root) {
    [void](Assert-SafePath $Root $Root)
    $pending = [Collections.Generic.Stack[string]]::new()
    $pending.Push($Root)
    while ($pending.Count) {
        foreach ($item in @(Get-ChildItem -LiteralPath $pending.Pop() -Force)) {
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw "Linked files/folders need manual review before administrator patching: $($item.FullName)" }
            if ($item.PSIsContainer) { $pending.Push($item.FullName) }
        }
    }
}
function Assert-OriginalResources($Install) {
    $resources = Join-Path $Install.Directory 'resources'
    $backupArchive = Join-Path $resources 'app.asar.backup'
    $backupSupport = Join-Path $resources 'app.asar.unpacked.backup'
    $hasArchive = Test-Path -LiteralPath $backupArchive
    $hasSupport = Test-Path -LiteralPath $backupSupport
    if ($hasArchive -ne $hasSupport) { throw 'Only part of the original backup exists. Preserve it and repair the installation before continuing.' }
    $package = Join-Path $Install.Root 'packages\Wand-12.63.0-full.nupkg'
    if (-not (Test-Path -LiteralPath $package)) { throw 'The original 12.63.0 package is missing. Repair official Wand in Gaming so originals can be verified.' }
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($package)
    $checked = 0
    try {
        foreach ($entry in $zip.Entries) {
            if (-not $entry.FullName.StartsWith('lib/net45/resources/') -or $entry.FullName.EndsWith('/')) { continue }
            $relative = $entry.FullName.Substring('lib/net45/resources/'.Length).Replace('/','\')
            $target = Join-Path $resources $relative
            if ($hasArchive) {
                if ($relative -eq 'app.asar') { $target = $backupArchive }
                elseif ($relative.StartsWith('app.asar.unpacked\')) { $target = Join-Path $backupSupport $relative.Substring('app.asar.unpacked\'.Length) }
            }
            [void](Assert-SafePath $target $Install.Directory)
            if (-not (Test-Path -LiteralPath $target -PathType Leaf)) { throw "Original support file missing: $relative" }
            $hash = [Security.Cryptography.SHA256]::Create()
            $stream = $entry.Open()
            try { $expected = [BitConverter]::ToString($hash.ComputeHash($stream)).Replace('-','') }
            finally { $stream.Dispose(); $hash.Dispose() }
            Assert-Hash $target $expected
            $checked++
        }
    } finally { $zip.Dispose() }
    if ($checked -lt 2) { throw 'Original package contained no usable resources.' }
    Write-SetupLog "Verified $checked original resource files against the cached official package."
}
function Invoke-EnhancerPatch($Install, [string]$Exe, $Selection) {
    $assembly = [Reflection.Assembly]::LoadFrom($Exe)
    $type = $assembly.GetType('WandEnhancer.Core.Enhancer', $true)
    $config = [Activator]::CreateInstance($assembly.GetType('WandEnhancer.Models.PatchConfig', $true))
    $patchType = $assembly.GetType('WandEnhancer.Models.EPatchType', $true)
    $config.PatchTypes = [Activator]::CreateInstance([Collections.Generic.HashSet``1].MakeGenericType($patchType))
    foreach ($value in $Selection.Types) { [void]$config.PatchTypes.Add([Enum]::ToObject($patchType, [int]$value)) }
    $config.Strategy = [Enum]::ToObject($assembly.GetType('WandEnhancer.Models.EPatchStrategy', $true), 1)
    $config.AutoApplyAfterUpdate = $Selection.AutoApply
    $target = [Activator]::CreateInstance($assembly.GetType('WandEnhancer.Models.WeModConfig', $true))
    $target.RootDirectory=$Install.Directory; $target.ExecutableName=$Install.ExeName; $target.BrandName=$Install.Brand
    $loggerType = [Action``2].MakeGenericType([string], $assembly.GetType('WandEnhancer.Core.ELogType', $true))
    $logger = { param($message,$level) Write-SetupLog "[$level] $message" } -as $loggerType
    $patcher = [Activator]::CreateInstance($type, @($target,$logger,$config))
    $patcher.Patch()
    if (-not $type.GetMethod('IsPatched').Invoke($null, [object[]]@([string]$Install.Directory))) { throw 'Patch completion and backups were not confirmed.' }
}
function Invoke-AdminWorker {
    if (-not (Test-Administrator)) { throw 'The patch step requires Windows administrator approval.' }
    Assert-NativeProcess
    $account = Get-GamingAccount
    if ($TargetSid -ne $account.Sid -or $TargetSession -lt 1 -or $RunId -notmatch '^[a-f0-9]{32}$') { throw 'Invalid Gaming setup request.' }
    Assert-SessionOwner $TargetSid $TargetSession
    $enhancerHome = Join-Path $account.Profile 'AppData\Local\Programs\WandEnhancer'
    $run = Join-Path $account.Profile "AppData\Local\WandEnhancerSetup\runs\$RunId"
    [void](Assert-SafePath $enhancerHome $account.Profile)
    [void](Assert-SafePath $run $account.Profile)
    if (-not (Test-Path -LiteralPath $run -PathType Container)) { throw 'Gaming setup run directory is missing.' }
    $script:LogPath = Join-Path $run 'admin-patch.log'
    foreach ($name in 'admin-patch.log','admin-result.json','previous-enhancer.json') { [void](Assert-SafePath (Join-Path $run $name) $run) }
    $result = @{ Success=$false; RunId=$RunId; TargetSid=$TargetSid; Error=$null }
    $lock = $null; $exeLock = $null
    try {
        $lockPath = Join-Path $account.Profile 'AppData\Local\WandEnhancerSetup\admin-worker.lock'
        [void](Assert-SafePath $lockPath $account.Profile)
        $lock = [IO.File]::Open($lockPath, [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        Assert-NoWandProcesses
        $install = Find-GamingInstall $account.Profile
        if (-not $install) { throw 'No supported Wand installation found in Gaming.' }
        Assert-NoLinkedFiles $install.Root
        $selection = Get-Selection $install.Root
        $exe = Join-Path $enhancerHome 'WandEnhancer.exe'
        [void](Assert-SafePath $exe $enhancerHome)
        $exeLock = [IO.File]::Open($exe, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
        Assert-Hash $exe $script:BuildHash
        if (Test-Path -LiteralPath (Join-Path $enhancerHome 'renderer-scripts')) { throw 'Remove/review custom renderer scripts before automatic administrator patching.' }
        Assert-OriginalResources $install
        if (Test-Path -LiteralPath (Join-Path $install.Root 'enhancer.json')) { Copy-Item -LiteralPath (Join-Path $install.Root 'enhancer.json') -Destination (Join-Path $run 'previous-enhancer.json') }
        # The target comes from Gaming's SID/profile, never the elevated user's environment.
        Invoke-EnhancerPatch $install $exe $selection
        $result.Success=$true; $result.Installation=$install.Directory; $result.Root=$install.Root
        $result.ExeName=$install.ExeName; $result.RemoteEnabled=($selection.Types -contains 16)
    } catch {
        $result.Error=$_.Exception.GetBaseException().Message
        Write-SetupLog "STOPPED: $($result.Error)"
    } finally {
        if ($exeLock) { $exeLock.Dispose() }; if ($lock) { $lock.Dispose() }
        $result | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $run 'admin-result.json') -Encoding UTF8
    }
    if (-not $result.Success) { throw $result.Error }
}
function Wait-ForOwnRemote($Install, [int]$Session, [int]$Seconds = 45) {
    $deadline = [DateTime]::UtcNow.AddSeconds($Seconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        try {
            $listeners = @(Get-NetTCPConnection -State Listen -LocalPort 3223 -ErrorAction Stop)
            $expectedExe = Join-Path $Install.Directory $Install.ExeName
            $own = @($listeners | Where-Object {
                $p=Get-CimInstance Win32_Process -Filter "ProcessId=$($_.OwningProcess)" -ErrorAction Stop
                $p -and $p.SessionId -eq $Session -and $p.ExecutablePath -eq $expectedExe
            })
            if ($own.Count) {
                $health = Invoke-RestMethod 'http://127.0.0.1:3223/remote/api/health' -TimeoutSec 3
                if ($health.ok) { return $true }
            }
        } catch { }
        Start-Sleep -Seconds 2
    }
    return $false
}
function Invoke-GamingSetup([bool]$ReadOnly) {
    Write-Step 1 'Check Gaming account and verified setup files'
    $account = Get-GamingAccount
    Assert-UserContext $account ([Security.Principal.WindowsIdentity]::GetCurrent().User.Value) (Test-Administrator) $env:LOCALAPPDATA
    Assert-NativeProcess
    $session = (Get-Process -Id $PID).SessionId
    Assert-SessionOwner $account.Sid $session
    Assert-Kit $PSScriptRoot
    $install = Find-GamingInstall $account.Profile
    if ($ReadOnly) { Write-Host 'Read-only checks passed. No files changed.'; return }
    $setupHome = Join-Path $account.Profile 'AppData\Local\WandEnhancerSetup'
    [void](Assert-SafePath $setupHome $account.Profile)
    [IO.Directory]::CreateDirectory($setupHome) | Out-Null
    [void](Assert-SafePath (Join-Path $setupHome 'wizard.lock') $setupHome)
    $wizardLock = [IO.File]::Open((Join-Path $setupHome 'wizard.lock'), [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    try {
        $id = [Guid]::NewGuid().ToString('N')
        $run = Join-Path $setupHome "runs\$id"
        [void](Assert-SafePath $run $setupHome)
        [IO.Directory]::CreateDirectory($run) | Out-Null
        $script:LogPath = Join-Path $run 'setup.log'
        Write-Step 2 'Install official Wand if needed'
        if (-not $install) {
            Write-Host 'Official Wand setup will open. Click Install Now and finish it in Gaming. No passwords are entered in this script.'
            $installer = Start-Process -FilePath (Join-Path $PSScriptRoot 'Wand-Setup.exe') -PassThru
            if (-not $installer.WaitForExit(1200000)) { throw 'Installer is still running. Finish it before rerunning setup.' }
            [void](Read-Host 'When installation has finished, press Enter to continue')
            $install = Find-GamingInstall $account.Profile
            if (-not $install) { throw 'Installation was cancelled or did not finish. No patch was applied.' }
        }
        Write-SetupLog "Target: $($install.Directory)"
        Write-Step 3 'Close games and Wand, then prepare the enhancer'
        $selection = Get-Selection $install.Root
        Write-Host 'Save/close your game and exit Wand and Wand Enhancer, including tray icons, in ALL Windows accounts.'
        Write-Host "Static patch; selected feature IDs: $($selection.Types -join ', '). Default 1/8/16 = Pro patch, F12 diagnostics, remote panel."
        [void](Read-Host 'Press Enter when everything is closed, or Ctrl+C to cancel')
        Assert-NoWandProcesses
        $enhancerHome = Join-Path $account.Profile 'AppData\Local\Programs\WandEnhancer'
        [void](Assert-SafePath $enhancerHome $account.Profile)
        [IO.Directory]::CreateDirectory($enhancerHome) | Out-Null
        foreach ($name in 'WandEnhancer.exe','build-info.json') {
            $target=Join-Path $enhancerHome $name
            [void](Assert-SafePath $target $enhancerHome)
            if (Test-Path -LiteralPath $target) { Copy-Item -LiteralPath $target -Destination (Join-Path $run "previous-$name") }
            Copy-Item -LiteralPath (Join-Path $PSScriptRoot $name) -Destination $target -Force
        }
        Assert-Hash (Join-Path $enhancerHome 'WandEnhancer.exe') $script:BuildHash
        $workerScript = Join-Path $run 'Start-GamingSetup.ps1'
        Copy-Item -LiteralPath $PSCommandPath -Destination $workerScript
        Write-Step 4 'Administrator backup verification and patch'
        Write-Host 'Approve the Windows UAC prompt. If it requests an administrator password, enter it only into Windows. The target remains Gaming.'
        $powershell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $arguments = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Mode AdminWorker -TargetSid "{1}" -TargetSession {2} -RunId {3}' -f $workerScript,$account.Sid,$session,$id
        $worker=Start-Process -FilePath $powershell -ArgumentList $arguments -Verb RunAs -WindowStyle Hidden -PassThru
        if (-not $worker.WaitForExit(900000)) { throw 'The administrator patch is still running. Do not start another copy; check the run log before retrying.' }
        $resultPath=Join-Path $run 'admin-result.json'
        if (-not(Test-Path -LiteralPath $resultPath)) { throw 'Administrator step did not report a result. UAC may have been cancelled; no success is assumed.' }
        $result=Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
        if ($result.RunId -ne $id -or $result.TargetSid -ne $account.Sid -or -not $result.Success -or $worker.ExitCode -ne 0) { throw "Administrator step failed: $($result.Error)" }
        Write-Step 5 'Open repaired Wand as Gaming and create shortcuts'
        $shell=New-Object -ComObject WScript.Shell
        foreach($item in @(@{Name='Wand Enhancer (repaired).lnk';Exe=(Join-Path $enhancerHome 'WandEnhancer.exe')},@{Name='Wand (repaired).lnk';Exe=(Join-Path $install.Root $install.ExeName)})) {
            $link=$shell.CreateShortcut((Join-Path ([Environment]::GetFolderPath('Desktop')) $item.Name)); $link.TargetPath=$item.Exe; $link.WorkingDirectory=Split-Path -Parent $item.Exe; $link.Save()
        }
        # This controller is NOT elevated: Wand inherits Gaming's normal account.
        Start-Process -FilePath (Join-Path $install.Root $install.ExeName)
        Start-Process -FilePath (Join-Path $enhancerHome 'WandEnhancer.exe')
        Write-Host 'Sign into Wand privately if prompted. Leave Wand open. No game will be started.'
        [void](Read-Host 'When Wand is open and signed in, press Enter for the final check')
        Write-Step 6 'Verify startup and report the result'
        $expectedExe=Join-Path $install.Directory $install.ExeName
        $running=@(Get-CimInstance Win32_Process | Where-Object {$_.ExecutablePath -eq $expectedExe -and $_.SessionId -eq $session})
        $remote=if($result.RemoteEnabled){Wait-ForOwnRemote $install $session}else{$null}
        $summary=@{PatchApplied=$true;Version='2.1.3.0';Target='Gaming';WandStarted=($running.Count -gt 0);RemoteEnabled=$result.RemoteEnabled;RemoteHealthy=$remote;GameplayTest='Pending - reserved for the user';Logs=$run}
        $summary|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $run 'setup-result.json') -Encoding UTF8
        if (-not $summary.WandStarted -or ($result.RemoteEnabled -and -not $remote)) { throw "Patch applied, but startup/remote verification is incomplete. Keep the backups. Logs: $run" }
        Write-Host "`nSETUP VERIFIED: Enhancer 2.1.3 applied to Gaming; Wand startup and selected remote panel checked." -ForegroundColor Green
        Write-Host 'You can now test your game. Gameplay has not been tested by this script.'
        Write-Host "Restore: close games/Wand, open Wand Enhancer (repaired), choose Restore. Logs: $run"
    } finally { $wizardLock.Dispose() }
}

if ($LibraryOnly) { return }
try {
    if ($Mode -eq 'AdminWorker') { Invoke-AdminWorker }
    else { Invoke-GamingSetup ($Mode -eq 'CheckOnly') }
    exit 0
} catch {
    Write-Host "`nSTOPPED: $($_.Exception.GetBaseException().Message)" -ForegroundColor Red
    if ($script:LogPath) { Add-Content -LiteralPath $script:LogPath -Value "STOPPED: $($_.Exception.GetBaseException().Message)" }
    Write-Host 'No game was launched. Keep any existing backups; do not delete them to force a retry.'
    exit 1
}
