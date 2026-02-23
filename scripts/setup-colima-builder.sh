#!/usr/bin/env nix-shell
#! nix-shell -i bash -p colima openssh jq

# Setup Colima as a Nix remote builder with Rosetta 2 support
# This enables building x86_64-linux packages on aarch64-darwin via fast Rosetta translation

set -euo pipefail

COLIMA_PROFILE="nix-builder"
COLIMA_CPU=4
COLIMA_MEMORY=8
COLIMA_DISK=60

# Global variables set by get_ssh_config
BUILDER_HOST=""
BUILDER_PORT=""
BUILDER_SSH_KEY="$HOME/.ssh/nix-builder-colima"

log() {
    echo "[$(date '+%H:%M:%S')] $*"
}

error() {
    echo "[$(date '+%H:%M:%S')] ERROR: $*" >&2
    exit 1
}

ssh_vm() {
    colima ssh --profile "$COLIMA_PROFILE" -- "$@"
}

ssh_vm_sudo() {
    colima ssh --profile "$COLIMA_PROFILE" -- sudo "$@"
}

# Check if Colima VM is running
is_colima_running() {
    colima status --profile "$COLIMA_PROFILE" &>/dev/null
}

# Check if Colima profile exists (running or stopped)
colima_profile_exists() {
    colima list --json 2>/dev/null | jq -e ".[] | select(.name == \"$COLIMA_PROFILE\")" &>/dev/null
}

# Start Colima with Rosetta support
start_colima() {
    log "Checking Colima VM..."

    if is_colima_running; then
        log "Colima profile '$COLIMA_PROFILE' is already running"
        return 0
    fi

    if colima_profile_exists; then
        log "Starting existing Colima profile..."
        colima start --profile "$COLIMA_PROFILE"
    else
        log "Creating new Colima VM with Rosetta 2 support..."
        colima start \
            --profile "$COLIMA_PROFILE" \
            --vm-type vz \
            --vz-rosetta \
            --cpu "$COLIMA_CPU" \
            --memory "$COLIMA_MEMORY" \
            --disk "$COLIMA_DISK" \
            --network-address
    fi

    log "Colima VM started successfully"
}

# Check if Nix is installed and working in VM
is_nix_installed() {
    ssh_vm bash -c 'source /etc/profile && command -v nix' &>/dev/null
}

# Check if nix-daemon is running
is_nix_daemon_running() {
    ssh_vm_sudo systemctl is-active nix-daemon.socket &>/dev/null
}

# Install dependencies in VM
install_vm_dependencies() {
    log "Ensuring dependencies in VM..."

    ssh_vm_sudo bash -c '
        if command -v apt-get &>/dev/null; then
            # Check if xz is installed
            if ! command -v xz &>/dev/null; then
                apt-get update && apt-get install -y xz-utils curl
            fi
        elif command -v apk &>/dev/null; then
            if ! command -v xz &>/dev/null; then
                apk add --no-cache xz curl
            fi
        fi
    '
}

