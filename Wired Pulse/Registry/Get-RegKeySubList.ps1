<#
SYNOPSIS:
    Queries a specific Registry Key and returns the Sub-Keys of it.

.PARAMETER key
    Used to specify the path to the key to verify.

.PARAMETER HKEY_CLASSES_ROOT
    Used to specify HKCR.

.PARAMETER HKEY_CURRENT_USER
    Used to specify HKCU.

.PARAMETER HKEY_LOCAL_MACHINE
    Used to specify HKLM.

.PARAMETER HKEY_USERS
    Used to specify HKUS.

.PARAMETER HKEY_CURRENT_CONFIG
    Used to specify HKCC.

.EXAMPLE
    PS C:\> Get-RegKeySubList.ps1 -ComputerName c:\users\blue\desktop\computers.txt -HKEY_LOCAL_MACHINE -key System\currentcontrolset\services

    Lists all the keys unders 'Services' on the systems listed in computers.txt

.EXAMPLE
    PS C:\> Get-RegKeySubList.ps1 -ComputerName 172.16.155.201 -HKEY_LOCAL_MACHINE -key System\currentcontrolset\services

    Lists all the keys unders 'Services' on 172.16.155.201

#>


param(
    [Parameter(Mandatory=$true)][string]$Key,
    [switch]$HKEY_CLASSES_ROOT,
    [switch]$HKEY_CURRENT_USER,
    [switch]$HKEY_LOCAL_MACHINE,
    [switch]$HKEY_USERS,
    [switch]$HKEY_CURRENT_CONFIG
    )


if($HKEY_CLASSES_ROOT)
    {
    $HKCR = [uint32]'0x80000000' #HKEY_CLASSES_ROOT
    $hive = $HKCR
    }

if($HKEY_CURRENT_USER)
    {
    $HKCU = [uint32]'0x80000001' #HKEY_CURRENT_USER
    $hive = $HKCU
    }

if($HKEY_LOCAL_MACHINE)
    {
    $HKLM = [uint32]'0x80000002' #HKEY_LOCAL_MACHINE
    $hive = $HKLM
    }

if($HKEY_USERS)
    {
    $HKUS = [uint32]'0x80000003' #HKEY_USERS
    $hive = $HKUS
    }

if($HKEY_CURRENT_CONFIG)
    {
    $HKCC = [uint32]'0x80000005' #HKEY_CURRENT_CONFIG
    $hive = $HKCC
    }


$newline = "`r`n"
$current_user = [Environment]::UserName

