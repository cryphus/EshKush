$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)
docker compose -f compose.demo.yml up --build -d --wait
if ($LASTEXITCODE -ne 0) { throw 'Demo did not start. Run: docker compose -f compose.demo.yml logs' }
Start-Process 'http://127.0.0.1:8080/demo' -WindowStyle Hidden
