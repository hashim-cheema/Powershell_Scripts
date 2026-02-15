#Purpose - Gathers a list of all snapshots in vCenter and exports them into a csv
#Author - Hashim Cheema
#Date - 01/20/2026

Write-Host "Checking if connected to VPN" -ForegroundColor Yellow

$network_adapter = Get-NetAdapter | Where-Object {$_.Status -eq "Up" -and $_.InterfaceDescription -like "*Cisco AnyConnect*"}

if ($null -eq $network_adapter) {
    Write-Host "You are not connected to the Cisco VPN. Please try again with the VPN on." -ForegroundColor Red
    exit 1
}
else {
    Write-Host "Connected to the VPN" -ForegroundColor Green
}

Write-Host "Input your vCenter credentials when prompted" -ForegroundColor Yellow

#Connect to vCenter

$vcenter_server = ""
$credentials = Get-Credential

try {
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false  
    Connect-VIServer -Server $vcenter_server -Credential $credentials -ErrorAction Stop
}
catch {
    Write-Host $_.ErrorDetails
    exit 1
}

$scope = Read-Host "Do you want all snapshots from vCenter? y/n"



if ($scope -eq 'y') {

    Write-Host "Getting all snapshots..." -ForegroundColor Green
    $snapshots = Get-VM | Get-Snapshot | Select-Object -Property VM, Name, @{Name="SizeGB";Expression={[Math]::Round($_.SizeGB, 2)}}, Created, PowerState, Description
}
elseif ($scope -eq 'n') {

    #Get which folder you want snapshots from

    $location = Read-Host "Which folder do you want snapshots from?"

    Write-Host "Getting snapshots from $location" -ForegroundColor Yellow

    #Get the snapshots

    $snapshots = Get-VM -Location $location | Get-Snapshot | Select-Object -Property VM, Name, SizeGB, Created, PowerState, Description

}
else {

    Write-Host "Unexpected answer, exiting..." -ForegroundColor Grey
}




#Export to csv

Write-Host "Creating csv in the script's directory" -ForegroundColor Green

$current_path = $PSScriptRoot
$snapshots | Export-Csv -Path "$current_path\snapshots.csv"

Write-Host "Done!" -ForegroundColor Green
