# Генератор иконок приложения «Мои дела» (PNG 192/512 + maskable)
# Фон — фиолетовый диагональный градиент, галочка белая.
Add-Type -AssemblyName System.Drawing

$GRAD_FROM = [System.Drawing.Color]::FromArgb(255, 168, 85, 247)  # #A855F7
$GRAD_TO   = [System.Drawing.Color]::FromArgb(255, 109, 40, 217)  # #6D28D9

function New-GradientBrush {
  param([int]$Size)
  $rect = New-Object System.Drawing.RectangleF 0, 0, $Size, $Size
  $mode = [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal
  New-Object System.Drawing.Drawing2D.LinearGradientBrush -ArgumentList $rect, $GRAD_FROM, $GRAD_TO, $mode
}

function New-Icon {
  param([int]$Size, [string]$Path, [double]$CheckScale, [switch]$FullBleed)

  $bmp = New-Object System.Drawing.Bitmap $Size, $Size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

  if ($FullBleed) {
    # маскируемая иконка: градиент на весь квадрат, содержимое в безопасной зоне
    $grad = New-GradientBrush $Size
    $g.FillRectangle($grad, 0, 0, $Size, $Size)
    $grad.Dispose()
  } else {
    $g.Clear([System.Drawing.Color]::Transparent)
    $r = $Size * 0.22
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddArc(0, 0, 2 * $r, 2 * $r, 180, 90)
    $p.AddArc($Size - 2 * $r, 0, 2 * $r, 2 * $r, 270, 90)
    $p.AddArc($Size - 2 * $r, $Size - 2 * $r, 2 * $r, 2 * $r, 0, 90)
    $p.AddArc(0, $Size - 2 * $r, 2 * $r, 2 * $r, 90, 90)
    $p.CloseFigure()
    $grad = New-GradientBrush $Size
    $g.FillPath($grad, $p)
    $grad.Dispose(); $p.Dispose()
  }

  # галочка: нормализованные точки (0..1), масштабируются вокруг центра
  $pts = [System.Drawing.PointF[]]@(
    [System.Drawing.PointF]::new(0.28, 0.53),
    [System.Drawing.PointF]::new(0.44, 0.68),
    [System.Drawing.PointF]::new(0.75, 0.34)
  ) | ForEach-Object {
    [System.Drawing.PointF]::new(
      [float](($Size * (0.5 + ($_.X - 0.5) * $CheckScale))),
      [float](($Size * (0.5 + ($_.Y - 0.5) * $CheckScale)))
    )
  }

  $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), ([float]($Size * 0.088))
  $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.EndCap   = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  $g.DrawLines($pen, [System.Drawing.PointF[]]$pts)
  $pen.Dispose()

  $g.Dispose()
  $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
  Write-Host "OK $Path"
}

$dir = Join-Path $PSScriptRoot 'icons'
New-Item -ItemType Directory -Force -Path $dir | Out-Null
New-Icon -Size 192 -Path (Join-Path $dir 'icon-192.png') -CheckScale 1.0
New-Icon -Size 512 -Path (Join-Path $dir 'icon-512.png') -CheckScale 1.0
New-Icon -Size 512 -Path (Join-Path $dir 'icon-maskable-512.png') -CheckScale 0.62 -FullBleed