# ==============================================================================
# Function Name 'ListComputers' - Takes entered domain and lists all computers
# ==============================================================================
Function ListComputers
{
    $DN = ""
    $Response = ""
    $DNSName = ""
    $DNSArray = ""
    $objSearcher = ""
    $colProplist = ""
    $objComputer = ""
    $objResults = ""
    $colResults = ""
    $Computer = ""
    $comp = ""
    New-Item -type file -force "$Script:Folder_Path\Computer_List_$Script:curDate.txt" | Out-Null
    $Script:Compute = "$Script:Folder_Path\Computer_List_$Script:curDate.txt"
    $strCategory = "(ObjectCategory=Computer)"
    
    Write-Host "Would you like to automatically pull from your domain or provide your own domain?"
    Write-Host "Auto pull uses the current domain you are on, if you need to select a different domain use manual."
    $response = Read-Host = "[1] Auto Pull, [2] Manual Selection"
    
    If($Response -eq "1") {
        $DNSName = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain().Name
        If($DNSName -ne $Null) {
            $DNSArray = $DNSName.Split(".") 
            for ($x = 0; $x -lt $DNSArray.Length ; $x++) {  
                if ($x -eq ($DNSArray.Length - 1)){$Separator = ""}else{$Separator =","} 
                [string]$DN += "DC=" + $DNSArray[$x] + $Separator  } }
        $Script:Domain = $DN
        echo "Pulled computers from: "$Script:Domain
        $objSearcher = New-Object System.DirectoryServices.DirectorySearcher("LDAP://$Script:Domain")
        $objSearcher.Filter = $strCategory
        $objSearcher.PageSize = 100000
        $objSearcher.SearchScope = "SubTree"
        $colProplist = "name"
        foreach ($i in $colPropList) {
            $objSearcher.propertiesToLoad.Add($i) }
        $colResults = $objSearcher.FindAll()
        foreach ($objResult in $colResults) {
            $objComputer = $objResult.Properties
            $comp = $objComputer.name
            echo $comp | Out-File $Script:Compute -Append }
        $Script:Computers = (Get-Content $Script:Compute) | Sort-Object
    }
	elseif($Response -eq "2")
    {
        Write-Host "Would you like to automatically pull from your domain or provide your own domain?"
        Write-Host "Auto pull uses the current domain you are on, if you need to select a different domain use manual."
        $Script:Domain = Read-Host "Enter your Domain here: OU=West,DC=Company,DC=com"
        If ($Script:Domain -eq $Null) {Write-Host "You did not provide a valid response."; . ListComputers}
        
        echo "Pulled computers from: "$Script:Domain
        $objOU = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$Script:Domain")
        $objSearcher = New-Object System.DirectoryServices.DirectorySearcher
        $objSearcher.SearchRoot = $objOU
        $objSearcher.Filter = $strCategory
        $objSearcher.PageSize = 100000
        $objSearcher.SearchScope = "SubTree"
        $colProplist = "name"
        foreach ($i in $colPropList) { $objSearcher.propertiesToLoad.Add($i) }
        $colResults = $objSearcher.FindAll()
        foreach ($objResult in $colResults) {
            $objComputer = $objResult.Properties
            $comp = $objComputer.name
            echo $comp | Out-File $Script:Compute -Append }
        $Script:Computers = (Get-Content $Script:Compute) | Sort-Object
    }
    else {
        Write-Host "You did not supply a correct response, Please select a response." -foregroundColor Red
        . ListComputers }
}

