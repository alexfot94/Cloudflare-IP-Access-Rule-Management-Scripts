# === Config: Import Global IP Access Rules ===
$headers = @{
  "X-Auth-Email" = "<YOUR_CLOUDFLARE_EMAIL>"     # Replace with your Cloudflare account email
  "X-Auth-Key"   = "<YOUR_CLOUDFLARE_API_KEY>"   # Replace with your Cloudflare Global API key
  "Content-Type" = "application/json"
}

$accountId         = "<YOUR_ACCOUNT_ID>"         # Replace with your Cloudflare Account ID
$jsonFile          = "$env:USERPROFILE\Desktop\account_ip_access_rules.json"
$logFile           = "$env:USERPROFILE\Desktop\imported_ips.log"
$successListFile   = "$env:USERPROFILE\Desktop\import_success_summary.txt"
$failListFile      = "$env:USERPROFILE\Desktop\import_failed_summary.txt"

# === Load previous success log ===
$importedIPs = @()
if (Test-Path $logFile) {
    $importedIPs = Get-Content $logFile
}

# === Load rules to import ===
if (-Not (Test-Path $jsonFile)) {
    Write-Host "File not found: $jsonFile"
    return
}

$rules = Get-Content -Raw -Path $jsonFile | ConvertFrom-Json
$successfullyImported = @()
$failedImports = @()

# === Import loop ===
foreach ($rule in $rules) {
    $ip = $rule.configuration.value

    if ($importedIPs -contains $ip) {
        Write-Host "Skipped (already imported): $ip"
        continue
    }

    $payload = @{
        mode = $rule.mode
        configuration = @{
            target = $rule.configuration.target
            value  = $ip
        }
        notes = $rule.notes
    }

    $body = $payload | ConvertTo-Json -Depth 10 -Compress
    $url  = "https://api.cloudflare.com/client/v4/accounts/$accountId/firewall/access_rules/rules"

    $success = $false
    $retryCount = 0

    while (-not $success -and $retryCount -lt 10) {
        try {
            $response = Invoke-RestMethod -Uri $url -Method POST -Headers $headers -Body $body
            Start-Sleep -Milliseconds 300

            if ($response.success -eq $true) {
                $ip | Out-File -FilePath $logFile -Append
                $successfullyImported += $ip
                Write-Host "Imported: $ip [$($rule.mode)]"
                $success = $true
            } else {
                $failedImports += "$ip - API Error"
                break
            }
        } catch {
            if ($_.Exception.Response.StatusCode.Value__ -eq 429) {
                Write-Host "Rate limit hit. Waiting 60 seconds..."
                Start-Sleep -Seconds 60
                $retryCount++
            } else {
                $failedImports += "$ip - $($_.Exception.Message)"
                break
            }
        }
    }
}

# === Write Success Summary ===
$summary = @()
$summary += "Total successfully imported IPs: $($successfullyImported.Count)"
$summary += ""
$summary += $successfullyImported
$summary | Out-File -Encoding utf8 $successListFile
Write-Host "`nSuccess list saved to: $successListFile"

# === Write Failed Summary ===
$fails = @()
$fails += "Total failed IPs: $($failedImports.Count)"
$fails += ""
$fails += $failedImports
$fails | Out-File -Encoding utf8 $failListFile
Write-Host "Failed list saved to: $failListFile"
