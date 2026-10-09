param([string]$Output)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Path $Output -Force | Out-Null
foreach($entry in @(@{Size=192;Name='icon-192.png'},@{Size=512;Name='icon-512.png'},@{Size=180;Name='apple-touch-icon.png'})) {
 $size=$entry.Size
 $bitmap=[Drawing.Bitmap]::new($size,$size)
 $g=[Drawing.Graphics]::FromImage($bitmap)
 $g.SmoothingMode=[Drawing.Drawing2D.SmoothingMode]::AntiAlias
 $dark=[Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#10131a'))
 $white=[Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml('#f2f4f8'))
 $g.FillRectangle($dark,0,0,$size,$size)
 $points=[Drawing.PointF[]]@([Drawing.PointF]::new($size*.5,$size*.18),[Drawing.PointF]::new($size*.82,$size*.5),[Drawing.PointF]::new($size*.5,$size*.82),[Drawing.PointF]::new($size*.18,$size*.5))
 $g.FillPolygon($white,$points)
 foreach($point in @(@{X=.5;Y=.37},@{X=.37;Y=.5},@{X=.63;Y=.5},@{X=.5;Y=.63})) {
  $r=$size*.035
  $g.FillEllipse($dark,[float]($point.X*$size-$r),[float]($point.Y*$size-$r),[float](2*$r),[float](2*$r))
 }
 $bitmap.Save((Join-Path $Output $entry.Name),[Drawing.Imaging.ImageFormat]::Png)
 $g.Dispose();$bitmap.Dispose();$dark.Dispose();$white.Dispose()
}