# ==============================================================================
# Function Name 'ListTextFile' - Enumerates Computer Names in a text file
# Create a text file and enter the names of each computer. One computer
# name per line. Supply the path to the text file when prompted.
# ==============================================================================
Function ListTextFile 
{
	$file_Dialog = ""
    $file_Name = ""
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $file_Dialog = New-Object system.windows.forms.openfiledialog
    $file_Dialog.InitialDirectory = "$env:USERPROFILE\Desktop"
    $file_Dialog.MultiSelect = $false
    $file_Dialog.showdialog()
    $file_Name = $file_Dialog.filename
    $Comps = Get-Content $file_Name
    If ($Comps -eq $Null) {
        Write-Host "Your file was empty. You must select a file with at least one computer in it." -Fore Red
        . ListTextFile }
    Else
    {
        $Script:Computers = @()
        ForEach ($Comp in $Comps)
        {
            If ($Comp -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d{1,2}")
            {
                $Temp = $Comp.Split("/")
                $IP = $Temp[0]
                $Mask = $Temp[1]
                . Get-Subnet-Range $IP $Mask
                $Script:Computers += $Script:IPList
            }
            Else
            {
                $Script:Computers += $Comp
            }
        }

        
    }
}

Function Get-Subnet-Range {
    #.Synopsis
    # Lists all IPs in a subnet.
    #.Example
    # Get-Subnet-Range -IP 192.168.1.0 -Netmask /24
    #.Example
    # Get-Subnet-Range -IP 192.168.1.128 -Netmask 255.255.255.128        
    Param(
        [string]
        $IP,
        [string]
        $netmask
    )  
    Begin {
        $IPs = New-Object System.Collections.ArrayList

        Function Get-NetworkAddress {
            #.Synopsis
            # Get the network address of a given lan segment
            #.Example
            # Get-NetworkAddress -IP 192.168.1.36 -mask 255.255.255.0
            Param (
                [string]
                $IP,
               
                [string]
                $Mask,
               
                [switch]
                $Binary
            )
            Begin {
                $NetAdd = $null
            }
            Process {
                $BinaryIP = ConvertTo-BinaryIP $IP
                $BinaryMask = ConvertTo-BinaryIP $Mask
                0..34 | %{
                    $IPBit = $BinaryIP.Substring($_,1)
                    $MaskBit = $BinaryMask.Substring($_,1)
                    IF ($IPBit -eq '1' -and $MaskBit -eq '1') {
                        $NetAdd = $NetAdd + "1"
                    } elseif ($IPBit -eq ".") {
                        $NetAdd = $NetAdd +'.'
                    } else {
                        $NetAdd = $NetAdd + "0"
                    }
                }
                if ($Binary) {
                    return $NetAdd
                } else {
                    return ConvertFrom-BinaryIP $NetAdd
                }
            }
        }
       
        Function ConvertTo-BinaryIP {
            #.Synopsis
            # Convert an IP address to binary
            #.Example
            # ConvertTo-BinaryIP -IP 192.168.1.1
            Param (
                [string]
                $IP
            )
            Process {
                $out = @()
                Foreach ($octet in $IP.split('.')) {
                    $strout = $null
                    0..7|% {
                        IF (($octet - [math]::pow(2,(7-$_)))-ge 0) {
                            $octet = $octet - [math]::pow(2,(7-$_))
                            [string]$strout = $strout + "1"
                        } else {
                            [string]$strout = $strout + "0"
                        }  
                    }
                    $out += $strout
                }
                return [string]::join('.',$out)
            }
        }
 
 
        Function ConvertFrom-BinaryIP {
            #.Synopsis
            # Convert from Binary to an IP address
            #.Example
            # Convertfrom-BinaryIP -IP 11000000.10101000.00000001.00000001
            Param (
                [string]
                $IP
            )
            Process {
                $out = @()
                Foreach ($octet in $IP.split('.')) {
                    $strout = 0
                    0..7|% {
                        $bit = $octet.Substring(($_),1)
                        IF ($bit -eq 1) {
                            $strout = $strout + [math]::pow(2,(7-$_))
                        }
                    }
                    $out += $strout
                }
                return [string]::join('.',$out)
            }
        }

        Function ConvertTo-MaskLength {
            #.Synopsis
            # Convert from a netmask to the masklength
            #.Example
            # ConvertTo-MaskLength -Mask 255.255.255.0
            Param (
                [string]
                $mask
            )
            Process {
                $out = 0
                Foreach ($octet in $Mask.split('.')) {
                    $strout = 0
                    0..7|% {
                        IF (($octet - [math]::pow(2,(7-$_)))-ge 0) {
                            $octet = $octet - [math]::pow(2,(7-$_))
                            $out++
                        }
                    }
                }
                return $out
            }
        }
 
        Function ConvertFrom-MaskLength {
            #.Synopsis
            # Convert from masklength to a netmask
            #.Example
            # ConvertFrom-MaskLength -Mask /24
            #.Example
            # ConvertFrom-MaskLength -Mask 24
            Param (
                [int]
                $mask
            )
            Process {
                $out = @()
                [int]$wholeOctet = ($mask - ($mask % 8))/8
                if ($wholeOctet -gt 0) {
                    1..$($wholeOctet) |%{
                        $out += "255"
                    }
                }
                $subnet = ($mask - ($wholeOctet * 8))
                if ($subnet -gt 0) {
                    $octet = 0
                    0..($subnet - 1) | %{
                         $octet = $octet + [math]::pow(2,(7-$_))
                    }
                    $out += $octet
                }
                for ($i=$out.count;$i -lt 4; $I++) {
                    $out += 0
                }
                return [string]::join('.',$out)
            }
        }

        Function Get-IPRange {
            #.Synopsis
            # Given an Ip and subnet, return every IP in that lan segment
            #.Example
            # Get-IPRange -IP 192.168.1.36 -Mask 255.255.255.0
            #.Example
            # Get-IPRange -IP 192.168.5.55 -Mask /23
            Param (
                [string]
                $IP,
               
                [string]
                $netmask
            )
            Process {
                iF ($netMask.length -le 3) {
                    $masklength = $netmask.replace('/','')
                    $Subnet = ConvertFrom-MaskLength $masklength
                } else {
                    $Subnet = $netmask
                    $masklength = ConvertTo-MaskLength -Mask $netmask
                }
                $network = Get-NetworkAddress -IP $IP -Mask $Subnet
               
                [int]$FirstOctet,[int]$SecondOctet,[int]$ThirdOctet,[int]$FourthOctet = $network.split('.')
                $TotalIPs = ([math]::pow(2,(32-$masklength)) -2)
                $blocks = ($TotalIPs - ($TotalIPs % 256))/256
                if ($Blocks -gt 0) {
                    1..$blocks | %{
                        0..255 |%{
                            if ($FourthOctet -eq 255) {
                                If ($ThirdOctet -eq 255) {
                                    If ($SecondOctet -eq 255) {
                                        $FirstOctet++
                                        $secondOctet = 0
                                    } else {
                                        $SecondOctet++
                                        $ThirdOctet = 0
                                    }
                                } else {
                                    $FourthOctet = 0
                                    $ThirdOctet++
                                }  
                            } else {
                                $FourthOctet++
                            }
                            Write-Output ("{0}.{1}.{2}.{3}" -f `
                            $FirstOctet,$SecondOctet,$ThirdOctet,$FourthOctet)
                        }
                    }
                }
                $sBlock = $TotalIPs - ($blocks * 256)
                if ($sBlock -gt 0) {
                    1..$SBlock | %{
                        if ($FourthOctet -eq 255) {
                            If ($ThirdOctet -eq 255) {
                                If ($SecondOctet -eq 255) {
                                    $FirstOctet++
                                    $secondOctet = 0
                                } else {
                                    $SecondOctet++
                                    $ThirdOctet = 0
                                }
                            } else {
                                $FourthOctet = 0
                                $ThirdOctet++
                            }  
                        } else {
                            $FourthOctet++
                        }
                        Write-Output ("{0}.{1}.{2}.{3}" -f `
                        $FirstOctet,$SecondOctet,$ThirdOctet,$FourthOctet)
                    }
                }
            }
        }
    }
    Process {
        #get every ip in scope
        Get-IPRange $IP $netmask | %{
        [void]$IPs.Add($_)
        }
        $Script:IPList = $IPs
    }
}

# ==============================================================================
# Function Name 'SingleEntry' - Enumerates Computer from user input
# ==============================================================================
Function SingleEntry 
{
    $Comp = Read-Host "Enter Computer Name or IP (1.1.1.1) or IP Subnet (1.1.1.1/24)"
    If ($Comp -eq $Null) { . SingleEntry } 
    ElseIf ($Comp -match "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/\d{1,2}")
    {
        $Temp = $Comp.Split("/")
        $IP = $Temp[0]
        $Mask = $Temp[1]
        . Get-Subnet-Range $IP $Mask
        $Script:Computers = $Script:IPList
    }
    Else
    { $Script:Computers = $Comp}
}

# ==============================================================================
# Menu
# ==============================================================================

Write-Host "How do you want to list computers?"	-ForegroundColor yellow
$strResponse = Read-Host "`n[1] All Domain Computers (Must provide Domain), `n[2] Computer names from a File, `n[3] List a Single Computer manually `n"
If($strResponse -eq "1"){. ListComputers | Sort-Object}
	elseif($strResponse -eq "2"){. ListTextFile}
	elseif($strResponse -eq "3"){. SingleEntry}
	else{Write-Host "You did not supply a correct response, `
	Please run script again."; pause -foregroundColor Red}	

# ==============================================================================
# Loops through and gets the Key data along with linking it back to a System/IP
# ==============================================================================
foreach($cpu in $computers){
$reg = Get-WmiObject -list -Namespace root\default |Where-Object {$_.name -eq "stdregprov"}
$subkeys = $reg.EnumKey($hive, $key) 
$names= $subkeys.snames
foreach($name in $names){
$new_table += $cpu + ' ' + $name + $newline
}}

# ==============================================================================
# Writes data to a file
# ==============================================================================
add-content -Path "c:\users\$current_user\desktop\Reg.txt" -Value ($new_table)

# ==============================================================================
# Splits data into two columns and exports it as a csv
# ==============================================================================
import-csv "c:\users\$current_user\desktop\Reg.txt" -Delimiter ' ' -Header 'System', 'Key' |export-csv c:\users\$current_user\desktop\Registry_Keys.csv

# ==============================================================================
# Cleanup
# ==============================================================================
pause
remove-item "c:\users\$current_user\desktop\Reg.txt"
Remove-Variable new_table -ErrorAction SilentlyContinue
