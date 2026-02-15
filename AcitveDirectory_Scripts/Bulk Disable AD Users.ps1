#Import-Module ActiveDirectory

#Import from CSV 
$CSV = (Read-Host "Enter the full path of the CSV file")
$ADUsers = Import-Csv -Path $CSV 

foreach ($User in $ADUsers){

    $SamAccountName = $User.Username
    $DistinguishedName = $User.DistinguishedName
    $OU = $User.OU

    if (Get-ADUser -Filter "SamAccountName -eq '$($User.Username)'") {

        Write-Host "The user exists!" -ForegroundColor Green

        Disable-ADAccount $SamAccountName
        Set-ADUser -Identity $SamAccountName -Description "Termination Date 08/21/2024"
        Move-ADObject -Identity $DistinguishedName -TargetPath $OU
    }

    else {

        Write-Host "The user does not exist!" -ForegroundColor Red
    }
}
