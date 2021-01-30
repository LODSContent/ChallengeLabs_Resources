# Configure firewall rule
netsh advfirewall firewall add rule name="http" dir=in action=allow protocol=TCP localport=80

# Install IIS feature
Install-WindowsFeature Web-Server -IncludeManagementTools

# Copy new index.html file
Invoke-WebRequest 'https://raw.githubusercontent.com/LODSContent/ChallengeLabs_Resources/master/ais-009/index.html' -OutFile 'C:\inetpub\wwwroot\index.html'
