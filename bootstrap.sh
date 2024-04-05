#!/bin/bash

# Define configurations for each host at the top of the script
declare -A HOST_CONFIG=(
    ["hv-2"]="enp37s0,10.173.5.70/24,10.173.5.1,1.1.1.1,true,5"
)

# List of Nix packages to install
NIX_PACKAGES="python312 git wget tmux"

# Hostname passed as a script argument
HOSTNAME=$1
if [ -z "$HOSTNAME" ]; then
    echo "Usage: $0 <hostname>"
    exit 1
fi

IFS=',' read -ra CONFIG <<< "${HOST_CONFIG[$HOSTNAME]}"
if [ ${#CONFIG[@]} -eq 0 ]; then
    echo "No configuration found for host: $HOSTNAME"
    exit 1
fi

NETWORK_INTERFACE=${CONFIG[0]}
IP_ADDRESS=${CONFIG[1]}
DEFAULT_GATEWAY=${CONFIG[2]}
DNS_SERVER=${CONFIG[3]}
SETUP_VLAN=${CONFIG[4]}
VLAN_NUMBER=${CONFIG[5]}
# Define logging function
log() {
    echo "`date '+%Y-%m-%d %H:%M:%S'`: $1"
}

# Check if the script is run as root
if [ "$(id -u)" -ne "0" ]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Function to create a VLAN interface
create_vlan() {
    if [ "$SETUP_VLAN" = "true" ]; then
        log "Creating VLAN Interface on $NETWORK_INTERFACE with VLAN ID $VLAN_NUMBER..."
        ip link add link $NETWORK_INTERFACE name ${NETWORK_INTERFACE}.${VLAN_NUMBER} type vlan id $VLAN_NUMBER &>> vlan_setup.log
        if [ $? -eq 0 ]; then
            log "VLAN Interface created successfully."
        else
            log "Failed to create VLAN Interface. See vlan_setup.log for details."
            exit 1
        fi
    else
        log "VLAN setup skipped."
    fi
}

# Function to set static IP
assign_ip() {
    if [ "$IP_ADDRESS" != "" ] && [ "$SETUP_VLAN" = "true" ]; then
        log "Assigning static IP to VLAN Interface..."
        ip addr add $IP_ADDRESS dev ${NETWORK_INTERFACE}.${VLAN_NUMBER} &>> vlan_setup.log
        if [ $? -eq 0 ]; then
            log "Static IP assigned successfully."
        else
            log "Failed to assign static IP. See vlan_setup.log for details."
            exit 1
        fi
    else
        log "Skipping IP assignment."
    fi
}


# Function to activate VLAN interface
activate_vlan() {
    log "Activating VLAN Interface..."
    ip link set dev ${NETWORK_INTERFACE}.5 up &>> vlan_setup.log
    if [ $? -eq 0 ]; then
        log "VLAN Interface activated successfully."
    else
        log "Failed to activate VLAN Interface. See vlan_setup.log for details."
        exit 1
    fi
}

# Function to configure the default gateway
configure_gateway() {
    if [ "$DEFAULT_GATEWAY" != "" ]; then
        log "Configuring default gateway..."
        ip route add default via $DEFAULT_GATEWAY &>> vlan_setup.log
        if [ $? -eq 0 ]; then
            log "Default gateway configured successfully."
        else
            log "Failed to configure default gateway. See vlan_setup.log for details."
            exit 1
        fi
    else
        log "Skipping gateway configuration."
    fi
}

# Function to configure DNS
configure_dns() {
    if [ "$DNS_SERVER" != "" ]; then
        log "Configuring DNS..."
        echo "nameserver $DNS_SERVER" | tee -a /etc/resolv.conf &>> vlan_setup.log
        if [ $? -eq 0 ]; then
            log "DNS configured successfully."
        else
            log "Failed to configure DNS. See vlan_setup.log for details."
            exit 1
        fi
    else
        log "Skipping DNS configuration."
    fi
}
# Function to verify internet connectivity
check_internet() {
    log "Checking Internet connectivity..."
    ping -c 4 8.8.8.8 &>> vlan_setup.log
    if [ $? -eq 0 ]; then
        log "Internet connectivity verified."
    else
        log "Internet connectivity check failed. See vlan_setup.log for details."
        exit 1
    fi
}

# Function to verify DNS resolution
check_dns() {
    log "Checking DNS resolution..."
    ping -c 4 google.com &>> vlan_setup.log
    if [ $? -eq 0 ]; then
        log "DNS resolution verified."
    else
        log "DNS resolution check failed. See vlan_setup.log for details."
        exit 1
    fi
}

# Function to download and configure SSH keys for root and nixos users
configure_ssh_keys() {
    log "Downloading and configuring SSH keys for root and nixos users..."

    # Define users and their home directories
    declare -A USER_HOME_DIRS=(["root"]="/root" ["nixos"]="/home/nixos")

    for user in "${!USER_HOME_DIRS[@]}"; do
        home_dir=${USER_HOME_DIRS[$user]}
        
        # Ensure the .ssh directory exists with the correct permissions
        mkdir -p "$home_dir/.ssh"
        chmod 700 "$home_dir/.ssh"
        
        # Download SSH keys and append to authorized_keys, ensuring file has correct permissions
        if curl https://github.com/blakeashleyjr.keys | tee -a "$home_dir/.ssh/authorized_keys" &>> vlan_setup.log; then
            chmod 600 "$home_dir/.ssh/authorized_keys"
            
            # Ensure correct ownership
            chown -R $user:$user "$home_dir/.ssh"
            
            log "SSH keys configured successfully for $user."
        else
            log "Failed to configure SSH keys for $user. See vlan_setup.log for details."
            exit 1
        fi
    done
}

# Function to generate NixOS hardware configuration
generate_nixos_hardware_config() {
    log "Generating NixOS hardware configuration..."

    # Ensure the target directory exists
    if [ ! -d "/mnt" ]; then
        log "/mnt directory does not exist. Creating it..."
        mkdir -p /mnt &>> vlan_setup.log
        if [ $? -ne 0 ]; then
            log "Failed to create /mnt directory. See vlan_setup.log for details."
            exit 1
        fi
    fi

    # Generate hardware configuration without filesystems
    sudo nixos-generate-config --no-filesystems --root /mnt &>> vlan_setup.log
    if [ $? -eq 0 ]; then
        log "NixOS hardware configuration generated successfully."
    else
        log "Failed to generate NixOS hardware configuration. See vlan_setup.log for details."
        exit 1
    fi
}

# Install Nix packages
install_nix_packages() {
    log "Installing Nix packages: $NIX_PACKAGES..."
    for pkg_name in $NIX_PACKAGES; do
        # Prepend 'nixos.' to each package name
        pkg="nixos.$pkg_name"
        nix-env -iA $pkg &>> nix_packages_install.log
        if [ $? -eq 0 ]; then
            log "$pkg installed successfully."
        else
            log "Failed to install $pkg. See nix_packages_install.log for details."
            exit 1
        fi
    done
    log "All Nix packages installed successfully."
}


# Execute functions based on the configuration
[ "$SETUP_VLAN" = "true" ] && create_vlan
assign_ip
activate_vlan
configure_gateway
configure_dns
check_internet
check_dns
configure_ssh_keys
generate_nixos_hardware_config
install_nix_packages # Calling the function to install Nix packages

log "Network, hardware, and software configuration for $HOSTNAME completed successfully."
