#Hashim Cheema - 10/01/2025
#Sensitive info was taken out so that I could publish the script here

Start-Transcript -Path "C:\Automation\Outputs\LowDiskSpaceScript.log"



# vCenter and VM details
$vcenterServer = ""
$location = ""

$hosts_path = "C:\Windows\System32\drivers\etc\hosts"

$mappings = @'
# ESXi IP Addresses and Hostnames


'@

# Backup hosts file
Copy-Item -Path $hosts_path -Destination "$hosts_path.bak" -Force

$currentcontent = Get-Content -Path $hosts_path -Raw

if ($currentcontent -notmatch "") {
    # Append mappings to hosts file
    Add-Content -Path $hosts_path -Value $mappings
    Write-Host "Hosts file has been edited!" -ForegroundColor Blue
}

else {
    Write-Host "Hosts file already has the proper entries!" -ForegroundColor Blue
}

#Connect to vCenter
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false     #ignore invalid certificates otherwise it will fail
Connect-VIServer -Server $vcenterServer -User '' -Password ''

$vms = Get-VM -Location $location | Where-Object {$_.PowerState -eq 'PoweredOn' -and ($_.Guest.OSFullName -like "*Windows*" -or $_.GuestId -like "windows*")}

# Script to run inside the VM
$scriptText = @'
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID, @{Name="TotalGB";Expression={[math]::Round($_.Size/1GB, 2)}}, @{Name="FreeGB";Expression={[math]::Round($_.FreeSpace/1GB, 2)}}
'@

$results = @()

foreach ($vm in $vms) {

    if ($vm.ExtensionData.Guest.ToolsRunningStatus -eq 'guestToolsRunning') {

        try {
            $Script_Result = Invoke-VMScript -VM $vm -GuestUser '' -GuestPassword '' -ScriptText $scriptText -ScriptType Powershell -ErrorAction Stop

            $lines = $Script_Result.ScriptOutput -split "`r?`n" | Select-Object -Skip 2     

            foreach ($line in $lines) {
                $parts = $line.Trim() -split '\s+'
                if ($parts.Count -eq 3 -and $parts[0] -ne '--------') {
                    $totalgb = [double]$parts[1]
                    $freegb = [double]$parts[2]

                    if ($totalgb -gt 0) {
                        $percentfree = [math]::Round(($freegb / $totalgb) * 100, 2)

                        if ($percentfree -le 10) {
                            $needsmorespace = "True"
                            $results += [PSCustomObject]@{
                                VMName = $vm.Name
                                VMWare_Tools = "Running"
                                Drive = $parts[0]
                                TotalGB = $parts[1]
                                FreeGB = $parts[2]
                                NeedsMoreSpace = $needsmorespace

                            }
                        }
                    
                    } else {
                        Write-Host "Invalid Storage Size. Total GB returning less than or equal to 0 GB." -ForegroundColor Red
                        Write-Host "Skipping $($vm.name)...." -ForegroundColor Red
                    } 
                }
            }
        } catch {
            Write-Host "Error running script on $($vm.Name): $_" -ForegroundColor Red

        }
    } else {
        Write-Host "Guest Tools is not running or not installed on $($vm.Name)" -ForegroundColor Yellow
        }
}

$results | Export-Csv -Path "C:\Automation\Outputs\Low_Disk_Space_Report.csv" -NoTypeInformation

Stop-Transcript
