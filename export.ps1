# === Config: Export ===
$headers = @{
  "X-Auth-Email" = "<YOUR_CLOUDFLARE_EMAIL>"     # Replace with your Cloudflare account email
  "X-Auth-Key"   = "<YOUR_CLOUDFLARE_API_KEY>"   # Replace with your Cloudflare API key
  "Content-Type" = "application/json"
}

$zoneId = "<YOUR_ZONE_ID>"                       # Replace with your Cloudflare Zone ID

$outputJsonFile   = "$env:USERPROFILE\Desktop\zone_ip_access_rules.json"
$successListFile  = "$env:USERPROFILE\Desktop\export_success_summary.txt"
$failedListFile   = "$env:USERPROFILE\Desktop\export_failed_summary.txt"

# === Fetch Rules with Pagination & Retry ===
$allRules = @()
$successIPs = @()
$failedPages = @()
$page = 1
$perPage = 100
$totalPages = 1
$retryCount = 0

do {
    $url = "https://api.cloudflare.com/client/v4/zones/$zoneId/firewall/access_rules/rules?page=$page&per_page=$perPage"

    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers -Method GET
        Start-Sleep -Milliseconds 300

        if ($response.success -eq $true) {
            $allRules += $response.result
            $successIPs += $response.result.configuration.value
            $totalPages = $response.result_info.total_pages
            $page++
            $retryCount = 0
        } else {
            $failedPages += "Page $page - API Error"
            $page++
        }
    } catch {
        if ($_.Exception.Response.StatusCode.Value__ -eq 429) {
            Write-Host "Rate limit hit. Waiting 60 seconds..."
            Start-Sleep -Seconds 60
            $retryCount++
        } else {
            $failedPages += "Page $page - $($_.Exception.Message)"
            $page++
        }
    }
} while ($page -le $totalPages -and $retryCount -lt 10)

# === Write JSON output ===
if ($allRules.Count -gt 0) {
    $allRules | ConvertTo-Json -Depth 10 | Out-File -Encoding utf8 $outputJsonFile
    Write-Host "Exported $($allRules.Count) rules to JSON: $outputJsonFile"
}

# === Write Success & Fail Summary ===
$successSummary = @()
$successSummary += "Total exported rules: $($allRules.Count)"
$successSummary += ""
$successSummary += $allRules.configuration.value
$successSummary | Out-File -Encoding utf8 $successListFile

$failSummary = @()
$failSummary += "Failed pages: $($failedPages.Count)"
$failSummary += ""
$failSummary += $failedPages
$failSummary | Out-File -Encoding utf8 $failedListFile

Write-Host "`nSuccess list saved to: $successListFile"
Write-Host "Failures list saved to: $failedListFile"
