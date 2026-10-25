param([Parameter(Mandatory=$true)][string]$AssemblyPath)
$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$assembly=[Reflection.Assembly]::LoadFrom((Resolve-Path -LiteralPath $AssemblyPath).Path)
$terminate=$assembly.GetType('WandEnhancer.Utils.ProcessTerminator',$true).GetMethod('TryKillProcessesUnder')
$verify=$assembly.GetType('WandEnhancer.Core.Patching.Shared.DiskFusePatch',$true).GetMethod('VerifyWritable')
$scratch=Join-Path ([IO.Path]::GetTempPath()) ('wand-lock-test-'+[Guid]::NewGuid().ToString('N'))
$install=Join-Path $scratch 'install';$outside=$install+'-other'
[IO.Directory]::CreateDirectory($install)|Out-Null
[IO.Directory]::CreateDirectory($outside)|Out-Null
$children=@()
function Assert($Condition,[string]$Message){if(-not $Condition){throw $Message}}
function Start-Fixture([string]$Executable,[string]$Target,[int]$Lifetime){
    $ready=$Target+'.ready'
    if(Test-Path -LiteralPath $ready){Remove-Item -LiteralPath $ready}
    $p=Start-Process -FilePath $Executable -ArgumentList ('"{0}" "{1}" {2}' -f $Target,$ready,$Lifetime) -WindowStyle Hidden -PassThru
    $script:children+= $p
    $deadline=[DateTime]::UtcNow.AddSeconds(10)
    while(-not(Test-Path -LiteralPath $ready)){
        if($p.HasExited -or [DateTime]::UtcNow -gt $deadline){throw 'Fixture did not acquire its lock'}
        Start-Sleep -Milliseconds 30
    }
    return $p
}
try{
    # Framework C# fixture works under both Windows PowerShell and pwsh.
    $source=Join-Path $scratch 'holder.cs'
    @'
using System;
using System.IO;
using System.Threading;
class Holder {
 static void Main(string[] args) {
  using(var file=new FileStream(args[0],FileMode.Open,FileAccess.Read,FileShare.Read)) {
   File.WriteAllText(args[1],"ready"); Thread.Sleep(int.Parse(args[2]));
  }
 }
}
'@|Set-Content -LiteralPath $source
    $compiler=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
    $helper=Join-Path $install 'AuxiliaryFixture.exe'
    & $compiler /nologo /target:exe "/out:$helper" $source
    if($LASTEXITCODE -ne 0){throw 'Fixture compiler failed'}
    $otherHelper=Join-Path $outside 'AuxiliaryFixture.exe';Copy-Item -LiteralPath $helper -Destination $otherHelper
    $client=Join-Path $install 'Wand.exe';[IO.File]::WriteAllText($client,'unchanged client fixture')
    $otherFile=Join-Path $outside 'data';[IO.File]::WriteAllText($otherFile,'other account fixture')
    $initial=(Get-FileHash -LiteralPath $client).Hash
    $p=Start-Fixture $otherHelper $client 900
    $verify.Invoke($null,@($client))|Out-Null
    Assert ((Get-FileHash -LiteralPath $client).Hash -eq $initial) 'Transient-lock check wrote the client'
    Write-Host 'PASS: transient executable lock is retried without changing bytes'
    $p.WaitForExit()
    $p=Start-Fixture $otherHelper $client 15000
    $failed=$false
    try{$verify.Invoke($null,@($client))|Out-Null}catch{$failed=$_.Exception.ToString().Contains('executable is still locked')}
    Assert $failed 'Persistent lock did not produce an actionable failure'
    Assert (-not $p.HasExited) 'File verification killed the outside process'
    $p.Kill();$p.WaitForExit()
    Write-Host 'PASS: persistent lock fails and preserves outside process and file'
    $inside=Start-Fixture $helper $client 20000
    $other=Start-Fixture $otherHelper $otherFile 20000
    $terminate.Invoke($null,@($install))|Out-Null
    Assert ($inside.WaitForExit(5000)) 'Auxiliary process under selected install survived'
    Assert (-not $other.HasExited) 'Sibling/other installation was terminated'
    $verify.Invoke($null,@($client))|Out-Null
    Write-Host 'PASS: scoped shutdown releases auxiliary lock and preserves sibling installation'
    $updater=Join-Path $install 'Update.exe';Copy-Item -LiteralPath $helper -Destination $updater
    $p=Start-Fixture $updater $client 20000
    $failed=$false
    try{$terminate.Invoke($null,@($install))|Out-Null}catch{$failed=$_.Exception.ToString().Contains('Wait for the update to finish')}
    Assert ($failed -and -not $p.HasExited) 'Active installer was interrupted or not reported'
    Write-Host 'PASS: active installer blocks patching and remains running'
}finally{
    foreach($p in $children){if(-not $p.HasExited){$p.Kill();$p.WaitForExit(5000)|Out-Null};$p.Dispose()}
    # Unique test directory only; retain fixtures on cleanup failure.
    if([IO.Path]::GetFullPath($scratch).StartsWith([IO.Path]::GetFullPath([IO.Path]::GetTempPath()),[StringComparison]::OrdinalIgnoreCase)){
        Remove-Item -LiteralPath $scratch -Recurse -Force
    }
}
