Import-Module Activedirectory

$users = Get-Content "c:\Users\john.smith\deleteaccounts.txt"



ForEach ($user in $users)

{

Start-Sleep -s "1"

Remove-ADUser -Identity $remove -Confirm:$false

Write-host $user "Deleted"

}
