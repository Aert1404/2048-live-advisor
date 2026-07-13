param(
  [Parameter(Mandatory = $true)]
  [string] $ImagePath
)

# Native Windows OCR, restricted to the 16 board cells. It combines the
# unmodified frame and a high-contrast board-only copy: this avoids using tile
# colours as game data while improving recognition of bright tile numerals.
Add-Type -AssemblyName System.Runtime.WindowsRuntime
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies 'System.Drawing.dll' -TypeDefinition @'
using System.Drawing;
using System.Drawing.Imaging;

public static class PurpleBoardContrast {
  public static void Create(string sourcePath, string outputPath) {
    using (var source = new Bitmap(sourcePath))
    using (var output = new Bitmap(900, 900, PixelFormat.Format24bppRgb)) {
      for (var y = 0; y < 900; y++) {
        for (var x = 0; x < 900; x++) {
          var pixel = source.GetPixel(x + 90, y + 745);
          output.SetPixel(x, y,
            pixel.R > 205 && pixel.G > 205 && pixel.B > 205 ? Color.Black : Color.White);
        }
      }
      output.Save(outputPath, ImageFormat.Png);
    }
  }
}
'@
$null = [Windows.Storage.StorageFile, Windows.Storage, ContentType = WindowsRuntime]
$null = [Windows.Storage.FileAccessMode, Windows.Storage, ContentType = WindowsRuntime]
$null = [Windows.Storage.Streams.IRandomAccessStream, Windows.Storage.Streams, ContentType = WindowsRuntime]
$null = [Windows.Graphics.Imaging.BitmapDecoder, Windows.Graphics.Imaging, ContentType = WindowsRuntime]
$null = [Windows.Graphics.Imaging.SoftwareBitmap, Windows.Graphics.Imaging, ContentType = WindowsRuntime]
$null = [Windows.Media.Ocr.OcrEngine, Windows.Foundation, ContentType = WindowsRuntime]
$null = [Windows.Media.Ocr.OcrResult, Windows.Foundation, ContentType = WindowsRuntime]
$null = [Windows.Globalization.Language, Windows.Globalization, ContentType = WindowsRuntime]

function Wait-WinRt($operation, [Type] $resultType) {
  $method = [System.WindowsRuntimeSystemExtensions].GetMethods() |
    Where-Object { $_.Name -eq 'AsTask' -and $_.IsGenericMethodDefinition -and $_.GetParameters().Count -eq 1 } |
    Select-Object -First 1
  $task = $method.MakeGenericMethod($resultType).Invoke($null, @($operation))
  return $task.GetAwaiter().GetResult()
}

$engine = [Windows.Media.Ocr.OcrEngine]::TryCreateFromLanguage([Windows.Globalization.Language]::new('en-US'))

function Read-Words([string] $path, [int] $offsetX, [int] $offsetY) {
  $file = Wait-WinRt ([Windows.Storage.StorageFile]::GetFileFromPathAsync((Resolve-Path $path))) ([Windows.Storage.StorageFile])
  $stream = Wait-WinRt ($file.OpenAsync([Windows.Storage.FileAccessMode]::Read)) ([Windows.Storage.Streams.IRandomAccessStream])
  $decoder = Wait-WinRt ([Windows.Graphics.Imaging.BitmapDecoder]::CreateAsync($stream)) ([Windows.Graphics.Imaging.BitmapDecoder])
  $bitmap = Wait-WinRt ($decoder.GetSoftwareBitmapAsync()) ([Windows.Graphics.Imaging.SoftwareBitmap])
  $result = Wait-WinRt ($engine.RecognizeAsync($bitmap)) ([Windows.Media.Ocr.OcrResult])
  $words = @()
  foreach ($line in $result.Lines) {
    foreach ($word in $line.Words) {
      $words += [pscustomobject]@{
        text = $word.Text.Trim()
        x = [double]$word.BoundingRect.X + $offsetX
        y = [double]$word.BoundingRect.Y + $offsetY
        width = [double]$word.BoundingRect.Width
        height = [double]$word.BoundingRect.Height
      }
    }
  }
  return $words
}

# Exact cell pitch from purple-board.png. The same native screen resolution is
# preserved by ADB screencap, regardless of how large the scrcpy window is.
$gridLeft = 120
$gridTop = 777
$cellPitchX = 210
$cellPitchY = 212
$board = @(@(0, 0, 0, 0), @(0, 0, 0, 0), @(0, 0, 0, 0), @(0, 0, 0, 0))
$allowed = @('2', '4', '8', '16', '32', '64', '128', '256', '512', '1024', '2048')
$candidates = @(Read-Words $ImagePath 0 0)

# Keep white glyphs and discard the varied tile/background artwork. This is a
# contrast transformation, not a tile-colour classifier.
$temporaryImage = Join-Path $env:TEMP ('purple-board-' + [guid]::NewGuid() + '.png')
[PurpleBoardContrast]::Create((Resolve-Path $ImagePath), $temporaryImage)
try {
  $candidates += @(Read-Words $temporaryImage 90 745)
} finally {
  Remove-Item -LiteralPath $temporaryImage -Force -ErrorAction SilentlyContinue
}

foreach ($word in $candidates) {
  if ($word.text -notin $allowed) { continue }
  $column = [math]::Floor((($word.x + $word.width / 2) - $gridLeft) / $cellPitchX)
  $row = [math]::Floor((($word.y + $word.height / 2) - $gridTop) / $cellPitchY)
  if ($row -ge 0 -and $row -lt 4 -and $column -ge 0 -and $column -lt 4) {
    $board[$row][$column] = [int]$word.text
  }
}

'[' + (($board | ForEach-Object { '[' + ($_ -join ',') + ']' }) -join ',') + ']'
