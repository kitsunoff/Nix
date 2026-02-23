# Colima-based Linux builder with Rosetta 2 support
# Provides aarch64-linux (native) and x86_64-linux (via Rosetta) builds
{ lib, ... }:
{
  flake.darwinModules.colima-builder =
    { config, lib, pkgs, ... }:
    let
      cfg = config.nix.colima-builder;
    in
    {
      options.nix.colima-builder = {
        enable = lib.mkEnableOption "Colima-based Linux builder with Rosetta 2";

        sshPort = lib.mkOption {
          type = lib.types.port;
          default = 2222;
          description = "SSH port for Colima VM";
        };

        sshKey = lib.mkOption {
          type = lib.types.path;
          default = "/Users/${config.users.primaryUser.name or "kitsunoff"}/.ssh/nix-builder-colima";
          description = "Path to SSH private key for builder";
        };

        maxJobs = lib.mkOption {
          type = lib.types.int;
          default = 4;
          description = "Maximum number of parallel jobs on the builder";
        };

        systems = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "aarch64-linux" "x86_64-linux" ];
          description = "Systems supported by the builder";
        };

        speedFactor = lib.mkOption {
          type = lib.types.int;
          default = 1;
          description = "Speed factor for the builder (higher = preferred)";
        };

        supportedFeatures = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
          description = "Supported features of the builder";
        };

        profile = lib.mkOption {
          type = lib.types.str;
          default = "nix-builder";
          description = "Colima profile name";
        };

        cpu = lib.mkOption {
          type = lib.types.int;
          default = 4;
          description = "Number of CPUs for Colima VM";
        };

        memory = lib.mkOption {
          type = lib.types.int;
          default = 8;
          description = "Memory in GB for Colima VM";
        };

        disk = lib.mkOption {
          type = lib.types.int;
          default = 60;
          description = "Disk size in GB for Colima VM";
        };
      };

      config = lib.mkIf cfg.enable {
        # Configure nix to use the builder
        # Port is specified in hostName as ssh://host:port format doesn't work,
        # so we use SSH config alias instead
        nix.buildMachines = [{
          hostName = "colima-nix-builder";
          sshUser = "root";
          sshKey = cfg.sshKey;
          protocol = "ssh-ng";
          systems = cfg.systems;
          maxJobs = cfg.maxJobs;
          speedFactor = cfg.speedFactor;
          supportedFeatures = cfg.supportedFeatures;
        }];

        # SSH config for the builder with the custom port
        environment.etc."ssh/ssh_config.d/colima-nix-builder.conf".text = ''
          Host colima-nix-builder
            HostName 127.0.0.1
            Port ${toString cfg.sshPort}
            User root
            IdentityFile ${cfg.sshKey}
            StrictHostKeyChecking no
            UserKnownHostsFile /dev/null
        '';

        nix.distributedBuilds = true;

        # Allow building for linux systems
        nix.settings.extra-platforms = cfg.systems;

        # Setup script for bootstrapping the builder
        environment.systemPackages = [
          (pkgs.writeShellScriptBin "colima-builder-setup" ''
            set -euo pipefail
            export PATH="${pkgs.colima}/bin:${pkgs.jq}/bin:${pkgs.openssh}/bin:${pkgs.curl}/bin:$PATH"

            PROFILE="${cfg.profile}"
            SSH_PORT="${toString cfg.sshPort}"
            SSH_KEY="${cfg.sshKey}"
            CPU="${toString cfg.cpu}"
            MEMORY="${toString cfg.memory}"
            DISK="${toString cfg.disk}"

            log() { echo "[$(date '+%H:%M:%S')] $*"; }
            error() { echo "[$(date '+%H:%M:%S')] ERROR: $*" >&2; exit 1; }

            ssh_vm() { colima ssh --profile "$PROFILE" -- "$@"; }
            ssh_vm_sudo() { colima ssh --profile "$PROFILE" -- sudo "$@"; }

            is_running() { colima status --profile "$PROFILE" &>/dev/null; }
            profile_exists() { colima list --json 2>/dev/null | ${pkgs.jq}/bin/jq -e ".[] | select(.name == \"$PROFILE\")" &>/dev/null; }

            is_nix_installed() { ssh_vm bash -c 'source /etc/profile && command -v nix' &>/dev/null; }
            is_nix_daemon_running() { ssh_vm_sudo systemctl is-active nix-daemon.socket &>/dev/null; }

            start_colima() {
              log "Checking Colima VM..."
              if is_running; then
                log "Colima '$PROFILE' already running"
                return 0
              fi

              if profile_exists; then
                log "Starting existing profile..."
                colima start --profile "$PROFILE"
              else
                log "Creating new Colima VM with Rosetta 2..."
                colima start \
                  --profile "$PROFILE" \
                  --vm-type vz \
                  --vz-rosetta \
                  --cpu "$CPU" \
                  --memory "$MEMORY" \
                  --disk "$DISK" \
                  --network-address \
                  --ssh-port "$SSH_PORT"
              fi
              log "Colima started"
            }

            cleanup_broken_nix() {
              log "Cleaning up broken Nix..."
              ssh_vm_sudo bash -c '
                systemctl stop nix-daemon.socket nix-daemon.service 2>/dev/null || true
                systemctl disable nix-daemon.socket nix-daemon.service 2>/dev/null || true
                systemctl daemon-reload || true
                rm -f /etc/bash.bashrc.backup-before-nix /etc/bashrc.backup-before-nix
                rm -f /etc/profile.d/nix.sh.backup-before-nix /etc/zshrc.backup-before-nix
                rm -rf /nix /etc/nix /etc/profile.d/nix.sh
                rm -f /etc/systemd/system/nix-daemon.service /etc/systemd/system/nix-daemon.socket
                for h in /root /home/*; do rm -rf "$h"/.nix-{profile,defexpr,channels} "$h"/.local/state/nix "$h"/.cache/nix 2>/dev/null || true; done
                for i in $(seq 1 32); do userdel "nixbld$i" 2>/dev/null || true; done
                groupdel nixbld 2>/dev/null || true
              '
            }

            install_nix() {
              log "Checking Nix in VM..."
              if is_nix_installed && is_nix_daemon_running; then
                log "Nix already installed and running"
                return 0
              fi

              if ssh_vm test -d /nix 2>/dev/null; then
                cleanup_broken_nix
              fi

              log "Installing dependencies..."
              ssh_vm_sudo bash -c '
                if command -v apt-get &>/dev/null && ! command -v xz &>/dev/null; then
                  apt-get update && apt-get install -y xz-utils curl
                fi
              '

              log "Installing Nix (this takes a few minutes)..."
              ssh_vm bash -c '
                cd /tmp
                curl -L -o install-nix https://nixos.org/nix/install
                chmod +x install-nix
                sudo sh ./install-nix --daemon --yes
                rm -f install-nix
              '
              log "Nix installed"
            }

            configure_nix() {
              log "Configuring Nix..."

              # Check if fully configured (including extra-platforms)
              if ssh_vm_sudo grep -q "extra-platforms = x86_64-linux" /etc/nix/nix.conf 2>/dev/null; then
                log "Nix already configured"
                return 0
              fi

              # Remove old partial config if exists
              ssh_vm_sudo bash -c '
                # Backup and clean
                if grep -q "trusted-users" /etc/nix/nix.conf; then
                  sed -i "/# Builder configuration/,/^$/d" /etc/nix/nix.conf 2>/dev/null || true
                fi

                cat >> /etc/nix/nix.conf << EOF

# Builder configuration
experimental-features = nix-command flakes
trusted-users = root @wheel @nixbld
max-jobs = auto
cores = 0
# Enable x86_64-linux builds via Rosetta 2
extra-platforms = x86_64-linux
sandbox = false
EOF
                systemctl restart nix-daemon
              '
              log "Nix configured with x86_64-linux support"
            }

            setup_ssh() {
              log "Setting up SSH..."
              if [[ ! -f "$SSH_KEY" ]]; then
                log "Generating SSH key..."
                ssh-keygen -t ed25519 -f "$SSH_KEY" -N "" -C "nix-builder-colima"
              fi

              local pubkey
              pubkey=$(cat "''${SSH_KEY}.pub")

              ssh_vm_sudo bash -c "
                mkdir -p /root/.ssh
                chmod 700 /root/.ssh
                grep -qF '$pubkey' /root/.ssh/authorized_keys 2>/dev/null || echo '$pubkey' >> /root/.ssh/authorized_keys
                chmod 600 /root/.ssh/authorized_keys
              "
              log "SSH configured"
            }

            test_builder() {
              log "Testing builder..."
              if ssh -i "$SSH_KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=no -o BatchMode=yes \
                  root@127.0.0.1 "bash -c 'source /etc/profile && nix --version'" 2>&1; then
                log "SSH connection OK"
              else
                error "SSH connection failed"
              fi

              log "Testing x86_64-linux build..."
              if ssh -i "$SSH_KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=no -o BatchMode=yes \
                  root@127.0.0.1 "bash -c 'source /etc/profile && nix build --no-link --system x86_64-linux nixpkgs#hello'" 2>&1; then
                log "x86_64-linux builds work via Rosetta!"
              else
                log "Warning: x86_64 test failed (may work anyway)"
              fi
            }

            main() {
              log "Setting up Colima Nix builder with Rosetta 2"
              start_colima
              install_nix
              configure_nix
              setup_ssh
              test_builder
              log "Setup complete!"
            }

            main "$@"
          '')

          (pkgs.writeShellScriptBin "colima-builder-start" ''
            export PATH="${pkgs.colima}/bin:$PATH"
            colima start --profile "${cfg.profile}" 2>/dev/null || true
          '')

          (pkgs.writeShellScriptBin "colima-builder-stop" ''
            export PATH="${pkgs.colima}/bin:$PATH"
            colima stop --profile "${cfg.profile}" 2>/dev/null || true
          '')
        ];
      };
    };
}