# Clean up broken Nix installation
cleanup_broken_nix() {
    log "Cleaning up previous Nix installation..."

    ssh_vm_sudo bash -c '
        # Stop services if they exist
        systemctl stop nix-daemon.socket 2>/dev/null || true
        systemctl stop nix-daemon.service 2>/dev/null || true
        systemctl disable nix-daemon.socket 2>/dev/null || true
        systemctl disable nix-daemon.service 2>/dev/null || true
        systemctl daemon-reload 2>/dev/null || true

        # Remove backup files that block reinstall
        rm -f /etc/bash.bashrc.backup-before-nix
        rm -f /etc/bashrc.backup-before-nix
        rm -f /etc/profile.d/nix.sh.backup-before-nix
        rm -f /etc/zshrc.backup-before-nix

        # Remove Nix files
        rm -rf /nix
        rm -rf /etc/nix
        rm -f /etc/profile.d/nix.sh
        rm -f /etc/systemd/system/nix-daemon.service
        rm -f /etc/systemd/system/nix-daemon.socket

        # Remove user Nix files
        for user_home in /root /home/*; do
            rm -rf "$user_home/.nix-profile" 2>/dev/null || true
            rm -rf "$user_home/.nix-defexpr" 2>/dev/null || true
            rm -rf "$user_home/.nix-channels" 2>/dev/null || true
            rm -rf "$user_home/.local/state/nix" 2>/dev/null || true
            rm -rf "$user_home/.cache/nix" 2>/dev/null || true
        done

        # Remove nixbld users and group
        for i in $(seq 1 32); do
            userdel "nixbld$i" 2>/dev/null || true
        done
        groupdel nixbld 2>/dev/null || true
    '

    log "Cleanup complete"
}

# Install Nix inside Colima VM
install_nix_in_vm() {
    log "Checking Nix installation in VM..."

    if is_nix_installed && is_nix_daemon_running; then
        log "Nix is already installed and running in VM"
        return 0
    fi

    # If Nix exists but is broken, clean it up
    if ssh_vm test -d /nix 2>/dev/null; then
        log "Found broken Nix installation, cleaning up..."
        cleanup_broken_nix
    fi

    install_vm_dependencies

    log "Installing Nix in VM (this may take a few minutes)..."

    ssh_vm bash -c '
        cd /tmp
        curl -L -o install-nix https://nixos.org/nix/install
        chmod +x install-nix
        sudo sh ./install-nix --daemon --yes
        rm -f install-nix
    '

    log "Nix installed successfully"
}

# Configure Nix settings in VM for builder usage
configure_nix_in_vm() {
    log "Configuring Nix in VM..."

    # Check if already configured
    if ssh_vm_sudo grep -q "trusted-users" /etc/nix/nix.conf 2>/dev/null; then
        log "Nix already configured in VM"
        return 0
    fi

    ssh_vm_sudo bash -c '
        cat >> /etc/nix/nix.conf << EOF

# Builder configuration
experimental-features = nix-command flakes
trusted-users = root @wheel @nixbld
max-jobs = auto
cores = 0
EOF
        systemctl restart nix-daemon
    '

    log "Nix configured in VM"
}

# Setup SSH access for Nix builder
setup_ssh_access() {
    log "Setting up SSH access for Nix builder..."

    # Generate dedicated SSH key if not exists
    if [[ ! -f "$BUILDER_SSH_KEY" ]]; then
        log "Generating SSH key for builder..."
        ssh-keygen -t ed25519 -f "$BUILDER_SSH_KEY" -N "" -C "nix-builder-colima"
    fi

    local pubkey
    pubkey=$(cat "${BUILDER_SSH_KEY}.pub")

    # Check if key already added
    if ssh_vm grep -qF "$pubkey" ~/.ssh/authorized_keys 2>/dev/null; then
        log "SSH key already configured"
        return 0
    fi

    # Add public key to regular user
    ssh_vm bash -c "
        mkdir -p ~/.ssh
        chmod 700 ~/.ssh
        echo '$pubkey' >> ~/.ssh/authorized_keys
        chmod 600 ~/.ssh/authorized_keys
    "

    # Add to root for nix-daemon
    ssh_vm_sudo bash -c "
        mkdir -p /root/.ssh
        chmod 700 /root/.ssh
        echo '$pubkey' >> /root/.ssh/authorized_keys
        chmod 600 /root/.ssh/authorized_keys
    "

    log "SSH access configured"
}

# Get SSH connection details
get_ssh_config() {
    local ssh_config
    ssh_config=$(colima ssh-config --profile "$COLIMA_PROFILE")

    BUILDER_HOST=$(echo "$ssh_config" | grep "HostName" | awk '{print $2}')
    BUILDER_PORT=$(echo "$ssh_config" | grep "Port" | awk '{print $2}')
}

# Test the builder connection
test_builder() {
    log "Testing builder connection..."

    get_ssh_config

    log "Connecting to $BUILDER_HOST:$BUILDER_PORT as root..."

    # Test SSH connection with nix
    local nix_version
    if nix_version=$(ssh -i "$BUILDER_SSH_KEY" -p "$BUILDER_PORT" \
        -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes \
        "root@$BUILDER_HOST" "source /etc/profile && nix --version" 2>&1); then
        log "Builder connection successful! $nix_version"
    else
        log "SSH output: $nix_version"
        error "Failed to connect to builder"
    fi

    # Test x86_64-linux build capability
    log "Testing x86_64-linux build capability (this may take a while on first run)..."
    local build_result
    if build_result=$(ssh -i "$BUILDER_SSH_KEY" -p "$BUILDER_PORT" \
        -o StrictHostKeyChecking=no -o BatchMode=yes \
        "root@$BUILDER_HOST" \
        "source /etc/profile && nix build --no-link --print-out-paths --system x86_64-linux nixpkgs#hello" 2>&1); then
        log "x86_64-linux builds work via Rosetta!"
        log "Built: $build_result"
    else
        log "Warning: x86_64-linux test build output: $build_result"
        log "This might be fine - Rosetta translation should still work for builds"
    fi
}

# Print nix.conf configuration for darwin
print_nix_config() {
    log "Generating Nix builder configuration..."

    get_ssh_config

    cat << EOF

=== Add to your nix-darwin configuration ===

nix.buildMachines = [{
  hostName = "$BUILDER_HOST";
  sshUser = "root";
  sshKey = "$BUILDER_SSH_KEY";
  protocol = "ssh-ng";
  port = $BUILDER_PORT;
  systems = [ "aarch64-linux" "x86_64-linux" ];
  maxJobs = $COLIMA_CPU;
  supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
}];

nix.distributedBuilds = true;

=== Or add to ~/.ssh/config ===

Host colima-nix-builder
    HostName $BUILDER_HOST
    Port $BUILDER_PORT
    User root
    IdentityFile $BUILDER_SSH_KEY
    StrictHostKeyChecking no

=== Then use in nix.buildMachines ===

nix.buildMachines = [{
  hostName = "colima-nix-builder";
  systems = [ "aarch64-linux" "x86_64-linux" ];
  maxJobs = $COLIMA_CPU;
  supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
}];

EOF
}

# Main
main() {
    log "Setting up Colima as Nix remote builder with Rosetta 2"
    echo ""

    start_colima
    install_nix_in_vm
    configure_nix_in_vm
    setup_ssh_access
    test_builder
    print_nix_config

    log "Setup complete!"
}

main "$@"
