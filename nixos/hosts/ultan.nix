# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  # Hardware config is imported by flake.nix, don't import here
  imports = [ ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "ultan"; # Define your hostname.

  # Static IP configuration
  networking = {
    networkmanager.enable = false; # Disable NetworkManager for static config
    useDHCP = false;
    interfaces.enp34s0 = {
      useDHCP = false;
      ipv4.addresses = [
        {
          address = "192.168.0.245";
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = "192.168.0.1"; # Your router IP
    nameservers = [
      # pi-hole running on same host
      "127.0.0.1"
      # fallback
      "8.8.8.8"
    ];
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  security.rtkit.enable = true;

  # Increase sudo timeout to 30 minutes
  security.sudo.extraConfig = ''
    Defaults timestamp_timeout=30
  '';

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Disable automatic suspend/hibernate
  systemd.sleep.extraConfig = ''
    AllowSuspend=no
    AllowHibernation=no
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
  '';

  # Disable GNOME's automatic suspend
  services.displayManager.gdm.autoSuspend = false;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with 'passwd'.
  users.users.aostow = {
    isNormalUser = true;
    description = "Augustus";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFFejeagAt8t4oK1CgY/1jOw5UqHYSybEG2XZts8WNZADIh4tL6OhfG66TTxXNdVTcFhFSQlN5zZ/3C2g/o4X9wc52J11qmmXO/1xN0640oU7+/POW+HWZMsgoQB0GOptNI6gSzoMGayZqmWJYra1RmJYTJfWCAFwhPGLzXrnxCnH6koSqXutqsAstm+MXOgkv1Xle5Ul2ZEO3gx/6OjoYjlf7NX6WDJCL1bF8IpAFbIBvTRAQ07U0i2gmkaaFQFsGUIht6lBdLoBvAWoYOoHOhnv+/LN8/xVeOPuB7BKZfJ02mGnKrKHQWv7tjywe0zTuZVPKCuvaZrozY7yNzGrHGDAMNaaX5WQg+FwDrJJ1kp2ZJk2VdZ+N7zVEeAsQl87JzVlqbQIQvtQt3aFo96n+2ZarWYdCEiPQ0iQxHFJdDiXIoZ5BSWc5bDXREqLazTAWqXaXl71XfHXmgaCrwoa+t6+1YHafhzWOSMo9NjSerTVY2EgcVJMD9hoDKP9xHQs= aostow@Augustuss-Air.nyc.rr.com"
    ];
    packages = with pkgs; [
      #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Enable zsh system-wide
  programs.zsh.enable = true;

  # Enable flakes and new nix commands system-wide
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
    "auto-allocate-uids"
    "configurable-impure-env"
  ];

  # Add registry alias for home config repo
  nix.registry.home = {
    from = {
      id = "home";
      type = "indirect";
    };
    to = {
      owner = "gusostow";
      repo = "home";
      type = "github";
    };
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    amdgpu_top
    dig
    ethtool
    mergerfs
    unixtools.netstat
    unixtools.ifconfig
    pciutils
    radeontop
    tcpdump
    unrar
    vim
    wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
    # Only allow SSH for aostow user
    extraConfig = ''
      AllowUsers aostow
    '';
  };

  # Firewall configuration using nftables
  networking.nftables.enable = true;

  # Open ports for testing
  networking.firewall.allowedTCPPorts = [ 9999 ];
  networking.nftables.tables.geoblock = {
    family = "inet";
    content = ''
      # Set to hold US IP ranges (populated by systemd service)
      set us_ipv4 {
        type ipv4_addr
        flags interval
        auto-merge
      }

      chain prerouting {
        type filter hook prerouting priority raw;

        # Allow all private networks (RFC1918)
        ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } accept

        # Allow localhost
        ip saddr 127.0.0.0/8 accept

        # Allow established/related connections
        ct state { established, related } accept

        # For public services (SSH, HTTP, HTTPS), only allow US IPs
        tcp dport { 22, 80, 443 } ip saddr @us_ipv4 accept
        tcp dport { 22, 80, 443 } drop

        # Allow all other traffic (non-public services)
        accept
      }
    '';
  };

  # Service to download and update US IP ranges
  systemd.services.geoip-update = {
    description = "Update US IP ranges for geoblocking";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "geoip-update" ''
        set -euo pipefail

        # Create directory for IP lists
        mkdir -p /var/lib/geoip

        # Download US IP ranges from ipdeny.com
        ${pkgs.curl}/bin/curl -f -o /var/lib/geoip/us.zone \
          https://www.ipdeny.com/ipblocks/data/aggregated/us-aggregated.zone

        # Convert to nftables format and reload
        (
          echo "flush set inet geoblock us_ipv4"
          echo "add element inet geoblock us_ipv4 {"
          ${pkgs.gawk}/bin/awk '{printf "  %s,\n", $1}' /var/lib/geoip/us.zone | ${pkgs.gnused}/bin/sed '$ s/,$//'
          echo "}"
        ) | ${pkgs.nftables}/bin/nft -f -

        echo "GeoIP update completed successfully"
      '';
    };
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };

  # Timer to update IP ranges daily
  systemd.timers.geoip-update = {
    description = "Daily update of US IP ranges";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "1d";
      Persistent = true;
    };
  };

  # mount 2TB SATA SSD
  fileSystems."/mnt/space1" = {
    device = "/dev/disk/by-uuid/8a784acc-6319-4459-8fec-d1c3e90a5ac5";
    fsType = "ext4";
    options = [ "defaults" ];
  };

  # mount 12TB removeable HDD
  fileSystems."/mnt/space2" = {
    device = "/dev/disk/by-uuid/ad899781-fe94-4f3b-9545-9305e60d8cf4";
    fsType = "ext4";
    options = [
      "defaults"
      "nofail"
      "x-systemd.device-timeout=5"
    ];
  };

  # merge both disks into /space at the file level
  fileSystems."/space" = {
    device = "/mnt/space1:/mnt/space2";
    fsType = "fuse.mergerfs";
    options = [
      "defaults"
      "allow_other"
      "use_ino"
      "category.create=mfs"
      "nofail"
      "x-systemd.device-timeout=5"
    ];
    depends = [
      "/mnt/space1"
      "/mnt/space2"
    ];
  };

  # Enable media stack (Plex, *arr apps, etc.)
  services.mediaStack.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
