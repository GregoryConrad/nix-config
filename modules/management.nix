{ ... }:
{
  # Tailscale
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
    openssh.authorizedKeys.keyFiles = [ ../deploy/authorized_keys.pub ];
  };
}
