{
  pkgs,
  hostname,
  username,
  ...
}:
{
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  nix.gc.automatic = true;
  nix.linux-builder.enable = true;
  nix.linux-builder.config.virtualisation.cores = 8;

  environment.shells = [ pkgs.fish ];
  programs.fish.enable = true;

  system.primaryUser = username;
  users.users.${username} = {
    home = "/Users/${username}";
  };

  fonts.packages = with pkgs; [
    nerd-fonts.hack
  ];

  homebrew = {
    enable = true;
    casks = [
      "unnaturalscrollwheels"
      "vlc"
      "wezterm"
    ];
  };

  networking.hostName = hostname;
  networking.computerName = hostname;
  system.defaults.smb.NetBIOSName = hostname;

  security.pam.services.sudo_local.touchIdAuth = true;
}
