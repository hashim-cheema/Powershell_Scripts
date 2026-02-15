#The purpose of this script is to get attributes from VMs such as CPU, Memory, Network, and Disk usage to help determine if any VMs are not being used
#Hashim Cheema - 09/09/2025

$server = ""
$credentials = Get-Credential
$location = Read-Host -Prompt "Enter vCenter Folder"

Write-Host "Server: $server"
Write-Host "Location: $location"

Write-Host "You will be entering two dates to analyze the resource usage of each VM`n" -ForegroundColor Cyan

$start_date = Read-Host "Please enter a valid start date in this format, MM/DD/YYYY"
$end_date = Read-Host "Please enter a valid end date in this format, MM/DD/YYYY"

try {
    $Start = Get-Date $start_date -ErrorAction Stop
    $Finish = Get-Date $end_date -ErrorAction Stop
}
catch {
    Write-Error "There was a problem with the format or the dates you chose, please try again!"
    Exit 1
}

try {
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
    Connect-VIServer -Server $server -Credential $credentials -ErrorAction Stop
}
catch {
    Write-Error "There was an issue connecting to the vCenter Host $server"
    Exit 1
}

Write-Host "Getting a list of VMs powered on" -ForegroundColor Green

$VMs = Get-VM -Location $location | Where-Object {$_.PowerState -eq 'PoweredOn'}

$VMs | Select-Object Name

$continue = Read-Host "Is this list of VMs ok? y/n"

if ($continue -eq 'y') {
    Write-Host "Continuing..." -ForegroundColor Green
}
else {
    Write-Host "Stopping..." -ForegroundColor Green
}

$results = @()

foreach ($vm in $VMs) {

    try {
        $cpu_stat = Get-Stat -Entity $vm -Stat cpu.usage.average -Start $Start -Finish $Finish
        $mem_stat = Get-Stat -Entity $vm -Stat mem.usage.average -Start $Start -Finish $Finish
        $net_stat = Get-Stat -Entity $vm -Stat net.usage.average -Start $Start -Finish $Finish
        $disk_stat = Get-Stat -Entity $vm -Stat disk.usage.average -Start $Start -Finish $Finish
    }
    catch {
        Write-Error "There was an issue getting one of the statistics for the VM $($vm.Name)"
    }

    $cpu_avg = if ($cpu_stat) {
        [math]::Round(($cpu_stat | Measure-Object -Property Value -Average).Average, 2)
    } else { "No CPU Data" }

    $mem_avg = if ($mem_stat) {
        [math]::Round(($mem_stat | Measure-Object -Property Value -Average).Average, 2)
    } else { "No Memory Data" }

    $net_avg = if ($net_stat) {
        [math]::Round(($net_stat | Measure-Object -Property Value -Average).Average, 2)
    } else { "No Network Data" }

    $disk_avg = if ($disk_stat) {
        [math]::Round(($disk_stat | Measure-Object -Property Value -Average).Average, 2)
    } else { "No Disk Data" }

    $results += [PSCustomObject]@{
        VM_Name = $vm.Name
        Power_State = $vm.PowerState
        CPU_Usage_Percent = $cpu_avg
        Memory_Usage_Percent = $mem_avg
        Network_Usage_KBps = $net_avg
        Disk_Usage_KBps = $disk_avg
    }
}

Write-Host "Exporting results to C:\VM Resource Usage.csv" -ForegroundColor Green

$results | Export-Csv -Path "C:\VM Resource Usage.csv" -NoTypeInformation
