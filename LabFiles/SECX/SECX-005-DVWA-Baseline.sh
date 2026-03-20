#!/bin/bash
# Title: Lab05 LCA - Create insecure DVWA exposure baseline
# Description: Stages an intentionally exposed Apache/DVWA baseline for Lab 05.
# Target: DVWA
# Version: 2026.03.10 - LCA

set -euo pipefail

# Create an exposed directory with no index file
mkdir -p /var/www/html/exposed
echo "Sample backup content" > /var/www/html/exposed/readme.txt

# Create insecure baseline Apache configuration
cat > /etc/apache2/conf-available/dvwa-exposure.conf <<'EOF'
ServerTokens Full
ServerSignature On

<Directory /var/www/html/exposed>
    Options +Indexes
    Require all granted
</Directory>

<Location "/dvwa/setup.php">
    Require all granted
</Location>
EOF

# Enable the configuration
if [ ! -e /etc/apache2/conf-enabled/dvwa-exposure.conf ]; then
    a2enconf dvwa-exposure
fi

# Reload Apache with syntax check
systemctl reload apache2

# Clear prior student artifacts
rm -f /root/dvwa-*.txt
rm -f /home/*/dvwa-*.txt 2>/dev/null || true

# Truncate logs so students see fresh evidence
: > /var/log/apache2/access.log
: > /var/log/apache2/error.log

echo "Lab05 insecure baseline configured."
