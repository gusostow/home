# Project Overview

This is a Nix Home Manager configuration repository managing both a macOS laptop and a NixOS home server (`ultan`). The repo contains ~2,382 lines of Nix code implementing a production-grade home lab with media automation, infrastructure services, monitoring, and SSO.

# Guidelines

Do not remind me to rebuild and switch every time you make a change. I know how to roll out changes
to my system.

Never make write-type git commands. I will commit and push my own work.

# How-to

You can SSH to ultan for investigations. Don't do this unless asked.

```
$ ssh ultan.home
```

# Directory Structure

```
/Users/aostow/dev/home/
├── flake.nix                  # main flake: laptop + ultan configs
├── home/
│   ├── profiles/              # per-host user profiles
│   │   ├── laptop.nix        # macOS profile with AWS SSO
│   │   └── ultan.nix         # server user profile
│   └── modules/              # shared Home Manager modules
│       ├── terminal.nix      # zsh, git, tmux, CLI tools
│       ├── dev.nix           # dev tools (go, rust, node, etc.)
│       └── neovim.nix        # neovim with CoC + LSPs
├── nixos/
│   ├── hosts/                # NixOS system configs
│   │   ├── ultan.nix        # main server config
│   │   └── ultan-hardware.nix
│   └── modules/              # 20+ service modules
│       ├── plex/            # media stack (*arr suite)
│       ├── caddy.nix        # reverse proxy
│       ├── pihole.nix       # DNS + ad-blocking
│       ├── wireguard.nix    # VPN server
│       ├── step-ca.nix      # internal PKI
│       ├── keycloak.nix     # SSO/IdP
│       └── monitoring/      # prometheus, grafana, loki
├── secrets/                  # agenix encrypted secrets
├── pkgs/                     # custom packages (decluttarr)
├── scripts/                  # utility scripts
├── nvim/                     # neovim config files
├── tmux/                     # tmux config
└── sh/                       # shell utilities
```

# Key Configurations

## Hosts

- **laptop** (macOS): `homeConfigurations."aostow@laptop"` - standalone Home Manager
- **ultan** (NixOS): `nixosConfigurations.ultan` - full system with server services

## Server Details (ultan)

- Static IP: 192.168.0.245
- Disk pooling: mergerfs combining /mnt/space1 + /mnt/space2 into /space
- Internal domain: .home TLD with custom CA for TLS
- External domains: plex.foamer.net, requests.foamer.net, vpn.foamer.net

## Deployment

- **Laptop**: `nix-switch` → `home-manager switch --flake home#aostow@laptop` (local)
- **Server**: `nix-switch` → `sudo nixos-rebuild switch --refresh --flake home#ultan` (from GitHub)
- Pre-commit hooks: auto-format Nix with nixfmt-rfc-style

# Important Patterns

## Modular Services

Services use enable options like `services.mediaStack.enable` with shared config:
- Data directory: `services.mediaStack.dataDir` (default: /space)
- Shared media group (gid 1500) for file permissions
- Consistent user/group management across services

## Secret Management

- All secrets encrypted with agenix
- Public keys in secrets/secrets.nix
- Access at runtime via `config.age.secrets.<name>.path`

## Internal Networking

- Pi-hole provides DNS for .home domains
- step-ca provides TLS certificates for internal services
- Caddy reverse proxy with OAuth2 protection via Keycloak
- WireGuard VPN on 10.0.0.0/24 subnet (4 clients configured)

## Registry Aliases

Both hosts define `home` registry:
- Laptop: points to local /Users/aostow/dev/home
- Server: points to GitHub gusostow/home

# Services Overview

## Media Stack (nixos/modules/plex/)

- Plex Media Server
- Download automation: qBittorrent, Prowlarr, Radarr, Sonarr
- Overseerr (requests), Tautulli (analytics)
- Unpackerr, Decluttarr (custom cleanup tool)

## Infrastructure

- **Caddy**: Reverse proxy with automatic HTTPS (Let's Encrypt + internal CA)
- **Pi-hole**: DNS with ad-blocking (Steven Black, OISD, AdGuard lists)
- **WireGuard**: VPN server with iptables NAT/forwarding
- **step-ca**: Internal PKI (root + intermediate CAs)
- **Keycloak**: SSO/IdP for internal services
- **oauth2-proxy**: Forward auth integrated with Keycloak

## Monitoring

- **Prometheus**: Metrics collection + custom AMD GPU exporter
- **Grafana**: Visualization
- **Loki**: Log aggregation

## Other

- **Immich**: Self-hosted photos
- **DDNS**: Updates AWS Route 53 for foamer.net
- **Backup**: Daily S3 backups via rclone (systemd timer at 2am)

# Utility Scripts

- **scripts/generate-wireguard-client.sh**: Generate WireGuard client configs
- **scripts/s3-backup.sh**: Backup script (runs daily via systemd)
- **sh/utils.sh**: Shell utilities (copy, mkcd, abs, share-cmd, etc.)

# Development

- Pre-commit hooks: `nix run .#install-hooks`
- Custom packages in pkgs/ (currently: decluttarr v2.0.0)
- Comment style: single sentence = lowercase, no period; multiple = uppercase, periods

# Dependencies

- nixpkgs: nixos-25.11
- home-manager: release-25.11
- agenix: secret management
- pre-commit-hooks: automatic formatting
