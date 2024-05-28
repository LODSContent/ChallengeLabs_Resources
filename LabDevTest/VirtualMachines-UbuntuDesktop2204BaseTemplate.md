## Virtual Machines:

<br>
#### LAMP VM

- Configuration:

    | Item | Detail |
    |:---------|:---------|
    | User | +++@lab.VirtualMachine(ubuntudesktop22.04).Username+++ |
    | Password | +++@lab.VirtualMachine(ubuntudesktop22.04).Password+++ |
    | Name   | labuser-virtual-machine   |
    | Platform | ESX |
    | OS | Ubuntu Desktop v22.04 |
    | IP Address   | DHCP   |
    | CPU(s) | 4 |
    | RAM | 4 GB |
    | HD 1 | 100 GB |
    | NIC(s) | 2 |

- Optimizations:

>[+] The following optimizations are based upon the standards established in the [Basic Lab Developer Training](https://labondemand.com/LabProfile/Instructions/132658?instructionsSetId=227922#lab-optimisation) documentation.
>
- Updated Ubuntu:
>
    ```bash
    set -e
    sudo apt-get update
    sudo apt-get upgrade
    sudo apt-get dist-upgrade
    ```
- Installed Python 3: ++sudo apt install python3-pip++
- Installed VMware Tools: ++sudo apt-get install open-vm-tools-desktop -y++
- Disabled automatic updates:
>
    ```bash
    sudo systemctl disable --now unattended-upgrades
    echo 'APT::Periodic::Update-Package-Lists "0";' | sudo tee /etc/apt/apt.conf.d/20auto-upgrades
    echo 'APT::Periodic::Unattended-Upgrade "0";' | sudo tee -a /etc/apt/apt.conf.d/20auto-upgrades
    ```
- Removed background image and set the background to dark grey:   
>
    ```bash
    gsettings set org.gnome.desktop.background picture-uri none
    gsettings set org.gnome.desktop.background primary-color '#333333'
    ```
- Cleared history: ++history -c++
