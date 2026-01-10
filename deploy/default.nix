{
  self,
  deploy-rs,
  nixpkgs,
  ...
}:
let
  mkNode =
    hostname: system:
    let
      systemToArch = system: builtins.elemAt (nixpkgs.lib.splitString "-" system) 0;
      targetArch = systemToArch system;
      localArch = systemToArch builtins.currentSystem;
      remoteBuild = targetArch != localArch;
    in
    {
      inherit hostname remoteBuild;
      profiles.system.path =
        deploy-rs.lib."${system}".activate.nixos
          self.nixosConfigurations."${hostname}";
    };
in
{
  user = "root";
  sshUser = "deploy"; # NOTE: this is the "deploy" user from /hosts/modules/management.nix
  nodes = {
    # NOTE: also update /.github/workflows/deploy.yaml for new nodes
    optimus = mkNode "optimus" "x86_64-linux";
    rpi4 = mkNode "rpi4" "aarch64-linux";
  };
}
