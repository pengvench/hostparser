<# :
@echo off
chcp 65001 >nul
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ([System.IO.File]::ReadAllText('%~f0'))"
pause
exit /b
#>

# --- POWERSHELL CODE START ---

$currentDir = $PSScriptRoot
if (!$currentDir) { $currentDir = Split-Path $MyInvocation.MyCommand.Path -Parent }
if (!$currentDir) { $currentDir = Get-Location }

$dnsPool = @{
    'Astra_1'    = '108.165.164.201'
    'Astra_2'    = '108.165.164.224'
    'Xbox_Main'  = '176.99.11.77'
    'Xbox_Alt'   = '80.78.247.254'
    'GeoHide_1'  = '194.190.11.1'
    'GeoHide_2'  = '45.155.204.190'
    'Serverel'   = '103.27.157.38'
}

$inputFile = Join-Path $currentDir 'domainlist.txt'

if (-not (Test-Path $inputFile)) {
    Write-Host "ERROR: domainlist.txt not found in $currentDir" -ForegroundColor Red
    return
}

$lines = Get-Content $inputFile

foreach ($dnsName in $dnsPool.Keys) {
    $server = $dnsPool[$dnsName]
    $outputFile = Join-Path $currentDir "hosts_$($dnsName).txt"
    $results = New-Object System.Collections.Generic.List[string]
    
    Write-Host "`n>>> PROCESSING DNS: $dnsName ($server) <<<" -ForegroundColor Cyan

    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        
        if ($trimmed.StartsWith("#") -or -not $trimmed) {
            $results.Add($trimmed)
            continue
        }

        # Domain cleaning
        $domain = $trimmed -replace '^https?://', '' -replace '/.*$', ''
        if ($domain -match "/") { $domain = $domain.Split("/")[0] }

        try {
            $query = nslookup $domain $server 2>$null
            $ipMatch = $query | Select-String -Pattern "\d{1,3}(\.\d{1,3}){3}" | Select-Object -Last 1
            
            if ($ipMatch) {
                $rawIp = $ipMatch.ToString().Split()[-1]
                if ($rawIp -ne $server -and $rawIp -ne "127.0.0.1") {
                    $results.Add("$($rawIp.PadRight(15)) $domain")
                    Write-Host "[$dnsName] OK: $domain" -ForegroundColor Gray
                }
            }
        } catch {}
    }

    $results | Out-File $outputFile -Encoding utf8
    Write-Host "SUCCESS: hosts_$($dnsName).txt" -ForegroundColor Green
}

Write-Host "`n--- ALL DONE! ---" -ForegroundColor Yellow