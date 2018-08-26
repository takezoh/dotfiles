Install-PackageProvider -Name "nuget" -ForceBootstrap
Install-PackageProvider -Name "chocolatey" -ForceBootstrap
# Install-PackageProvider -Name "AppxGet" -ForceBootstrap

Install-Package GoogleChrome -ProviderName chocolatey
Install-Package wsltty -ProviderName chocolatey
Install-Package vcxsrv -ProviderName chocolatey
Install-Package autohotkey -ProviderName chocolatey
Install-Package vscode -ProviderName chocolatey
Install-Package googlejapaneseinput -ProviderName chocolatey
# Install-Package Hain -ProviderName chocolatey
# Install-Package global -ProviderName chocolatey
