Write-Host "Downloading all Windows updates...";
Install-PackageProvider NuGet -Force;
Register-PSRepository -Default -Verbose
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted;
Install-Module PSWindowsUpdate;
Get-WindowsUpdate -AcceptAll -Install -AutoReboot
