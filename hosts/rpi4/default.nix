{
  pkgs,
  nixpkgs,
  username,
  ...
}:
{
  imports = [
    "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
  ];

  nixpkgs.hostPlatform = "aarch64-linux";

  time.timeZone = "America/New_York";

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05";
}
