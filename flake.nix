{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=24.05";
    flake-parts.url = "github:hercules-ci/flake-parts";

    holonix_0_3 = {
      url = "github:holochain/holonix?ref=main-0.3";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };

    tryorama_0_3 = {
      url = "github:holochain/tryorama?ref=main";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    holonix_0_4 = {
      url = "github:holochain/holonix?ref=add-aarch64-linux";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };

    tryorama_0_4 = {
      url = "github:holochain/tryorama?ref=develop";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    holonix_0_3,
    tryorama_0_3,
    holonix_0_4,
    tryorama_0_4,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} ({withSystem, ...}: {
      flake = {
        nixosModules = {
          hcCommon = {...}: {
            users.groups.holochain = {};

            users.users.lair = {
              isSystemUser = true;
              group = "holochain";
            };

            users.users.conductor = {
              isSystemUser = true;
              group = "holochain";
            };

            users.users.trycp = {
              isSystemUser = true;
              group = "holochain";
            };
          };
          conductor = {pkgs, ...}: {
            imports = [./modules/conductor.nix];
            services.conductor.package = withSystem pkgs.stdenv.hostPlatform.system (
              {config, ...}:
                config.packages.holochain
            );
          };
          lair-keystore = {pkgs, ...}: {
            imports = [./modules/lair-keystore.nix];
            services.lair-keystore.package = withSystem pkgs.stdenv.hostPlatform.system (
              {config, ...}:
                config.packages.lair-keystore
            );
          };
          trycp-server = {pkgs, ...}: {
            imports = [./modules/trycp-server.nix];
            services.trycp-server.package = withSystem pkgs.stdenv.hostPlatform.system (
              {config, ...}:
                config.packages.trycp-server
            );
          };
        };

        nixosConfigurations = let
          vmModule = {
            config,
            pkgs,
            lib,
            modulesPath,
            ...
          }: {
            imports = [
              "${modulesPath}/virtualisation/qemu-vm.nix"
            ];

            system.stateVersion = "24.05";

            # Configure networking
            networking.useDHCP = false;
            # networking.interfaces.eth0.useDHCP = true;

            # Create user "test"
            services.getty.autologinUser = "test";
            users.users.test.isNormalUser = true;

            # Enable paswordless ‘sudo’ for the "test" user
            users.users.test.extraGroups = ["wheel"];
            security.sudo.wheelNeedsPassword = false;

            # Make it output to the terminal instead of separate window
            virtualisation.graphics = false;
          };
          modules = [
            vmModule
            {
              services.lair-keystore = {
                enable = true;
                passphrase = "password";
              };

              services.conductor = {
                enable = true;
                deviceSeed = "test";
                keystorePassphrase = "password";
              };
            }
            self.nixosModules.hcCommon
            self.nixosModules.conductor
            self.nixosModules.lair-keystore
          ];
        in {
          aarch64-darwin.test = nixpkgs.lib.nixosSystem {
            system = "aarch64-darwin";
            modules =
              modules
              ++ [
                {
                  virtualisation.host.pkgs = nixpkgs.legacyPackages.aarch64-darwin;
                }
              ];
          };
          aarch64-linux.test = nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            inherit modules;
          };
          x86_64-linux.test = nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            inherit modules;
          };
        };
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      perSystem = {
        system,
        config,
        pkgs,
        lib,
        ...
      }: {
        formatter = pkgs.alejandra;
        packages.holochain = holonix_0_4.packages.${system}.holochain;
        packages.lair-keystore = holonix_0_4.packages.${system}.lair-keystore;

        packages.vm = self.nixosConfigurations.${system}.test.config.system.build.vm;

        checks.test1 = let
          pkgs = import nixpkgs {inherit system;};
        in
          pkgs.testers.runNixOSTest (import ./tests/holochain-with-lair.nix {inherit self;});
      };
    });
}
