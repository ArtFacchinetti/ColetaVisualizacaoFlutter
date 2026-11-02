Add-Type -AssemblyName System.Drawing
$raiz = Split-Path $PSScriptRoot -Parent

function Salvar-Icone([string]$destino, [int]$tamanho, [bool]$adaptativo) {
    $imagem = New-Object System.Drawing.Bitmap($tamanho, $tamanho)
    $g = [System.Drawing.Graphics]::FromImage($imagem)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    if ($adaptativo) { $g.Clear([System.Drawing.Color]::Transparent) }
    else { $g.Clear([System.Drawing.ColorTranslator]::FromHtml('#126B66')) }
    $g.ScaleTransform(($tamanho / 512.0), ($tamanho / 512.0))
    $pino = New-Object System.Drawing.Drawing2D.GraphicsPath
    $pino.AddBezier(256, 380, 220, 330, 150, 268, 150, 218)
    $pino.AddBezier(150, 218, 150, 78, 362, 78, 362, 218)
    $pino.AddBezier(362, 218, 362, 268, 292, 330, 256, 380)
    $pino.CloseFigure()
    $g.FillPath([System.Drawing.Brushes]::White, $pino)
    $cor = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml('#FFCB77'))
    $g.FillEllipse($cor, 212, 166, 88, 88)
    $caneta = New-Object System.Drawing.Pen([System.Drawing.ColorTranslator]::FromHtml('#FFCB77'), 12)
    $g.DrawArc($caneta, 168, 354, 176, 62, 0, 180)
    $pasta = Split-Path $destino -Parent
    [System.IO.Directory]::CreateDirectory($pasta) | Out-Null
    $imagem.Save($destino, [System.Drawing.Imaging.ImageFormat]::Png)
    $caneta.Dispose(); $cor.Dispose(); $pino.Dispose(); $g.Dispose(); $imagem.Dispose()
}

Salvar-Icone "$raiz/assets/icons/localizacoes.png" 512 $false
Salvar-Icone "$raiz/android/app/src/main/res/drawable-nodpi/icone_localizacoes.png" 432 $true
$densidades = @{ 'mdpi' = 48; 'hdpi' = 72; 'xhdpi' = 96; 'xxhdpi' = 144; 'xxxhdpi' = 192 }
foreach ($densidade in $densidades.Keys) {
    Salvar-Icone "$raiz/android/app/src/main/res/mipmap-$densidade/ic_localizacoes.png" $densidades[$densidade] $false
}
