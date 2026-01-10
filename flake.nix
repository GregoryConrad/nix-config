{
  description = "Gregory Conrad's Configuration of Everything";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      deploy-rs,
    }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      mkFlakeOutput = f: nixpkgs.lib.genAttrs systems f;

      # NOTE: used by ./home/git.nix
      git = {
        settings = {
          user.name = "Gregory Conrad";
          user.email = "gregorysconrad@gmail.com";
        };
      };

      mkHomeManagerModule = specialArgs: homeManagerModules: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = specialArgs // {
          inherit git;
        };
        home-manager.users.${specialArgs.username} = nixpkgs.lib.mkMerge homeManagerModules;
      };
    in
    {
      formatter = mkFlakeOutput (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
      apps = mkFlakeOutput (system: {
        deploy-rs = deploy-rs.apps.${system}.deploy-rs;
      });
      deploy = import ./deploy inputs;

      darwinConfigurations.Groog-MBP =
        let
          username = "gconrad";
          hostname = "Groog-MBP";
          specialArgs = inputs // {
            inherit username hostname;
          };
        in
        nix-darwin.lib.darwinSystem {
          inherit specialArgs;
          modules = [
            ./hosts/modules/darwin-common.nix
            ./hosts/Groog-MBP.nix
            home-manager.darwinModules.home-manager
            (mkHomeManagerModule specialArgs [
              (import ./home)
              (import ./home/personal.nix)
            ])
          ];
        };

      darwinConfigurations.Greg-Work-MBP =
        let
          username = "greg";
          hostname = "Greg-Work-MBP";
          specialArgs = inputs // {
            inherit username hostname;
          };
          workExtrasPath = "/Users/greg/Documents/work-darwin-config.nix";
        in
        nix-darwin.lib.darwinSystem {
          inherit specialArgs;
          modules = [
            ./hosts/modules/darwin-common.nix
            ./hosts/Greg-Work-MBP.nix
            home-manager.darwinModules.home-manager
            (mkHomeManagerModule specialArgs [ (import ./home) ])

            # NOTE: this out-of-repo import is what requires impure.
            # Frankly too much effort to do this a "proper" way, like:
            # - A private git repo, that is added as a git submodule
            # - Via secret management (never looked into this enough)
            (if builtins.pathExists workExtrasPath then import workExtrasPath else { })
          ];
        };

      nixosConfigurations.optimus =
        let
          username = "gconrad";
          hostname = "optimus";
          specialArgs = inputs // {
            inherit username hostname;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            ./hosts/modules/nixos-common.nix
            ./hosts/modules/management.nix
            ./hosts/optimus
            home-manager.nixosModules.home-manager
            (mkHomeManagerModule specialArgs [ (import ./home) ])
          ];
        };

      images.rpi4 = self.nixosConfigurations.rpi4.config.system.build.sdImage;
      nixosConfigurations.rpi4 =
        let
          username = "gconrad";
          hostname = "rpi4";
          specialArgs = inputs // {
            inherit username hostname;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            ./hosts/modules/nixos-common.nix
            ./hosts/modules/management.nix
            ./hosts/rpi4
          ];
        };
    };
}
