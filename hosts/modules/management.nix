{ pkgs, ... }:
{
  # Tailscale
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;
  networking.search = [ "tail36d0f.ts.net" ];
  networking.nameservers = [
    "100.100.100.100"
    "8.8.8.8"
    "1.1.1.1"
  ];
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
  };

  # deploy-rs
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };
  nix.settings.trusted-users = [
    "root"
    "deploy"
  ];
  security.sudo.wheelNeedsPassword = false;
  users.users.deploy = {
    isNormalUser = true;
    description = "User for deploy-rs SSH access";
    extraGroups = [ "wheel" ];

    openssh.authorizedKeys.keyFiles =
      let
        githubKeys = pkgs.fetchurl {
          url = "https://github.com/GregoryConrad.keys";
          # nix-prefetch-url https://github.com/GregoryConrad.keys
          sha256 = "0wpz9hrnp8pypqn3wn6siiwba3m056s7mdszjk4x1vjmc0zx9gan";
        };
      in
      [ githubKeys ];
  };
}
