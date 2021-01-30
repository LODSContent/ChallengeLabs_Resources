# Configure firewall rule
netsh advfirewall firewall add rule name="http" dir=in action=allow protocol=TCP localport=80

# Install IIS feature
Install-WindowsFeature Web-Server -IncludeManagementTools

# Copy new index.html file
Invoke-WebRequest 'https://raw.githubusercontent.com/grabinski/ais-009/master/index.html' -OutFile 'C:\inetpub\wwwroot\index.html'
