Get-ADUser -Filter {Enabled -eq $True} -Properties * | Sort-object -casesensitive | Select-Object Name, UserPrincipalName, MobilePhone, Title | Export-csv ""   

#export all enabled users with specific info about them into a csv
