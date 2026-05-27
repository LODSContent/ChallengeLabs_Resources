<#
   Title: Lab14 LCA - SQL01 vulnerable baseline
   Description: Enables mixed authentication, ensures SQL listens on TCP 1433, stages the secxassess login, enables xp_cmdshell, and creates a local sqlcmd shim when sqlcmd is not installed.
   Target: SQL01
   Version: 2026.05.14 - LCA
#>

$ErrorActionPreference = "Stop"

function Get-SqlInstanceInfo {
    $instanceMapPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL"
    $instanceMap = Get-ItemProperty -Path $instanceMapPath -ErrorAction Stop
    $instanceProps = @($instanceMap.PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' })

    if ($instanceProps.Count -eq 0) {
        throw "No SQL Server instance names were found in the registry."
    }

    if ($instanceProps.Name -contains "MSSQLSERVER") {
        $instanceName = "MSSQLSERVER"
    }
    else {
        $instanceName = $instanceProps[0].Name
    }

    $instanceId = $instanceMap.$instanceName
    if ([string]::IsNullOrWhiteSpace($instanceId)) {
        throw "Could not resolve the SQL Server instance ID."
    }

    if ($instanceName -eq "MSSQLSERVER") {
        $serviceName = "MSSQLSERVER"
    }
    else {
        $serviceName = "MSSQL`$$instanceName"
    }

    [pscustomobject]@{
        InstanceName = $instanceName
        InstanceId   = $instanceId
        ServiceName  = $serviceName
    }
}

function Set-RegistryValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        $Value,

        [Parameter(Mandatory = $true)]
        [ValidateSet("String", "DWord")]
        [string]$PropertyType
    )

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $PropertyType -Force | Out-Null
}

function Configure-SqlRegistry {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InstanceId
    )

    $loginModePath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$InstanceId\MSSQLServer"
    Set-RegistryValue -Path $loginModePath -Name "LoginMode" -Value 2 -PropertyType DWord

    $tcpRoot = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\$InstanceId\MSSQLServer\SuperSocketNetLib\Tcp"
    if (-not (Test-Path $tcpRoot)) {
        throw "SQL Server TCP registry path was not found: $tcpRoot"
    }

    Set-RegistryValue -Path $tcpRoot -Name "Enabled" -Value 1 -PropertyType DWord

    Get-ChildItem -Path $tcpRoot -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -like "IP*" } | ForEach-Object {
        Set-RegistryValue -Path $_.PSPath -Name "Enabled" -Value 1 -PropertyType DWord
    }

    $ipAll = Join-Path $tcpRoot "IPAll"
    Set-RegistryValue -Path $ipAll -Name "TcpDynamicPorts" -Value "" -PropertyType String
    Set-RegistryValue -Path $ipAll -Name "TcpPort" -Value "1433" -PropertyType String
}

function Configure-Firewall {
    Get-NetFirewallRule -DisplayName "Allow SECX14 SQL Server from JumpBox Relay TCP 1433" -ErrorAction SilentlyContinue |
        Remove-NetFirewallRule -ErrorAction SilentlyContinue

    $sqlServerRule = @{
        DisplayName   = "Allow SECX14 SQL Server from JumpBox Relay TCP 1433"
        Direction     = "Inbound"
        Action        = "Allow"
        Protocol      = "TCP"
        LocalPort     = "1433"
        RemoteAddress = "192.168.10.99"
        Profile       = @("Domain", "Private", "Public")
    }

    New-NetFirewallRule @sqlServerRule | Out-Null
}

function Restart-SqlService {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName
    )

    $service = Get-Service -Name $ServiceName -ErrorAction Stop
    Set-Service -Name $ServiceName -StartupType Automatic

    if ($service.Status -eq "Running") {
        Restart-Service -Name $ServiceName -Force
    }
    else {
        Start-Service -Name $ServiceName
    }

    (Get-Service -Name $ServiceName).WaitForStatus('Running', '00:00:45')
    Start-Sleep -Seconds 8
}

