# Hydrodactyl subdomain patch

This repository provides a patch for Hydrodactyl's subdomain system. The
original behavior creates DNS `A` records only, so it requires the server to
have a static IP address. This patch also supports hostname-based servers,
such as servers whose public address is managed through DDNS, by creating a
`CNAME` record when the allocation is a hostname instead of an IP address.

## What it changes

- IP-based allocations continue to use `A` records.
- Hostname-based allocations use `CNAME` records.
- The patched Hydrodactyl image is built for `linux/amd64` and `linux/arm64`
  and pushed to GHCR.

## Requirements

- Windows PowerShell
- Git
- Docker Desktop with Buildx support
- A GitHub personal access token with the `write:packages` scope

The script expects these environment variables:

- `GHCR_USER`: your GitHub username
- `GHCR_TOKEN`: your GitHub personal access token for GHCR

The token is read securely from the environment and passed to `docker login`;
do not put it in this repository or in the command line.

## Apply the patch and publish the image

Open PowerShell in this repository and set the GHCR credentials for the
current PowerShell session:

```powershell
$env:GHCR_USER = 'your-github-username'
$env:GHCR_TOKEN = 'your-github-token'
```

Then run the build script:

```powershell
.\apply-hydrodactyl-subdomain.ps1
```

The script clones Hydrodactyl, checks and applies
`hydrodactyl-subdomain.patch`, logs in to GHCR, and builds and pushes:

```text
ghcr.io/jacob6707/hydrodactyl:canary-patch
```

Use the resulting image in your Hydrodactyl deployment. The script removes its
temporary build directory when it finishes.

## Customize the source or image

The source repository, branch, patch path, image name, and version can be
overridden with PowerShell parameters. For example:

```powershell
.\apply-hydrodactyl-subdomain.ps1 `
	-SourceBranch 'main' `
	-Image 'ghcr.io/your-github-username/hydrodactyl' `
	-Version 'canary-patch'
```
