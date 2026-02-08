{
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./disks.nix
  ];

  hardware.facter.reportPath = ./facter.json;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.immich = {
    enable = true;
    host = "0.0.0.0";
    openFirewall = true;
  };

  users.users.${username} = {
    isNormalUser = true;
    description = username;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    openssh.authorizedKeys.keyFiles = [ ../../deploy/authorized_keys.pub ];
  };

  time.timeZone = "America/New_York";
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

  # WARN: see the following before changing:
  # https://search.nixos.org/options?channel=unstable&show=system.stateVersion&query=system.stateVersion
  system.stateVersion = "26.05";
}
