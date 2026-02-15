$userprops = @{

    Enabled = $true
    Name = "Hashim Cheema"
    DisplayName = "Hashim Cheema"
    GivenName = "Hashim"
    Surname = "Cheema"
    UserPrincipalName = "hashim.cheema@xmen.com"
    SamAccountName = 'hashim.cheema'

    AccountPassword = (ConvertTo-SecureString -AsPlainText "TheeeeeDream_242323!!!" -Force)
    PasswordNeverExpires = $true 

    Description = "Test"
    EmailAddress = "hashim.cheema@xmen.com"
    MobilePhone = "111-222-3333"

    Title = "HelpDesk Technician"
    Department = "Students"
    Company = "X-Men"
    Manager = "hcheema"

}

New-ADUser @userprops
