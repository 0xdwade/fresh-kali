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
        echo -e "${RED}\nThis script must be run as root.${NC}"
        exit 1
    fi
}

# Check for root privileges
check_root

echo -e "${YELLOW}\nMOST of this script is automated.."
echo -e "The only time you might have to interact is during kali "update / upgrade""
echo -e "Once that completes it should be hands free${NC}"
sleep 5

# Fix kali mirror - issue that has popped up randomly
sudo rm /etc/apt/sources.list
echo "deb http://kali.download/kali kali-rolling main contrib non-free non-free-firmware" >/etc/apt/sources.list

# Update and upgrade the system
# libpcap-dev needed for PD naabu
echo -e "${YELLOW}\nUpdating and upgrading..${NC}"
sudo apt install libpcap-dev -y
sudo apt update &>/dev/null && sudo apt upgrade -y --fix-missing
wait

if [ $? -eq 0 ]; then
    echo -e "${GREEN}\nKali update successful${NC}"
else
    echo -e "${RED}\nKali update failed${NC}"
    exit 1
fi

# Install docker.io and docker-compose
sudo apt install docker.io docker-compose -y
if [ $? -eq 0 ]; then
    echo -e "${GREEN}\nDocker install successful${NC}"
else
    echo -e "${RED}\nDocker install failed${NC}"
    exit 1
fi

# Install pimpmykali if not already installed
if [ -f pimpmykali/pimpmykali.sh ]; then
    echo -e "${RED}\nPimpmykali already installed!${NC}"
    sleep 2
else
    echo -e "${YELLOW}\nDownloading pimpmykali...${NC}"
    git clone https://github.com/Dewalt-arch/pimpmykali.git &>/dev/null &
    wait

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}\nPimpmykali download complete!${NC}"
        chmod +x pimpmykali/pimpmykali.sh

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
            echo -e "${GREEN}\nPimpmykali installation and configuration complete!${NC}"
        else
            echo -e "${RED}\nSomething went wrong during pimpmykali installation!${NC}"
            exit 1
        fi
    else
        echo -e "${RED}\nPimpmykali download failed!${NC}"
        exit 1
    fi
fi

# Install additional tools
if [ -f /home/$SUDO_USER/go/bin/pdtm ]; then
    echo -e "${RED}\nPD tool manager already installed!${NC}"
    exit 1
else
    echo -e "${YELLOW}\nInstalling PD tool manager..${NC}"
    sudo -u "$SUDO_USER" go install -v github.com/projectdiscovery/pdtm/cmd/pdtm@latest
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}PD tool manager download complete!${NC}"
        sudo -u "$SUDO_USER" /home/$SUDO_USER/go/bin/pdtm
        sudo -iu "$SUDO_USER" zsh -c "source ~/.zshrc"
        sudo -u "$SUDO_USER" /home/$SUDO_USER/go/bin/pdtm --install-all
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}\nPD tool manager installation complete!${NC}"
        else
            echo -e "${RED}\nSomething went wrong during PD tool manager!${NC}"
            exit 1
        fi
    else
        echo -e "${RED}\nPD tool manager download failed${NC}"
        exit 1
    fi
fi

# Download bloodhound docker-compose.yml
sudo mkdir /opt/Bloodhound
cd /opt/Bloodhound
sudo curl -Lo docker-compose.yml https://ghst.ly/getbhce
if [ $? -eq 0 ]; then
    echo -e "${GREEN}\nBloodhound download successful${NC}"
else
    echo -e "${RED}\nBloodhound download failed${NC}"
    exit 1
fi

echo -e "${GREEN}\nSetup complete!${NC}"
