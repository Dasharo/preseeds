Write-Host "Downloading all Windows updates...";
Install-PackageProvider NuGet -Force;
# Uncomment the following line when the installation was performed without internet connection (PSGallery repository was not installed correctly)
# Register-PSRepository -Default -Verbose
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted;
Install-Module PSWindowsUpdate;
Get-WindowsUpdate -AcceptAll -Install -AutoReboot
