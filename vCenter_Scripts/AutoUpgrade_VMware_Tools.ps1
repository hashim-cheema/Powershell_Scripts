#The purpose of this script is to set every VM under the location you choose to auto upgrade its VMware Tools on reboot.
#Hashim Cheema - 09/05/2025

# Set variables
$server = ""
$location = Read-Host -Prompt "Enter vCenter Folder"
$credentials = Get-Credential

Write-Host "Server Name: $server"
Write-Host "Location: $location"


try {
    # Connect to vCenter and ignore invalid certificates
    Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
    Connect-VIServer -Server $server -Credential $credentials -ErrorAction Stop
}
catch {
    Write-Error -Message "Unable to connect to vCenter Host"
    Exit 1
}

Write-Host "Successfully connected to vCenter Server" -ForegroundColor Green

# Get all VMs in the specified location
$VMs = Get-VM -Location $location

$VMs | Select-Object Name

$continue = Read-Host "Are you ok with this list? y/n" -ErrorAction Stop

if ($continue -eq "y") {
    Write-Host "Continuing..." -ForegroundColor Blue
}
else {
    Write-Host "Stopping..." -ForegroundColor Red
    Exit 1
}

try {

    # Loop through each VM and configure auto-upgrade policy

    foreach ($vm in $VMs) {
    $view = Get-View -Id $vm.Id -ErrorAction Stop

    if ($view.Config.Tools.ToolsUpgradePolicy -ne "UpgradeAtPowerCycle") {
        $spec = New-Object VMware.Vim.VirtualMachineConfigSpec
        $spec.Tools = New-Object VMware.Vim.ToolsConfigInfo
        $spec.Tools.ToolsUpgradePolicy = "UpgradeAtPowerCycle"

        $view.ReconfigVM_Task($spec)

        Write-Host "Set $($vm.Name) to auto-upgrade VMware Tools on reboot." -ForegroundColor Green
    } 
    else {
        Write-Host "$($vm.Name) already set to auto-upgrade VMware Tools on reboot." -ForegroundColor Cyan
    }

    }
}
catch {
    Write-Error "There was an error getting info from VM" 
    Exit 1
}

try {
    #Export results to a csv
    $VMs | Select-Object Name, PowerState,
    @{Name='UpgradePolicy';Expression={$_.ExtensionData.Config.Tools.ToolsUpgradePolicy}} |
    Export-Csv -Path "C:\upgradetoolsonreset.csv" -NoTypeInformation -ErrorAction Stop
}
catch {
    Write-Error "Unable to add/edit the spreadsheet in your C Drive...please run as admin"
    Exit 1
}

Write-Host "Spreadsheet has been updated in C:\upgradetoolsonreset.csv!!!" -ForegroundColor Green  