function Invoke-SqlText {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString,

        [Parameter(Mandatory = $true)]
        [string]$SqlText
    )

    $connection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString
    $connection.Open()

    try {
        $batches = [regex]::Split($SqlText, '(?im)^\s*GO\s*$')

        foreach ($batch in $batches) {
            if ([string]::IsNullOrWhiteSpace($batch)) {
                continue
            }

            $command = $connection.CreateCommand()
            $command.CommandTimeout = 60
            $command.CommandText = $batch
            $command.ExecuteNonQuery() | Out-Null
        }
    }
    finally {
        $connection.Close()
    }
}

function Wait-ForSqlConnection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString
    )

    $deadline = (Get-Date).AddSeconds(90)
    $lastError = $null

    while ((Get-Date) -lt $deadline) {
        try {
            Invoke-SqlText -ConnectionString $ConnectionString -SqlText "SELECT 1;"
            return
        }
        catch {
            $lastError = $_.Exception.Message
            Start-Sleep -Seconds 3
        }
    }

    throw "SQL Server did not accept connections within the expected time. Last error: $lastError"
}

function Install-SqlCmdShim {
    $shimPath = Join-Path $env:SystemRoot "sqlcmd.cmd"
    $shimScript = Join-Path $env:SystemRoot "SECX14SqlCmdShim.ps1"

    $shimScriptContent = @'
$ErrorActionPreference = "Stop"

$server = "localhost"
$user = $null
$password = $null
$query = $null
$inputFile = $null
$integrated = $false

for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = [string]$args[$i]

    switch ($arg.ToLowerInvariant()) {
        "-s" {
            $i++
            if ($i -lt $args.Count) { $server = [string]$args[$i] }
        }
        "-u" {
            $i++
            if ($i -lt $args.Count) { $user = [string]$args[$i] }
        }
        "-p" {
            $i++
            if ($i -lt $args.Count) { $password = [string]$args[$i] }
        }
        "-q" {
            $i++
            if ($i -lt $args.Count) { $query = [string]$args[$i] }
        }
        "-i" {
            $i++
            if ($i -lt $args.Count) { $inputFile = [string]$args[$i] }
        }
        "-e" {
            $integrated = $true
        }
        "-b" {
            # Accepted for compatibility. Errors already cause a nonzero exit.
        }
        default {
            # Ignore unsupported sqlcmd options used outside this lab.
        }
    }
}

if ([string]::IsNullOrWhiteSpace($query) -and -not [string]::IsNullOrWhiteSpace($inputFile)) {
    $query = Get-Content -Path $inputFile -Raw -ErrorAction Stop
}

if ([string]::IsNullOrWhiteSpace($query)) {
    Write-Error "No SQL query was provided. Use -Q or -i."
    exit 1
}

if ($server -match '^(localhost|\.|127\.0\.0\.1)(\\.*)?$') {
    $dataSource = "tcp:127.0.0.1,1433"
}
else {
    $dataSource = $server
}

if ($integrated -or [string]::IsNullOrWhiteSpace($user)) {
    $connectionString = "Data Source=$dataSource;Initial Catalog=master;Integrated Security=SSPI;TrustServerCertificate=True;Encrypt=False;Connection Timeout=15"
}
else {
    $safePassword = $password.Replace("'", "''")
    $connectionString = "Data Source=$dataSource;Initial Catalog=master;User ID=$user;Password=$safePassword;TrustServerCertificate=True;Encrypt=False;Connection Timeout=15"
}

$connection = New-Object System.Data.SqlClient.SqlConnection $connectionString
$connection.Open()

