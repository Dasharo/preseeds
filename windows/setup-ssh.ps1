Write-Host "Setting up ssh...";
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Get-Service -Name ssh-agent | Set-Service -StartupType Manual
Start-Service ssh-agent
Get-Service -Name ssh-agent | Set-Service -StartupType Automatic
Start-Service sshd
Get-Service -Name sshd | Set-Service -StartupType Automatic
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force
wmic UserAccount set PasswordExpires=False
Powercfg /Change standby-timeout-ac 0
Powercfg /Change standby-timeout-dc 0
