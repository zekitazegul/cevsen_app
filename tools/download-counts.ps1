param([string[]]$Repositories = @('zekitazegul/cevsen_app', 'zekitazegul/kuran_app'))
$ErrorActionPreference = 'Stop'
foreach ($repository in $Repositories) {
    if ($repository -notmatch '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$') { throw 'Invalid repository name.' }
    $appCount = 0L
    $installerCount = 0L
    $page = 1
    do {
        $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/$repository/releases?per_page=100&page=$page" -Headers @{ 'User-Agent' = 'App-download-counts'; 'Cache-Control' = 'no-cache' }
        foreach ($release in $releases) {
            if ($release.draft) { continue }
            foreach ($asset in $release.assets) {
                if ($asset.name -notlike '*.apk') { continue }
                if ($asset.name -like '*Installer*') { $installerCount += $asset.download_count }
                else { $appCount += $asset.download_count }
            }
        }
        $page++
    } while ($releases.Count -eq 100)
    [PSCustomObject]@{ Repository = $repository; AppDownloads = $appCount; InstallerDownloads = $installerCount }
}
