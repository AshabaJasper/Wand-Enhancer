param([string]$OutputDirectory = (Join-Path $PSScriptRoot 'bin'))
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$compiler = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (!(Test-Path -LiteralPath $compiler)) { throw 'Windows .NET Framework compiler is required.' }
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$output = [IO.Path]::GetFullPath($OutputDirectory)
$package = Join-Path $output 'qrcoder.1.8.0.zip'
Invoke-WebRequest 'https://api.nuget.org/v3-flatcontainer/qrcoder/1.8.0/qrcoder.1.8.0.nupkg' -OutFile $package
if ((Get-FileHash -LiteralPath $package -Algorithm SHA256).Hash -ne '52F39E145C5467F6DD7660ECE886A689818321F831C9B13F092A4FCB2E433312') { throw 'QRCoder package hash mismatch.' }
$dependency = Join-Path $output 'dependency'
Expand-Archive -LiteralPath $package -DestinationPath $dependency -Force
Copy-Item -LiteralPath (Join-Path $dependency 'lib\net40\QRCoder.dll') -Destination $output
Copy-Item -LiteralPath (Join-Path $dependency 'LICENSE.txt') -Destination (Join-Path $output 'QRCoder-LICENSE.txt')
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'README.md') -Destination $output
$exe = Join-Path $output 'WandPhoneHelper.exe'
$sha = (& git -C $repo rev-parse HEAD).Trim()
$dirty = [bool](& git -C $repo status --porcelain)
$stamp = Join-Path $output 'BuildStamp.cs'
$suffix = if ($dirty) { '.dirty' } else { '' }
('using System.Reflection; [assembly: AssemblyInformationalVersion("1.0.0+' + $sha + $suffix + '")]') | Set-Content -LiteralPath $stamp -Encoding UTF8
& $compiler /nologo /target:winexe "/out:$exe" /reference:System.Drawing.dll /reference:System.Windows.Forms.dll /reference:System.Net.Http.dll /reference:System.Web.Extensions.dll "/reference:$(Join-Path $output 'QRCoder.dll')" "/resource:$(Join-Path $repo 'web-panel\protocol\web-contract.json'),web-contract.json" "/win32icon:$(Join-Path $repo 'assets\appicon.ico')" (Join-Path $PSScriptRoot 'PhoneHelper.cs') $stamp
if ($LASTEXITCODE -ne 0) { throw 'Helper compilation failed.' }
$testOutput = Join-Path $output 'test-output.txt'
$test = Start-Process -FilePath $exe -ArgumentList '--self-test' -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput $testOutput
if ($test.ExitCode -ne 0) { throw 'Helper checks failed.' }
Get-Content -LiteralPath $testOutput
@{version='1.0.0.0';sourceCommit=$sha;dirty=$dirty;sha256=(Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash;component='Wand Phone Helper only';wandEnhancerVersion='2.1.2.0'} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'build-info.json') -Encoding UTF8
$setup = Join-Path $output 'WandPhoneHelper-Setup.exe'
$resources = @('WandPhoneHelper.exe','QRCoder.dll','QRCoder-LICENSE.txt','build-info.json','README.md') | ForEach-Object { '/resource:' + (Join-Path $output $_) + ',' + $_ }
& $compiler /nologo /target:winexe "/out:$setup" /reference:System.Drawing.dll /reference:System.Windows.Forms.dll "/win32icon:$(Join-Path $repo 'assets\appicon.ico')" $resources (Join-Path $PSScriptRoot 'Setup.cs') $stamp
if ($LASTEXITCODE -ne 0) { throw 'Installer compilation failed.' }
@{sourceCommit=$sha;sha256=(Get-FileHash -LiteralPath $setup -Algorithm SHA256).Hash;component='Wand Phone Helper installer only'} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'installer-info.json') -Encoding UTF8
Write-Output "Built helper and installer in $output"
