{
  self,
  deploy-rs,
  ...
}:
let
  mkNode = hostname: system: {
    inherit hostname;
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
    rpi5 = mkNode "rpi5" "aarch64-linux";
    rpi4 = mkNode "rpi4" "aarch64-linux";
  };
}
