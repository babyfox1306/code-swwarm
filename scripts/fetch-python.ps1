# Download embeddable CPython for CODE SWARM (Windows x64)
# Usage: powershell -ExecutionPolicy Bypass -File scripts/fetch-python.ps1

$ErrorActionPreference = "Stop"
$Version = "3.11.9"
$Url = "https://www.python.org/ftp/python/$Version/python-$Version-embed-amd64.zip"
$Dest = Join-Path $PSScriptRoot "..\vendor\python"
$Zip = Join-Path $env:TEMP "python-embed.zip"

Write-Host "Fetching Python $Version embeddable..."
New-Item -ItemType Directory -Force -Path $Dest | Out-Null
Invoke-WebRequest -Uri $Url -OutFile $Zip
Expand-Archive -Path $Zip -DestinationPath $Dest -Force
Remove-Item $Zip

# Enable site-packages / local imports
$Pth = Join-Path $Dest "python311._pth"
if (Test-Path $Pth) {
    (Get-Content $Pth) -replace '#import site', 'import site' | Set-Content $Pth
}

Write-Host "Done. Python at: $Dest\python.exe"
