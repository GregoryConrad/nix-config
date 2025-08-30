{ ... }:
{
  programs.fish = {
    enable = true;
    shellInit = ''
      set -gx SUDOEDIT $EDITOR
    '';
    interactiveShellInit = ''
      set fish_greeting

      # fish_helix_key_bindings is non-idempotent, so manually disable first
      fish_default_key_bindings
      fish_helix_key_bindings
    '';
  };

  home.file.".config/fish/functions" = {
    source = ./fish/functions;
    recursive = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };
}
