#requires -Version 5.1
param([Parameter(Mandatory=$true)][string]$KitDirectory,
      [string]$TestRoot = (Join-Path $env:TEMP ('wand-setup-tests-' + [Guid]::NewGuid().ToString('N'))))
$ErrorActionPreference = 'Stop'
$tokens=$null; $parseErrors=$null
[void][Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Start-GamingSetup.ps1'),[ref]$tokens,[ref]$parseErrors)
if ($parseErrors.Count) { throw ($parseErrors | Out-String) }
. (Join-Path $PSScriptRoot 'Start-GamingSetup.ps1') -LibraryOnly
$script:Passed=0
function Check([string]$Name,[scriptblock]$Body) { & $Body; $script:Passed++; Write-Host "PASS: $Name" }
function Assert([bool]$Condition,[string]$Message) { if(-not $Condition){throw $Message} }
function Reject([scriptblock]$Body,[string]$Pattern) {
    $failure=$null
    try { & $Body | Out-Null } catch { $failure=$_.Exception.Message }
    Assert ($null -ne $failure -and $failure -match $Pattern) "Expected rejection '$Pattern'; got '$failure'"
}
function Put([string]$Path,[string]$Text='fixture') {
    [IO.Directory]::CreateDirectory((Split-Path -Parent $Path))|Out-Null
    [IO.File]::WriteAllText($Path,$Text)
}
$fixtureProfile=Join-Path $TestRoot 'Gaming'
$account=[pscustomobject]@{Sid='S-1-5-21-100-100-100-1007';Profile=$fixtureProfile;Name='Gaming'}
$appData=Join-Path $fixtureProfile 'AppData\Local'
[IO.Directory]::CreateDirectory($appData)|Out-Null
Check 'PowerShell 5.1 parser accepts the setup script' { Assert ($parseErrors.Count -eq 0) 'Parse failed' }
Check 'Correct Gaming context accepted' { Assert-UserContext $account $account.Sid $false $appData }
Check 'Wrong Windows account rejected' { Reject { Assert-UserContext $account 'S-1-5-21-other' $false $appData } 'Sign into the Gaming' }
Check 'Already elevated controller rejected' { Reject { Assert-UserContext $account $account.Sid $true $appData } 'normally' }
Check 'Redirected AppData rejected' { Reject { Assert-UserContext $account $account.Sid $false (Join-Path $TestRoot 'redirected') } 'Unexpected' }
Check 'Path traversal and sibling profile rejected' {
    Reject { Assert-SafePath (Join-Path $fixtureProfile '..\Other') $fixtureProfile } 'outside'
    Reject { Assert-SafePath ($fixtureProfile+'Other\file') $fixtureProfile } 'outside'
}
Check 'No fallback into another profile' {
    Put (Join-Path $TestRoot 'Other\AppData\Local\Wand\app-12.63.0\Wand.exe')
    Assert ($null -eq (Find-GamingInstall $fixtureProfile)) 'Unexpected installation'
}
$root=Join-Path $appData 'Wand'; $version=Join-Path $root 'app-12.63.0'
Put (Join-Path $version 'Wand.exe')
Check 'Incomplete official installation rejected' { Reject { Find-GamingInstall $fixtureProfile } 'incomplete' }
Put (Join-Path $version 'resources\app.asar') 'original archive'
Put (Join-Path $version 'resources\app.asar.unpacked\support.dll') 'original support'
$install=Find-GamingInstall $fixtureProfile
Check 'Supported stable installation selected' { Assert ($install.Directory -eq $version) 'Wrong target' }
Check 'Newer version blocks patch rather than choosing older supported version' {
    $newer=Join-Path $root 'app-12.64.0\Wand.exe'; Put $newer
    Reject { Find-GamingInstall $fixtureProfile } 'verified for 12.63.0 only'
    Remove-Item -LiteralPath $newer
}
Check 'Beta version rejected' {
    $beta=Join-Path $root 'app-12.64.0-beta'; [IO.Directory]::CreateDirectory($beta)|Out-Null
    Reject { Find-GamingInstall $fixtureProfile } 'Unsupported/beta'
    Remove-Item -LiteralPath $beta
}
Check 'Delivered executable, manifest and signed installer verified' { Assert-Kit $KitDirectory }
Check 'Corrupt executable rejected' {
    $bad=Join-Path $TestRoot 'bad.exe'; Put $bad
    Reject { Assert-Hash $bad $script:BuildHash } 'verification failed'
}
Check 'Default selection includes remote panel' {
    $selection=Get-Selection $root
    Assert (($selection.Types -join ',') -eq '1,8,16') 'Unexpected default'
}
Check 'Saved selection preserved; custom/unknown scripts rejected' {
    $config=Join-Path $root 'enhancer.json'
    Put $config '{"PatchTypes":[8,16],"AutoApplyAfterUpdate":false,"CustomScriptPaths":[]}'
    $selection=Get-Selection $root
    Assert (($selection.Types -join ',') -eq '8,16' -and -not $selection.AutoApply) 'Saved preferences lost'
    Put $config '{"PatchTypes":[16],"AutoApplyAfterUpdate":true,"CustomScriptPaths":["custom.js"]}'
    Reject { Get-Selection $root } 'Custom renderer'
    Put $config '{"PatchTypes":[128],"AutoApplyAfterUpdate":true}'
    Reject { Get-Selection $root } 'Unknown'
    Remove-Item -LiteralPath $config
}
Check 'Missing official package stops before patch' { Reject { Assert-OriginalResources $install } 'package is missing' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.IO.Compression
$package=Join-Path $root 'packages\Wand-12.63.0-full.nupkg'
[IO.Directory]::CreateDirectory((Split-Path -Parent $package))|Out-Null
$zip=[IO.Compression.ZipFile]::Open($package,[IO.Compression.ZipArchiveMode]::Create)
try {
    foreach($relative in 'app.asar','app.asar.unpacked/support.dll') {
        [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip,(Join-Path $version ('resources\'+$relative)),('lib/net45/resources/'+$relative))
    }
} finally { $zip.Dispose() }
Check 'Pristine resources match package' { Assert-OriginalResources $install }
Check 'Altered support DLL rejected' {
    $dll=Join-Path $version 'resources\app.asar.unpacked\support.dll'; Put $dll 'changed'
    Reject { Assert-OriginalResources $install } 'verification failed'
    Put $dll 'original support'
}
Check 'Incomplete original backup rejected' {
    Copy-Item -LiteralPath (Join-Path $version 'resources\app.asar') -Destination (Join-Path $version 'resources\app.asar.backup')
    Reject { Assert-OriginalResources $install } 'part of the original backup'
}
Copy-Item -LiteralPath (Join-Path $version 'resources\app.asar.unpacked') -Destination (Join-Path $version 'resources\app.asar.unpacked.backup') -Recurse
Check 'Existing complete backups verified for safe reapply' { Assert-OriginalResources $install }
Check 'Junctions rejected before elevated patching' {
    $link=Join-Path $root 'linked'; $destination=Join-Path $TestRoot 'external'; [IO.Directory]::CreateDirectory($destination)|Out-Null
    [void](New-Item -ItemType Junction -Path $link -Target $destination)
    Reject { Assert-SafePath (Join-Path $link 'file') $fixtureProfile } 'Linked/junction'
    Reject { Assert-NoLinkedFiles $root } 'Linked files'
    # Remove just the junction, never recurse into its destination.
    [IO.Directory]::Delete($link)
}
# Exercise worker orchestration without elevation, touching only this fixture.
# The patch engine, session lookup and privilege checks are deliberately mocked.
function Test-Administrator { return $true }
function Assert-NativeProcess { }
function Get-GamingAccount { return $account }
function Assert-SessionOwner($Sid,$Session) { Assert ($Sid -eq $account.Sid -and $Session -eq 7) 'Wrong session passed' }
function Assert-NoWandProcesses { if($script:Busy){throw 'Fixture busy process'} }
function Invoke-EnhancerPatch($Install,$Exe,$Selection) {
    $script:PatchCalls++
    Assert ($Install.Directory -eq $version) 'Elevated worker targeted another account'
    if($script:PatchFailure){throw 'Fixture patch failure'}
}
$enhancerHome=Join-Path $appData 'Programs\WandEnhancer'; [IO.Directory]::CreateDirectory($enhancerHome)|Out-Null
Copy-Item -LiteralPath (Join-Path $KitDirectory 'WandEnhancer.exe') -Destination $enhancerHome
$TargetSid=$account.Sid; $TargetSession=7
$script:Busy=$false; $script:PatchFailure=$false; $script:PatchCalls=0
function New-FixtureRun {
    $script:RunId=[Guid]::NewGuid().ToString('N')
    $script:run=Join-Path $appData "WandEnhancerSetup\runs\$RunId"
    [IO.Directory]::CreateDirectory($run)|Out-Null
}
Check 'Elevated worker targets Gaming even when caller AppData differs' {
    New-FixtureRun
    Invoke-AdminWorker
    $result=Get-Content -LiteralPath (Join-Path $run 'admin-result.json') -Raw|ConvertFrom-Json
    Assert ($result.Success -and $result.Installation -eq $version -and $script:PatchCalls -eq 1) 'Worker did not complete correct target'
}
Check 'Busy process blocks patch and records failure' {
    New-FixtureRun; $script:Busy=$true
    Reject { Invoke-AdminWorker } 'Fixture busy'
    $result=Get-Content -LiteralPath (Join-Path $run 'admin-result.json') -Raw|ConvertFrom-Json
    Assert (-not $result.Success -and $script:PatchCalls -eq 1) 'Busy worker patched or reported success'
    $script:Busy=$false
}
Check 'Patch failure never reports success; locks release for retry' {
    New-FixtureRun; $script:PatchFailure=$true
    Reject { Invoke-AdminWorker } 'Fixture patch failure'
    $result=Get-Content -LiteralPath (Join-Path $run 'admin-result.json') -Raw|ConvertFrom-Json
    Assert (-not $result.Success) 'False success'
    $script:PatchFailure=$false; New-FixtureRun; Invoke-AdminWorker
}
$script:LogPath=$null
Write-Host "`n$script:Passed checks passed. Fixtures retained: $TestRoot"
Write-Host 'No real installation was patched, no UAC prompt was accepted and no games were launched.'
