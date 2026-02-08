{ pkgs, username, ... }:
{
  imports = [
    ./shell.nix
    ./editor.nix
    ./git.nix
  ];

  home = {
    inherit username;

    # This value determines the Home Manager release that your
    # configuration is compatible with. This helps avoid breakage
    # when a new Home Manager release introduces backwards
    # incompatible changes.
    #
    # You can update Home Manager without changing this value. See
    # the Home Manager release notes for a list of state version
    # changes in each release.
    stateVersion = "26.05";

    packages = with pkgs; [
      nil # Can't decide if I like nil or nixd more, but nil is written in Rust...
      gh
      sl
      asciiquarium
    ];

    file =
      let
        # NOTE: this injects the helix executable's path into the wezterm scrollback script
        helixBinPath = "${pkgs.helix}/bin/hx";
        scrollbackLua = builtins.replaceStrings [ "__HELIX_BIN_PATH__" ] [ helixBinPath ] (
          builtins.readFile ./wezterm/scrollback.lua
        );
      in
      {
        ".config/background.jpg".source = ./background.jpg;
        ".config/wezterm/wezterm.lua".source = ./wezterm/wezterm.lua;
        ".config/wezterm/scrollback.lua".text = scrollbackLua;
      };
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
