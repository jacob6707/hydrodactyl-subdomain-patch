param(
    [string]$SourceRepository = 'https://github.com/BlueprintFramework/hydrodactyl.git',
    [string]$SourceBranch = 'main',
    [string]$PatchFile = 'hydrodactyl-subdomain.patch',
    [string]$Image = 'ghcr.io/jacob6707/hydrodactyl',
    [string]$Version = 'canary-patch'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'git is required.'
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw 'Docker is required.'
}

if (-not $env:GHCR_TOKEN) {
    throw 'Set GHCR_TOKEN before running this script.'
}

if (-not $env:GHCR_USER) {
    throw 'Set GHCR_USER before running this script.'
}

$patchPath = Join-Path $PSScriptRoot $PatchFile
$workDirectory = Join-Path $env:TEMP "hydrodactyl-build-$([guid]::NewGuid())"

try {
    New-Item -ItemType Directory -Path $workDirectory | Out-Null

    Write-Host "Cloning $SourceRepository..."
    git clone --depth 1 --branch $SourceBranch $SourceRepository $workDirectory

    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to clone the source repository.'
    }

    Write-Host 'Checking patch applicability...'
    git -C $workDirectory apply --check $patchPath

    if ($LASTEXITCODE -ne 0) {
        throw 'The patch does not apply cleanly to the selected source branch.'
    }

    Write-Host 'Applying patch...'
    git -C $workDirectory apply $patchPath

    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to apply the patch.'
    }

    Write-Host 'Logging in to GHCR...'
    $env:GHCR_TOKEN | docker login ghcr.io `
        --username $env:GHCR_USER `
        --password-stdin

    if ($LASTEXITCODE -ne 0) {
        throw 'GHCR login failed.'
    }

    $fullTag = "${Image}:${Version}"

    Write-Host "Building and pushing $fullTag..."
    docker buildx build `
        --platform linux/amd64,linux/arm64 `
        --tag $fullTag `
        --push `
        $workDirectory

    if ($LASTEXITCODE -ne 0) {
        throw 'Docker build or push failed.'
    }

    Write-Host "Successfully pushed $fullTag"
}
finally {
    if (Test-Path $workDirectory) {
        Remove-Item -Recurse -Force $workDirectory
    }
}