Install-PackageProvider -Name "nuget" -ForceBootstrap
Install-PackageProvider -Name "chocolatey" -ForceBootstrap
# Install-PackageProvider -Name "AppxGet" -ForceBootstrap

Install-Package GoogleChrome -ProviderName chocolatey
Install-Package googlejapaneseinput -ProviderName chocolatey
# Install-Package Hain -ProviderName chocolatey
# Install-Package global -ProviderName chocolatey
