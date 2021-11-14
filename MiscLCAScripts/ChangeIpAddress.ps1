write-host ""
write-host ""
write-host "This script can be used in combination with the lab UI to move the virtual machine from "
write-host "the 192.168.10.0/24 network to the the 172.16.0.0/24 network and vice versa." 
write-host ""
write-host "For the changes to be effective, you must make sure that the IP address for the virtual machine"
write-host "is on the same subnet as the network selected for the virtual machine on the Resources tab of" 
write-host "lab UI."
write-host ""
write-host "Before changing the IP address of the virtual machine, go the Resources tab, select the Win10-CLI1"
write-host "thumbnail, and then select the appropriate network, either the 192.168.10.0/24 or 172.16.0.0/24"
write-host "network from the drop-down."
write-host ""
pause

#declare variables

$ipmsg1 = $null
$ipmsg2 = $null
$ipconfig = Get-NetIPConfiguration
$ip = $ipconfig.Ipv4Address.IPaddress
$pf = $ipconfig.IPv4Address.PrefixLength
$dg = $ipconfig.IPv4DefaultGateway.NextHop
$dns = $ipconfig.DNSServer.ServerAddresses
$ifindex = $ipconfig.InterfaceIndex

# Offer choice

write-host ""
write-host "The current IP address is" -ForegroundColor White -NoNewline; Write-host " $ip/$pf " -ForegroundColor Green
If ($ip -match '192.168.10.21') {
$ipmsg1 = "Do you want to change the IP address to 172.16.0.21/24? [Y/N]?"
}
else {
$ipmsg2 = "Do you want to change the IP address to 192.168.10.21/24 [Y/N]?"
}

If ($ipmsg1 -ne $null){    
    $response = Read-Host -Prompt $ipmsg1
    if ($response -eq 'y'){
        Write-host ""
        Write-host "Changing IP address to 172.16.0.21/24"
        Remove-NetIPAddress -InterfaceIndex $ifindex -Confirm:$false
        New-NetIPAddress -InterfaceIndex $ifindex -IPAddress 172.16.0.21 -PrefixLength $pf -DefaultGateway $dg
        $NewDNS = Set-DnsClientServerAddress -InterfaceIndex $ifindex -ServerAddresses 172.16.0.1
        $ipconfig = Get-NetIPConfiguration
        $ip = $ipconfig.Ipv4Address.IPaddress
        $pf = $ipconfig.IPv4Address.PrefixLength
        $dg = $ipconfig.IPv4DefaultGateway.NextHop
        $dns = $ipconfig.DNSServer.ServerAddresses
        Write-Host "The current IP address is" -ForegroundColor White -NoNewline; Write-Host " $ip/$pf " -ForegroundColor Green
        Write-Host "The default gateway is" -ForegroundColor White -NoNewline; Write-Host " $dg " -ForegroundColor Green 
        Write-Host "The DNS server address is" -ForegroundColor White -NoNewline; Write-Host " $dns " -ForegroundColor Green 
        Write-Host ""
        pause
        }
        else{
            Write-host ""
            Write-host "Leaving IP address unchanged at" -ForegroundColor White -NoNewline; Write-host " $ip/$pf " -ForegroundColor Green
            pause
          }
    }
    else {
    $response = Read-Host -Prompt $ipmsg2
    if ($response -eq 'y'){
        Write-host ""
        Write-host "Changing IP address to 192.168.10.21/24"
        Remove-NetIPAddress -InterfaceIndex $ifindex -Confirm:$false
        New-NetIPAddress -InterfaceIndex $ifindex -IPAddress 192.168.10.21 -PrefixLength $pf -DefaultGateway $dg
        $NewDNS = Set-DnsClientServerAddress -InterfaceIndex $ifindex -ServerAddresses 192.168.10.10
        $ipconfig = Get-NetIPConfiguration
        $ip = $ipconfig.Ipv4Address.IPaddress
        $pf = $ipconfig.IPv4Address.PrefixLength
        $dg = $ipconfig.IPv4DefaultGateway.NextHop
        $dns = $ipconfig.DNSServer.ServerAddresses
        Write-Host "The current IP address is" -ForegroundColor White -NoNewline; Write-Host " $ip/$pf " -ForegroundColor Green
        Write-Host "The default gateway is" -ForegroundColor White -NoNewline; Write-Host " $dg " -ForegroundColor Green 
        Write-Host "The DNS server address is" -ForegroundColor White -NoNewline; Write-Host " $dns " -ForegroundColor Green 
        Write-Host ""
        pause
        }
        else{
            Write-host ""
            Write-host "Leaving IP address unchanged at" -ForegroundColor White -NoNewline; Write-host " $ip/$pf " -ForegroundColor Green
            pause
          }
    }
 
