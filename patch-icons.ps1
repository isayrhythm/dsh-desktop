$ErrorActionPreference = 'SilentlyContinue'
$src = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'assets'
$icoPath = Join-Path $src 'icon.ico'

function Extract-IcoPng([string]$path, [string]$outPath, [int]$size) {
    $b = [System.IO.File]::ReadAllBytes($path)
    $count = [System.BitConverter]::ToUInt16($b, 4)
    for ($i = 0; $i -lt $count; $i++) {
        $e = 6 + $i * 16
        $w = $b[$e]; if ($w -eq 0) { $w = 256 }
        if ($w -eq $size) {
            $len = [System.BitConverter]::ToUInt32($b, $e + 8)
            $off = [System.BitConverter]::ToUInt32($b, $e + 12)
            $png = New-Object byte[] $len
            [System.Array]::Copy($b, $off, $png, 0, $len)
            [System.IO.File]::WriteAllBytes($outPath, $png)
            return $true
        }
    }
    return $false
}

$patched = @()
Get-ChildItem "$env:LOCALAPPDATA\npm-cache\_npx" -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $dist = Join-Path $_.FullName 'node_modules\@deepseek-ai\dsh-web-frontend\dist'
    if (-not (Test-Path (Join-Path $dist 'index.html'))) { return }
    New-Item -ItemType Directory -Force -Path (Join-Path $dist 'icons') | Out-Null
    $extracted = Extract-IcoPng $icoPath (Join-Path $dist 'icons\icon-256.png') 256
    if (-not $extracted) { Write-Output ('WARN: no 256 entry in ico: ' + $icoPath) }
    if (-not (Test-Path (Join-Path $dist 'icons\icon-512.png')) -and $extracted) {
        Add-Type -AssemblyName System.Drawing
        $img = [System.Drawing.Image]::FromFile((Join-Path $dist 'icons\icon-256.png'))
        $bmp = New-Object System.Drawing.Bitmap(512, 512, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($img, 0, 0, 512, 512)
        $g.Dispose(); $img.Dispose()
        $bmp.Save((Join-Path $dist 'icons\icon-512.png'), [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
    }
    Copy-Item -LiteralPath $icoPath -Destination (Join-Path $dist 'favicon.ico') -Force
    $ih = Join-Path $dist 'index.html'
    $h = Get-Content -LiteralPath $ih -Raw
    $changed = $false
    if ($h -notmatch 'favicon\.ico') {
        $h = $h.Replace('<link rel="manifest"', '<link rel="icon" type="image/x-icon" href="/favicon.ico?v=2" />' + [char]10 + '    <link rel="manifest"')
        $changed = $true
    }
    if ($h -notmatch 'icon-256\.png') {
        $h = $h.Replace('<link rel="manifest"', '<link rel="icon" type="image/png" sizes="256x256" href="/icons/icon-256.png?v=2" />' + [char]10 + '    <link rel="manifest"')
        $changed = $true
    }
    if ($changed) { Set-Content -LiteralPath $ih -Value $h -Encoding UTF8 }
    $mf = Join-Path $dist 'manifest.webmanifest'
    $m = Get-Content -LiteralPath $mf -Raw | ConvertFrom-Json
    $names = $m.icons | ForEach-Object { $_.src }
    if ($names -notcontains '/icons/icon-256.png') {
        $m.icons += [pscustomobject]@{ src = '/icons/icon-256.png'; sizes = '256x256'; type = 'image/png'; purpose = 'any' }
    }
    if ($names -notcontains '/icons/icon-512.png') {
        $m.icons += [pscustomobject]@{ src = '/icons/icon-512.png'; sizes = '512x512'; type = 'image/png'; purpose = 'any' }
    }
    $m | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $mf -Encoding UTF8
    $patched += $dist
}
if ($patched.Count -gt 0) { Write-Output ('patched: ' + ($patched -join ', ')) } else { Write-Output 'no dist found' }
