param([Parameter(Mandatory=$true)][string]$AssemblyPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$exe=(Resolve-Path -LiteralPath $AssemblyPath).Path
$assembly=[Reflection.Assembly]::LoadFrom($exe)
$watcherType=$assembly.GetType('WandEnhancer.Core.Services.UpdateWatcherService',$true)
$enhancerType=$assembly.GetType('WandEnhancer.Core.Enhancer',$true)
$scratch=Join-Path ([IO.Path]::GetTempPath()) ('wand-watcher-test-'+[Guid]::NewGuid().ToString('N'))
$root=Join-Path $scratch 'Wand';[IO.Directory]::CreateDirectory($root)|Out-Null
$children=@()
function Assert($Condition,[string]$Message){if(-not $Condition){throw $Message}}
function Log-Contains([string]$Text){
    $log=Join-Path $root 'launcher.log'
    return (Test-Path -LiteralPath $log) -and ([IO.File]::ReadAllText($log).Contains($Text))
}
function Wait-Until([scriptblock]$Check,[string]$Message,[int]$Seconds=30){
    $deadline=[DateTime]::UtcNow.AddSeconds($Seconds)
    while(-not (& $Check)){
        if([DateTime]::UtcNow -ge $deadline){throw $Message}
        Start-Sleep -Milliseconds 100
    }
}
try{
    # Direct watch mode does not register startup. All patch targets are harmless fixtures.
    '{"PatchTypes":[],"Strategy":1,"CustomScriptPaths":[],"AutoApplyAfterUpdate":true}'|Set-Content -LiteralPath (Join-Path $root 'enhancer.json')
    $watcher=Start-Process -FilePath $exe -ArgumentList ('--watch-updates "{0}"' -f $root) -WindowStyle Hidden -PassThru
    $children+=$watcher
    Wait-Until {Log-Contains '[WATCHER] Watching'} 'Watcher did not start'

    # A sleeping update fixture lets us prove a stable archive alone never triggers a patch.
    $source=Join-Path $scratch 'updater.cs'
    'class Updater { static void Main() { System.Threading.Thread.Sleep(60000); } }'|Set-Content -LiteralPath $source
    $updaterExe=Join-Path $root 'Update.exe'
    & (Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe') /nologo /target:exe "/out:$updaterExe" $source
    if($LASTEXITCODE -ne 0){throw 'Updater fixture compilation failed'}
    $updater=Start-Process -FilePath $updaterExe -WindowStyle Hidden -PassThru;$children+=$updater

    $version=Join-Path $root 'app-1.0.0'
    $resources=Join-Path $version 'resources';[IO.Directory]::CreateDirectory($resources)|Out-Null
    $pack=Join-Path $scratch 'pack';[IO.Directory]::CreateDirectory((Join-Path $pack 'static\unpacked'))|Out-Null
    [IO.File]::WriteAllText((Join-Path $pack 'index.js'),'console.log("fixture only");')
    [IO.File]::WriteAllText((Join-Path $pack 'static\unpacked\native.dll'),'not executable; fixture bytes')
    $options=[Activator]::CreateInstance($assembly.GetType('AsarSharp.CreateOptions',$true));$options.Unpack=[regex]::new('^static[\\/]unpacked(?:[\\/]|$)')
    $creator=[Activator]::CreateInstance($assembly.GetType('AsarSharp.AsarCreator',$true),[object[]]@([string]$pack,[string](Join-Path $resources 'app.asar'),$options.PSObject.BaseObject))
    $creator.CreatePackageWithOptions()
    # Valid fuse wire in a deliberately non-executable file; no real client is launched.
    [byte[]]$wire=[Text.Encoding]::ASCII.GetBytes('dL7pKGdnNz796PbbjQWNKmHXBZaB9tsX') + [byte[]]@(1,5,48,48,48,48,49)
    [IO.File]::WriteAllBytes((Join-Path $version 'Wand.exe'),$wire)
    $archiveHash=(Get-FileHash -LiteralPath (Join-Path $resources 'app.asar')).Hash
    Wait-Until {Log-Contains 'New version folder detected'} 'New version event was missed'
    Start-Sleep -Seconds 10
    Assert (-not $updater.HasExited) 'Watcher terminated an updater'
    Assert (-not (Log-Contains 'Re-applying patches')) 'Watcher patched while the updater was active'
    Assert ((Get-FileHash -LiteralPath (Join-Path $resources 'app.asar')).Hash -eq $archiveHash) 'Archive changed while updater was active'
    Write-Host 'PASS: watcher leaves active updater and archive untouched after stable-size reads'
    $updater.Kill();$updater.WaitForExit()
    Wait-Until {Log-Contains 'Auto-patch after update succeeded'} 'Watcher did not finish the fixture patch after updater exit' 40
    Assert ($enhancerType.GetMethod('IsPatched').Invoke($null,[object[]]@([string]$version))) 'Fixture patch state incomplete'
    Assert ((Get-FileHash -LiteralPath (Join-Path $resources 'app.asar.backup')).Hash -eq $archiveHash) 'Original archive backup lost'
    Assert ([IO.File]::ReadAllBytes((Join-Path $version 'Wand.exe'))[38] -eq 114) 'Static fuse was not patched'
    Assert (-not $watcher.HasExited) 'Watcher stopped itself while patching'
    Write-Host 'PASS: watcher completes Static patch after updater exit, retains backups and survives'

    $stop=$watcherType.GetMethod('Stop')
    $stop.Invoke($null,[object[]]@([string]$root))|Out-Null
    Assert ($watcher.WaitForExit(10000)) 'Watcher did not stop on request'
    Write-Host 'PASS: watcher stop signal exits the real watcher process'
}finally{
    foreach($p in $children){if(-not $p.HasExited){$p.Kill();$p.WaitForExit(5000)|Out-Null};$p.Dispose()}
    if([IO.Path]::GetFullPath($scratch).StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase)){
        Remove-Item -LiteralPath $scratch -Recurse -Force
    }
}
