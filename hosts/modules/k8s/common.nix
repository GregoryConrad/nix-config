{
  config,
  pkgs,
  k3sConfig,
  ...
}:
{
  boot.kernelModules = [ "rbd" ]; # required for Rook/Ceph's RBD

  environment.systemPackages = [ pkgs.k9s ];

  # TODO change these if config.services.k3s.role is "agent"!
  networking.firewall.allowedTCPPorts = [
    6443 # k3s: required so that pods can reach the API server (running on port 6443 by default)
    2379 # k3s, etcd clients: required if using a "High Availability Embedded etcd" configuration
    2380 # k3s, etcd peers: required if using a "High Availability Embedded etcd" configuration
  ];
  networking.firewall.allowedUDPPorts = [
    8472 # k3s, flannel: required if using multi-node for inter-node networking
  ];

  # TODO is there something like this for the k3s containerd?
  # https://rook.io/docs/rook/latest-release/Getting-Started/Prerequisites/prerequisites/?h=nix#nixos
  # systemd.services.containerd.serviceConfig = {
  # LimitNOFILE = lib.mkForce null;
  # };

  # NOTE: this enables us to use USB devices for rook/ceph, as they are ignored otherwise.
  # Switches all disk devices marked as "usb" to "scsi", which rook/ceph does not ignore.
  # Adapted from https://github.com/rook/rook/issues/14699#issuecomment-2350953135
  services.udev.extraRules = ''
    ACTION=="add", ENV{ID_TYPE}=="disk", ENV{ID_BUS}=="usb", ENV{ID_BUS}="scsi"
    ACTION=="change", ENV{ID_TYPE}=="disk", ENV{ID_BUS}=="usb", ENV{ID_BUS}="scsi"
    ACTION=="online", ENV{ID_TYPE}=="disk", ENV{ID_BUS}=="usb", ENV{ID_BUS}="scsi"
  '';

  # WARN: make sure all k3s nodes have access to this secret in sops!
  sops.secrets.k3sToken = {
    sopsFile = ../../../secrets/k3s.yaml;
    key = "token";
  };

  services.k3s = k3sConfig // {
    enable = true;
    disable = [ "local-storage" ]; # we are using Rook/Ceph instead
    tokenFile = config.sops.secrets.k3sToken.path;

    # TODO do we need any of these?
    # extraFlags = [
    # NOTE: we need to use eth1 since we are in an integration test, where:
    # - eth0 is reserved for the NixOS test driver
    # - eth1 is reserved for inter-node communication
    # "--flannel-iface eth1"
    # ];
  };
}
