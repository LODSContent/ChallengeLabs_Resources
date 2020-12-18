# Configure firewall rule
netsh advfirewall firewall add rule name="http" dir=in action=allow protocol=TCP localport=80

# Install IIS feature
Install-WindowsFeature Web-Server

# Create index.html file
Set-Content -Path "C:\inetpub\wwwroot\index.html" -Value "Web app instance: $($env:computername)"
