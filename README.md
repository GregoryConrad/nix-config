# nix-config

> Formerly my `dotfiles` repo.
> I went all-in on nix and absolutely love it; [you should too](https://zero-to-nix.com/)!

## Overview
This repo is managed at the top level via `flake.nix`, which defines configuration for:
- My personal MacBook Pro
- My work MacBook Pro (requires a special `work-extras.nix`)
- `optimus`, an old Optiplex 9020 that I picked up some years ago
- `rpi4`, a Raspberry Pi 4

The two MBPs are configured via [nix-darwin].

### Building and Deploying
```bash
# Rebuild local system
sudo nixos-rebuild switch --flake .#HOSTNAME
sudo darwin-rebuild switch --flake .#HOSTNAME # --impure if needed

# Deploy to hosts (via ./deploy/default.nix)
nix run .#deploy-rs -- . -- --impure # --impure needed for builtins.currentSystem

# Create Raspberry Pi SD card image
nix build .#images.rpi4
```

Since I'm bound to forget how to set everything up on macOS, here's the TL;DR:
```zsh
# Install nix
# TODO these instructions are apt to change soon, just see the latest here:
# https://github.com/NixOS/nix-installer

# Setup for nix-darwin
sudo mkdir -p /etc/nix-darwin
sudo chown $(id -nu):$(id -ng) /etc/nix-darwin
cd /etc/nix-darwin
git clone git@github.com:GregoryConrad/nix-config.git .
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#HOSTNAME-GOES-HERE
```

## Tech I Use
- Nix (obviously)
- [nix-darwin] for configuring macOS to my liking
- [home-manager] for configuring my dotfiles, programs, and other config
- [fish] for my shell (with a modified [fish-helix](https://github.com/sshilovsky/fish-helix))
- [Helix] for text/code editing
- [WezTerm] for my terminal (with the Hack Nerd Font)
  - I love the scripting via Lua


[nix-darwin]: https://github.com/LnL7/nix-darwin
[home-manager]: https://github.com/nix-community/home-manager
[fish]: https://fishshell.com/
[Helix]: https://helix-editor.com
[WezTerm]: https://wezfurlong.org/wezterm/
