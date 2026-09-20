param([string]$Repo, [string]$Output)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase
$app=New-Object System.Windows.Application
foreach($file in @('Locale/lang.en-US.xaml','Style/ColorScheme.xaml','Style/Styles.xaml','Style/Icons.xaml')){
 $dictionary=[Windows.Markup.XamlReader]::Parse([IO.File]::ReadAllText((Join-Path $Repo "WandEnhancer/$file")))
 $app.Resources.MergedDictionaries.Add($dictionary)
}
$app.Resources.Add('ToVisibilityConverter', [Windows.Controls.BooleanToVisibilityConverter]::new())
$app.Resources['Inter']=New-Object Windows.Media.FontFamily('Segoe UI')
New-Item -ItemType Directory -Path $Output -Force | Out-Null
$source=[IO.File]::ReadAllText((Join-Path $Repo 'WandEnhancer/View/MainWindow/MainWindow.xaml'))
# Presentation-only preview: no Enhancer assembly, constructor, event handler, command or patch code is loaded.
$source=$source -replace 'x:Class="[^"]+"',''
$source=$source -replace 'Closing="[^"]+"',''
$source=$source -replace 'Click="[^"]+"',''
$source=$source -replace '<controls:PopupHost x:Name="PopupHost"\s*/>','<Grid x:Name="PopupHost" Visibility="Collapsed"/>'
foreach($scenario in @(
 @{Name='ready';Width=980;Height=690;Busy=$false;Patched=$false;Missing=$false},
 @{Name='compact';Width=640;Height=510;Busy=$false;Patched=$false;Missing=$false},
 @{Name='working';Width=980;Height=690;Busy=$true;Patched=$false;Missing=$false},
 @{Name='restore';Width=980;Height=690;Busy=$false;Patched=$true;Missing=$false},
 @{Name='missing';Width=640;Height=510;Busy=$false;Patched=$false;Missing=$true}
)){
 $window=[Windows.Markup.XamlReader]::Parse($source)
 $root=$window.Content
 $window.Content=$null
 $root.Background=$app.Resources['Background']
 [Windows.Documents.TextElement]::SetForeground($root,$app.Resources['Foreground'])
 [Windows.Documents.TextElement]::SetFontFamily($root,(New-Object Windows.Media.FontFamily('Segoe UI')))
 [Windows.Documents.TextElement]::SetFontSize($root,14)
 $install=if($scenario.Missing){$null}else{[pscustomobject]@{RootDirectory='C:\Users\Player\AppData\Local\Wand\app-12.56.0'}}
 $root.DataContext=[pscustomobject]@{
  WeModInfo=$install;IsBusy=$scenario.Busy;IsIdle=(-not $scenario.Busy);AlreadyPatched=$scenario.Patched
  CanRestore=$scenario.Patched;IsPatchEnabled=(-not $scenario.Patched -and -not $scenario.Missing)
  IsUpdateAvailable=$false;ShowUpdateCommand=$null
  OpenSettingsCommand=$null;SetFolderPathCommand=$null;CopyLogsCommand=$null;ExportLogsCommand=$null
  RestoreBackupCommand=$null;ApplyPatchCommand=$null
  LogList=@(
   [pscustomobject]@{LogType='Success';Message='[SUCCESS] Preview: Wand installation located.'},
   [pscustomobject]@{LogType='Info';Message='[INFO] Preview: review your options before applying.'},
   [pscustomobject]@{LogType='Warn';Message='[WARN] Preview: this is a sample warning, not a live result.'},
   [pscustomobject]@{LogType='Error';Message='[ERROR] Preview: sample failure text stays readable and can be copied.'}
  )
 }
 $size=New-Object Windows.Size($scenario.Width,$scenario.Height)
 $root.Measure($size);$root.Arrange((New-Object Windows.Rect($size)));$root.UpdateLayout()
 $bitmap=New-Object Windows.Media.Imaging.RenderTargetBitmap($scenario.Width,$scenario.Height,96,96,[Windows.Media.PixelFormats]::Pbgra32)
 $bitmap.Render($root)
 $encoder=New-Object Windows.Media.Imaging.PngBitmapEncoder
 $encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
 $stream=[IO.File]::Create((Join-Path $Output ($scenario.Name+'.png')))
 try{$encoder.Save($stream)}finally{$stream.Dispose()}
 $window.Close()
 Write-Output "Rendered $($scenario.Name): $($scenario.Width)x$($scenario.Height)"
}



$hostSource=[IO.File]::ReadAllText((Join-Path $Repo 'WandEnhancer/View/Controls/PopupHost.xaml'))
$hostSource=$hostSource -replace 'x:Class="[^"]+"','' -replace 'MouseLeftButtonDown="[^"]+"','' -replace 'Click="[^"]+"',''
$hostSource=$hostSource.Replace('Visibility="Collapsed"','Visibility="Visible"')
$hostControl=[Windows.Markup.XamlReader]::Parse($hostSource)
$dialogSource=[IO.File]::ReadAllText((Join-Path $Repo 'WandEnhancer/View/Popups/PatchVectorsPopup.xaml'))
$dialogSource=$dialogSource -replace 'x:Class="[^"]+"','' -replace 'Click="[^"]+"',''
$dialog=[Windows.Markup.XamlReader]::Parse($dialogSource)
$dialog.FindName('StrategyComboBox').ItemsSource=@([pscustomobject]@{DisplayName='Static (default)'},[pscustomobject]@{DisplayName='Supervised'})
$dialog.FindName('StrategyComboBox').SelectedIndex=0
$hostControl.FindName('Presenter').Content=$dialog
$hostControl.FindName('Title').Text='Choose changes'
$hostControl.Background=$app.Resources['Background']
$size=New-Object Windows.Size(640,510)
$hostControl.Measure($size);$hostControl.Arrange((New-Object Windows.Rect($size)));$hostControl.UpdateLayout()
$bitmap=New-Object Windows.Media.Imaging.RenderTargetBitmap(640,510,96,96,[Windows.Media.PixelFormats]::Pbgra32)
$bitmap.Render($hostControl)
$encoder=New-Object Windows.Media.Imaging.PngBitmapEncoder
$encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($bitmap))
$stream=[IO.File]::Create((Join-Path $Output 'options-compact.png'))
try{$encoder.Save($stream)}finally{$stream.Dispose()}
Write-Output 'Rendered options: 640x510 (presentation only).'

