{
  nix.gc.automatic = true;
  nix.linux-builder.enable = true;
  nix.linux-builder.config.virtualisation.cores = 8;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
}
