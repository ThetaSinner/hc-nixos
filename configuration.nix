# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, holochain, lair-keystore, trycp-server, ... }:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./modules/lair-keystore.nix
    ./modules/trycp-server.nix
    ./modules/conductor.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.hostName = "nixos"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable =
    true; # Easiest to use and most distros use this by default.
  networking.hostName = "nuc";
  networking.interfaces.eno1.ipv4.addresses = [{
    address = "10.27.240.80";
    prefixLength = 24;
  }];
  networking.defaultGateway = "10.27.240.222";
  networking.nameservers = [ "1.1.1.1" "8.8.8.8" ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];

    substituters =
      [ "https://holochain-ci.cachix.org" "https://cache.nixos.org" ];

    trusted-public-keys = [
      "holochain-ci.cachix.org-1:5IUSkZc0aoRS53rfkvH9Kid40NpyjwCMCzwRTXy+QN8="
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  # Set your time zone.
  time.timeZone = "Europe/London";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  users.groups.holochain = { };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.thetasinner = {
    isNormalUser = true;
    home = "/home/thetasinner";
    extraGroups = [
      "wheel" # Enable ‘sudo’ for the user.
      "holochain"
    ];
  };

  users.users.lair = {
    isSystemUser = true;
    group = "holochain";
  };

  users.users.conductor = {
    isSystemUser = true;
    group = "holochain";
  };

  users.users.trycp = {
    isSystemUser = true;
    group = "holochain";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    # vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    git
    holochain
    lair-keystore
    trycp-server
    htop
    sysstat
    helix
    sqlite
    sqlcipher
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
  services.openssh.enable = true;

  services.sysstat = { enable = true; };

  services.lair-keystore = {
    enable = true;
    passphrase = "default-passphrase";
  };

  services.conductor = {
    enable = true;
    keystorePassphrase = "default-passphrase";
  };

  services.trycp-server = { enable = true; };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    9000 # trycp
  ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}

