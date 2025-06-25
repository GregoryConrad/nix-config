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

  nix.gc.automatic = true;

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
