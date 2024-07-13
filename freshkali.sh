#!/bin/bash

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to check if the script is run as root
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}\n\nThis script must be run as root.\n\n${NC}"
        exit 1
    fi
}

# Check for root privileges
check_root

echo -e "${BLUE}\nMOST of this script is automated.."
echo -e "The only time you might have to interact is during kali "update / upgrade""
echo -e "Once that completes it should be hands free"
echo -e "Depending on how lazy you are with updating"
echo -e "...this could take a little while, grab a coffee!\n\n${NC}"
sleep 5

# Fix kali mirror - issue that has popped up randomly
sudo rm /etc/apt/sources.list
echo "deb http://kali.download/kali kali-rolling main contrib non-free non-free-firmware" >/etc/apt/sources.list

# Update and upgrade the system
# libpcap-dev needed for PD naabu
echo -e "${YELLOW}\n\nUpdating and upgrading..\n\n${NC}"
#sudo apt install libpcap-dev -y
sudo apt update &>/dev/null && sudo apt upgrade -y --fix-missing
wait

if [ $? -eq 0 ]; then
    echo -e "${GREEN}\n\nKali update successful\n\n${NC}"
else
    echo -e "${RED}\n\nKali update failed\n\n${NC}"
    exit 1
fi

# Install docker.io and docker-compose
echo -e "${YELLOW}\n\nDownloading and installing docker..\n\n${NC}"
sudo apt install docker.io docker-compose -y
wait

if [ $? -eq 0 ]; then
    echo -e "${GREEN}\n\nDocker install successful\n\n${NC}"
else
    echo -e "${RED}\n\nDocker install failed\n\n${NC}"
    exit 1
fi

# Install pimpmykali if not already installed
if [ -f pimpmykali/pimpmykali.sh ]; then
    echo -e "${RED}\n\nPimpmykali already installed!${NC}"
    sleep 2
else
    echo -e "${YELLOW}\n\nDownloading pimpmykali...\n\n${NC}"
    git clone https://github.com/Dewalt-arch/pimpmykali.git &>/dev/null &
    wait
    sleep 2

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}\n\nPimpmykali download complete!\n\n${NC}"
        chmod +x pimpmykali/pimpmykali.sh
        sleep 2

        # Interactive prompt using expect
        expect <<EOF
        wait
        set timeout -1
        spawn pimpmykali/pimpmykali.sh
        expect "Press key for menu item selection or press X to exit:"
        send "N"
        expect "Do you want to re-enable the ability to login as root in kali?"
        send "N"
        expect eof
EOF
        # Check if expect succeeded
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}\n\nPimpmykali installation and configuration complete!\n\n${NC}"
        else
            echo -e "${RED}\n\nSomething went wrong during pimpmykali installation!\n\n${NC}"
            exit 1
        fi
    else
        echo -e "${RED}\n\nPimpmykali download failed!\n\n${NC}"
        exit 1
    fi
fi

# Install additional tools
if [ -f /home/$SUDO_USER/go/bin/pdtm ]; then
    echo -e "${RED}\n\nPD tool manager already installed!\n\n${NC}"
    exit 1
else
    echo -e "${YELLOW}\n\nInstalling PD tool manager..\n\n${NC}"
    sudo -u "$SUDO_USER" go install -v github.com/projectdiscovery/pdtm/cmd/pdtm@latest
    wait
    sleep 2
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}\n\nPD tool manager download complete!\n\n${NC}"
        sleep 2
        sudo -u "$SUDO_USER" /home/$SUDO_USER/go/bin/pdtm
        sudo -iu "$SUDO_USER" zsh -c "source ~/.zshrc"
        sudo -u "$SUDO_USER" /home/$SUDO_USER/go/bin/pdtm --install-all
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}\n\nPD tool manager installation complete!${NC}"
        else
            echo -e "${RED}\n\nSomething went wrong during PD tool manager!${NC}"
            exit 1
        fi
    else
        echo -e "${RED}\n\nPD tool manager download failed${NC}"
        exit 1
    fi
fi

# Download bloodhound docker-compose.yml
echo -e "${YELLOW}\n\nDownloading bloodhound docker-compose.yml..\n\n${NC}"
sudo mkdir /opt/Bloodhound
cd /opt/Bloodhound
sudo curl -Lo docker-compose.yml https://ghst.ly/getbhce
wait

if [ $? -eq 0 ]; then
    echo -e "${GREEN}\n\nBloodhound download successful\n\n${NC}"
else
    echo -e "${RED}\n\nBloodhound download failed\n\n${NC}"
    exit 1
fi

echo -e "${GREEN}\n\nSetup complete!\n\n${NC}"
