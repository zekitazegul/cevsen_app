param(
    [string]$Repository = 'zekitazegul/cevsen_app',
    [string]$ApkPath = 'build/app/outputs/flutter-apk/app-release.apk',
    [string]$InstallerPath = 'build/installer/outputs/apk/release/installer-release.apk',
    [switch]$PrepareOnly
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
$installer = Get-Item -LiteralPath $InstallerPath
if ($installer.Length -ge 5MB) { throw 'Installer exceeds 5 MB.' }
$installerDestination = Join-Path $folder.FullName 'Cevsen-Installer.apk'
Copy-Item -LiteralPath $installer.FullName -Destination $installerDestination

# Check the final package rather than relying on asset declarations.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($destination)
try {
    if (@($archive.Entries | Where-Object { $_.FullName.EndsWith('.mp3') }).Count -gt 0) {
        throw 'Main APK must not contain MP3 recordings.'
    }
    $entry = $archive.GetEntry('assets/Cevsen-Installer.apk')
    if ($null -eq $entry) { throw 'Embedded installer is missing.' }
    $stream = $entry.Open()
    $digest = [Security.Cryptography.SHA256]::Create()
    try { $embeddedHash = ([BitConverter]::ToString($digest.ComputeHash($stream))).Replace('-', '') }
    finally { $digest.Dispose(); $stream.Dispose() }
    if ($embeddedHash -ne (Get-FileHash -LiteralPath $installer.FullName -Algorithm SHA256).Hash) {
        throw 'Embedded installer is stale. Rebuild the main APK.'
    }
} finally { $archive.Dispose() }

$metadata = [ordered]@{
    versionName = $version
    versionCode = [long]$build
    sizeBytes = (Get-Item -LiteralPath $destination).Length
    apkUrl = "https://github.com/$Repository/releases/download/$tag/Cevsen.apk"
    sha256 = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
}
$manifest = Join-Path $folder.FullName 'update.json'
[IO.File]::WriteAllText($manifest, ($metadata | ConvertTo-Json), [Text.UTF8Encoding]::new($false))
$notes = Join-Path $folder.FullName 'release-notes.md'
# The source notes are UTF-8 and are passed as a file to preserve Turkish characters.
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'release-notes.md') -Destination $notes
if ($PrepareOnly) {
    Write-Output "Release package prepared: $($folder.FullName)"
    return
}
gh release create $tag $destination $installerDestination $manifest --repo $Repository --title "Cevsen $version" --notes-file $notes --latest
if ($LASTEXITCODE -ne 0) { throw 'Release failed. Increase the version before replacing an existing tag.' }
