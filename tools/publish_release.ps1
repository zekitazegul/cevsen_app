param(
    [string]$Repository = 'zekitazegul/cevsen_app',
    [string]$ApkPath = 'build/app/outputs/flutter-apk/app-release.apk'
)
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
$versionLine = (Select-String -Path pubspec.yaml -Pattern '^version: (\S+)').Matches[0].Groups[1].Value
$version, $build = $versionLine.Split('+')
$apk = Get-Item -LiteralPath $ApkPath
$tag = "v$version-$build"
$folder = New-Item -ItemType Directory -Force -Path "build/releases/$tag"
$destination = Join-Path $folder.FullName 'Cevsen.apk'
Copy-Item -LiteralPath $apk.FullName -Destination $destination
$metadata = [ordered]@{
    versionName = $version
    versionCode = [long]$build
    sizeBytes = (Get-Item -LiteralPath $destination).Length
    apkUrl = "https://github.com/$Repository/releases/download/$tag/Cevsen.apk"
    sha256 = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
}
$manifest = Join-Path $folder.FullName 'update.json'
[IO.File]::WriteAllText($manifest, ($metadata | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
gh release create $tag $destination $manifest --repo $Repository --title "Cevşen $version" --notes "Uygulama içinden APK paylaşımı ve GitHub üzerinden güncelleme. / APK sharing and in-app updates. / APK delen en updates in de app." --latest
if ($LASTEXITCODE -ne 0) { throw 'Sürüm yayımlanamadı. Aynı etiket varsa üzerine yazmadan önce sürümü artır.' }
