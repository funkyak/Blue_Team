Import-Module Active Directory
$Resetpassword = Import-Csv "C:\path_to_username_password_file.csv"
 #Store CSV file into $Resetpassword variable
 
foreach ($User in $Resetpassword) {
    #For each name or account in the CSV file $Resetpassword, reset the password with the Set-ADAccountPassword string below
    $User.sAMAccountName
    $User.Password
        Set-ADAccountPassword -Identity $User.sAMAccountName -Reset -NewPassword (ConvertTo-SecureString $User.Password -AsPlainText -force)
}
 Write-Host " Passwords changed "
 $total = ($Resetpassword).count
 $total
 Write-Host "Accounts passwords have been reset..."
 
 Get-ADUser -filter * -properties passwordlastset | sort-object samaccountname | select-object samaccountname, passwordlastset, passwordneverexpires | Out-GridView