try {
    $batches = [regex]::Split($query, '(?im)^\s*GO\s*$')

    foreach ($batch in $batches) {
        if ([string]::IsNullOrWhiteSpace($batch)) {
            continue
        }

        $command = $connection.CreateCommand()
        $command.CommandTimeout = 60
        $command.CommandText = $batch

        $reader = $command.ExecuteReader()
        try {
            do {
                if ($reader.FieldCount -gt 0) {
                    $headers = @()
                    for ($c = 0; $c -lt $reader.FieldCount; $c++) {
                        $headers += $reader.GetName($c)
                    }

                    if ($headers.Count -gt 0) {
                        Write-Output ($headers -join "`t")
                    }

                    while ($reader.Read()) {
                        $values = @()
                        for ($c = 0; $c -lt $reader.FieldCount; $c++) {
                            if ($reader.IsDBNull($c)) {
                                $values += "NULL"
                            }
                            else {
                                $values += [string]$reader.GetValue($c)
                            }
                        }
                        Write-Output ($values -join "`t")
                    }
                }
            } while ($reader.NextResult())
        }
        finally {
            $reader.Close()
        }
    }
}
finally {
    $connection.Close()
}
'@

    Set-Content -Path $shimScript -Value $shimScriptContent -Encoding UTF8 -Force

    $cmdContent = @"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SystemRoot%\SECX14SqlCmdShim.ps1" %*
"@
    Set-Content -Path $shimPath -Value $cmdContent -Encoding ASCII -Force
}

$instanceInfo = Get-SqlInstanceInfo
Configure-SqlRegistry -InstanceId $instanceInfo.InstanceId
Configure-Firewall
Restart-SqlService -ServiceName $instanceInfo.ServiceName

$integratedConnection = "Data Source=tcp:127.0.0.1,1433;Initial Catalog=master;Integrated Security=SSPI;TrustServerCertificate=True;Encrypt=False;Connection Timeout=15"
Wait-ForSqlConnection -ConnectionString $integratedConnection

$baselineSql = @'
IF NOT EXISTS (SELECT 1 FROM sys.sql_logins WHERE name = N'secxassess')
BEGIN
    CREATE LOGIN [secxassess] WITH PASSWORD = N'Passw0rd!', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;
END
ELSE
BEGIN
    ALTER LOGIN [secxassess] WITH PASSWORD = N'Passw0rd!', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;
    ALTER LOGIN [secxassess] ENABLE;
END

IF NOT EXISTS (
    SELECT 1
    FROM sys.server_role_members rm
    JOIN sys.server_principals r ON rm.role_principal_id = r.principal_id
    JOIN sys.server_principals m ON rm.member_principal_id = m.principal_id
    WHERE r.name = N'sysadmin' AND m.name = N'secxassess'
)
BEGIN
    ALTER SERVER ROLE [sysadmin] ADD MEMBER [secxassess];
END

EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
EXEC sp_configure 'show advanced options', 0;
RECONFIGURE;
'@

Invoke-SqlText -ConnectionString $integratedConnection -SqlText $baselineSql

Install-SqlCmdShim

$sqlAuthConnection = "Data Source=tcp:127.0.0.1,1433;Initial Catalog=master;User ID=secxassess;Password=Passw0rd!;TrustServerCertificate=True;Encrypt=False;Connection Timeout=15"
Wait-ForSqlConnection -ConnectionString $sqlAuthConnection

$validationSql = @'
SELECT CONCAT(name,':',CAST(value_in_use AS int)) AS config_state
FROM sys.configurations
WHERE name IN ('show advanced options','xp_cmdshell')
ORDER BY name;
'@

Invoke-SqlText -ConnectionString $sqlAuthConnection -SqlText $validationSql

Write-Output "Lab14 SQL01 baseline configured."
Write-Output "SQL instance: $($instanceInfo.InstanceName)"
Write-Output "SQL service: $($instanceInfo.ServiceName)"
Write-Output "SQL listener: tcp:127.0.0.1,1433"
Write-Output "sqlcmd shim: C:\Windows\sqlcmd.cmd"
