README - Cloudflare IP Access Rule Management Scripts
=====================================================

********WARNING**********
use import.ps1 & export.ps1 for zone only
use exportGLOBALIPS.ps1 & importGLOBALIPS.ps1 for global Cloudflare Account ID
*************************

DESCRIPTION
-----------
These two PowerShell scripts are used to EXPORT and IMPORT IP Access Rules 
(firewall rules) for a specific Cloudflare zone.

You can use them to back up existing rules or replicate them in another account (Zone ID or Account ID).

LANGUAGE & TECHNOLOGY
---------------------
- Scripting Language: PowerShell
- API: Cloudflare v4 REST API
- Authentication: Requires a Cloudflare email + API key
- Output: JSON and TXT log files saved to your Desktop

FILES INCLUDED
--------------
1. Export-Cloudflare-IPRules.ps1
   - Fetches IP access rules from your specified Cloudflare zone.
   - Saves the rules in JSON format.
   - Generates success/failure summary logs.

2. Import-Cloudflare-IPRules.ps1
   - Loads the JSON file exported earlier.
   - Imports IP access rules into the target Cloudflare zone.
   - Logs already imported IPs to avoid duplicates.
   - Creates import success/failure summary files.

HOW TO USE
----------

**1. Exporting IP Rules**
-------------------------
a. Open `Export-Cloudflare-IPRules.ps1` in a code editor.
b. Replace the following placeholder values:
   - <YOUR_CLOUDFLARE_EMAIL>
   - <YOUR_CLOUDFLARE_API_KEY>
   - <YOUR_ZONE_ID>
c. Save the file.
d. Right-click and run the script using PowerShell.
e. Output files will be created on your Desktop:
   - zone_ip_access_rules.json (main data file)
   - export_success_summary.txt
   - export_failed_summary.txt

**2. Importing IP Rules**
-------------------------
a. Open `Import-Cloudflare-IPRules.ps1` in a code editor.
b. Replace these placeholder values:
   - <YOUR_CLOUDFLARE_EMAIL>
   - <YOUR_CLOUDFLARE_API_KEY>
   - <YOUR_ZONE_ID> (target zone for importing)
c. Ensure the `zone_ip_access_rules.json` file exists on your Desktop.
d. Run the script using PowerShell.
e. The script will:
   - Skip already-imported IPs (logged in imported_ips.log)
   - Save new logs:
     - import_success_summary.txt
     - import_failed_summary.txt

IMPORTANT NOTES
---------------
- Avoid exceeding Cloudflare API rate limits. The scripts wait and retry if needed.
- Make sure PowerShell has permission to write to your Desktop.
- Do not share your Cloudflare API credentials.
