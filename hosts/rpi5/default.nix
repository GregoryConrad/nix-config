{
  pkgs,
  username,
  nixos-raspberrypi,
  ...
}:
{
  imports = with nixos-raspberrypi.nixosModules; [
    raspberry-pi-5.base
    raspberry-pi-5.display-vc4
    raspberry-pi-5.page-size-16k
    ./nvme.nix
  ];

  # For https://github.com/k3s-io/k3s/issues/2067
  boot.kernelParams = [
    "cgroup_enable=cpuset"
    "cgroup_enable=memory"
  ];

  boot.loader.raspberry-pi.bootloader = "kernel";

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
