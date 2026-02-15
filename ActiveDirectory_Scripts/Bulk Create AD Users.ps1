#Import a list of users and properties about them and bulk creates AD accounts for them
#Completed Powershell Script 9-25-2024

$CSV = (Read-Host "Enter the full path of the CSV file")

$ADUsers = Import-Csv -Path $CSV   #Store CSV Info in Variable

foreach ($User in $ADUsers) {   #goes line by line in the CSV to fill up the properties for the user
    
    $Name = "$($User.Firstname) $($User.Lastname)"
    $GivenName = $User.Firstname
    $Surname = $User.Lastname
    $UserPrincipalName = $User.Email
    $SamAccountName = $User.Username
    $Path = $User.OU
    $Groups = $User.Group
    $AccountPassword = (ConvertTo-SecureString -AsPlainText $User.Password -Force)
    $Description = $User.Description
    $EmailAddress = $User.Email
    $MobilePhone = $User.Telephone
    $Title = $User.Title
    $Department = $User.Department
    $Company = $User.Company
    $Manager = $User.Manager

    #Check if user exists already
    if(Get-ADUser -Filter "SamAccountName -eq '$($User.Username)'") {
        Write-Host "Sorry, the user, '$($User.Username)', already exists in the Active Directory" -ForegroundColor Red
    }

    #If user doesn't exist then it will create the user using the properties above
    else {    
        $Userprops = @{
            
            Enabled = $true
            Name = $Name
            DisplayName = $Name
            GivenName = $GivenName
            Surname = $Surname
            UserPrincipalName = $UserPrincipalName
            SamAccountName = $SamAccountName
            Path = $Path
            AccountPassword = $AccountPassword
            PasswordNeverExpires = $true
            Description = $Description
            EmailAddress = $EmailAddress
            MobilePhone = $MobilePhone
            Title = $Title
            Department = $Department
            Company = $Company
            Manager = $Manager
        }

        New-ADUser @Userprops
        Write-Host "Adding user '$($Name)'..."

        #Another for loop to go through each entry under the Group column 
        foreach ($Group in $Groups.split(',')) {
        #Add Member to Group
            Add-ADGroupMember -Identity $Group -Members $SamAccountName
            Write-Host "Successfully added '$($Name)' to the group '$($Group)'" -ForegroundColor Green
        }

    }
}


