{
  description = "Gregory Conrad's Configuration of Everything";

  nixConfig = {
    extra-substituters = [ "https://gregoryconrad-nix-config.cachix.org" ];
    extra-trusted-public-keys = [
      "gregoryconrad-nix-config.cachix.org-1:Q6KV2EXusXFMUHB+kumMEOcq9Y5S4JxTdr0mPeA0ofY="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    # TODO once https://github.com/nvmd/nixos-raspberrypi/pull/131 is merged:
    # nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";
    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/remove-options-compat";
    nixos-raspberrypi.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      disko,
      deploy-rs,
      sops-nix,
      nixos-raspberrypi,
    }:
    let
      # NOTE: a special arg used by ./home/git.nix
      git = {
        settings = {
          user.name = "Gregory Conrad";
          user.email = "gregorysconrad@gmail.com";
        };
      };
    in
    {
      lib = {
        mkFlakeOutput = f: nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed f;

        mkHomeManagerModule = specialArgs: homeManagerModules: {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = specialArgs;
          home-manager.users.${specialArgs.username} = nixpkgs.lib.mkMerge homeManagerModules;
        };
      };

      formatter = self.lib.mkFlakeOutput (system: nixpkgs.legacyPackages.${system}.nixfmt-tree);
      apps = self.lib.mkFlakeOutput (system: {
        deploy-rs = deploy-rs.apps.${system}.deploy-rs;
      });
      deploy = import ./deploy inputs;
      devShells = self.lib.mkFlakeOutput (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = with pkgs; [
              sops
              ssh-to-age
              helm-ls
            ];

            shellHook = ''
              export SOPS_AGE_KEY="$(ssh-to-age -private-key -i ~/.ssh/id_ed25519)"
            '';
          };
        }
      );

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
          modules = [
            ./modules/darwin-common.nix
            ./modules/darwin-nix.nix
            ./hosts/Groog-MBP.nix
            home-manager.darwinModules.home-manager
            (self.lib.mkHomeManagerModule specialArgs [
              (import ./home)
              (import ./home/personal.nix)
            ])
          ];
        };

      imageScripts.optimus = self.nixosConfigurations.optimus.config.system.build.diskoImagesScript;
      nixosConfigurations.optimus =
        let
          username = "gconrad";
          hostname = "optimus";
          k3sConfig = {
            nodeIP = "100.64.0.1";
            clusterInit = true;
          };
          specialArgs = inputs // {
            inherit
              username
              hostname
              git
              k3sConfig
              ;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit specialArgs;
          modules = [
            sops-nix.nixosModules.sops
            ./modules/nixos-common.nix
            ./modules/management.nix
            ./modules/k8s
            ./modules/k8s/deployer.nix
            ./hosts/optimus
            home-manager.nixosModules.home-manager
            (self.lib.mkHomeManagerModule specialArgs [ (import ./home) ])
          ];
        };

      images.rpi5 = self.nixosConfigurations.rpi5.config.system.build.sdImage;
      nixosConfigurations.rpi5 =
        let
          username = "gconrad";
          hostname = "rpi5";
          k3sConfig = {
            nodeIP = "100.64.0.2";
            serverAddr = "https://${self.nixosConfigurations.optimus.config.services.k3s.nodeIP}:6443";
          };
          specialArgs = inputs // {
            inherit username hostname k3sConfig;
          };
        in
        nixos-raspberrypi.lib.nixosInstaller {
          inherit specialArgs;
          modules = [
            sops-nix.nixosModules.sops
            ./modules/nixos-common.nix
            ./modules/management.nix
            ./modules/k8s
            ./hosts/rpi5
          ];
        };

      images.rpi4 = self.nixosConfigurations.rpi4.config.system.build.sdImage;
      nixosConfigurations.rpi4 =
        let
          username = "gconrad";
          hostname = "rpi4";
          k3sConfig = {
            nodeIP = "100.64.0.3";
            serverAddr = "https://${self.nixosConfigurations.optimus.config.services.k3s.nodeIP}:6443";
          };
          specialArgs = inputs // {
            inherit username hostname k3sConfig;
          };
        in
        nixos-raspberrypi.lib.nixosInstaller {
          inherit specialArgs;
          modules = [
            sops-nix.nixosModules.sops
            ./modules/nixos-common.nix
            ./modules/management.nix
            ./modules/k8s
            ./hosts/rpi4
          ];
        };
    };
}
