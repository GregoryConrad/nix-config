{
  description = "Gregory Conrad's Configuration of Everything";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});

      # NOTE: used by ./home/git.nix
      git = {
        settings = {
          user.name = "Gregory Conrad";
          user.email = "gregorysconrad@gmail.com";
        };
      };
    in
    {
      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);

      # sudo nixos-rebuild switch --flake .#nixos-server
      nixosConfigurations.nixos-server =
        let
          username = "gconrad";
          hostname = "nixos-server";
          specialArgs = inputs // {
            inherit username hostname git;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          system = "x86_64-linux";
          modules = [
            ./hosts/nixos-server

            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = specialArgs;
              home-manager.users.${username} = import ./home;
            }
          ];
        };

      # darwin-rebuild switch --flake .#Groog-MBP
      darwinConfigurations.Groog-MBP =
        let
          username = "gconrad";
          hostname = "Groog-MBP";
          specialArgs = inputs // {
            inherit username hostname git;
          };
        in
        nix-darwin.lib.darwinSystem {
          inherit specialArgs;
          system = "aarch64-darwin";
          modules = [
            ./hosts/darwin-common.nix
            ./hosts/Groog-MBP.nix

            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = specialArgs;
              home-manager.users.${username} = nixpkgs.lib.mkMerge [
                (import ./home)
                (import ./home/personal.nix)
              ];
            }
          ];
        };

      # darwin-rebuild switch --flake .#Greg-Work-MBP --impure
      darwinConfigurations.Greg-Work-MBP =
        let
          username = "gsconrad";
          hostname = "Greg-Work-MBP";
          specialArgs = inputs // {
            inherit username hostname git;
          };
          workExtrasPath = "/Volumes/workplace/work-extras.nix";
        in
        nix-darwin.lib.darwinSystem {
          inherit specialArgs;
          system = "aarch64-darwin";
          modules = [
            ./hosts/darwin-common.nix
            ./hosts/Greg-Work-MBP.nix

            home-manager.darwinModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = specialArgs;
              home-manager.users.${username} = nixpkgs.lib.mkMerge [
                (import ./home)
                (if builtins.pathExists workExtrasPath then import workExtrasPath else { })
              ];
            }
          ];
        };
    };
}
