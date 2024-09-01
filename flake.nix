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

  outputs = inputs@{ self, nixpkgs, flake-parts, holonix_0_3, holonix_0_4, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } ({ withSystem, ... }: {
      flake = {
        nixosModules = {

          conductor = { pkgs, ... }: {
            imports = [ ./modules/conductor.nix ];
            services.conductor.package = withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }:
              config.packages.holochain
            );
          };
          lair-keystore = { pkgs, ... }: {
            imports = [ ./modules/lair-keystore.nix ];
            services.lair-keystore.package = withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }:
              config.packages.lair-keystore
            );
          };
        };

        nixosConfigurations.test =
          let
            vmModule =
              { config, pkgs, lib, modulesPath, ... }:
              {
                imports = [
                  "${modulesPath}/virtualisation/qemu-vm.nix"
                ];

                system.stateVersion = "24.05";

                # Configure networking
                networking.useDHCP = false;
                networking.interfaces.eth0.useDHCP = true;

                # Create user "test"
                services.getty.autologinUser = "test";
                users.users.test.isNormalUser = true;

                # Enable paswordless ‘sudo’ for the "test" user
                users.users.test.extraGroups = [ "wheel" ];
                security.sudo.wheelNeedsPassword = false;

                # Make it output to the terminal instead of separate window
                virtualisation.graphics = false;
              };
            withStoreImage = {
              virtualisation.useNixStoreImage = true;
              virtualisation.writableStore = true;
            };
          in
          nixpkgs.lib.nixosSystem {
            system = "aarch64-linux";
            modules = [
              vmModule
              {
                virtualisation.host.pkgs = nixpkgs.legacyPackages.aarch64-darwin;

                environment.systemPackages = [
                  holonix_0_4.packages.aarch64-linux.lair-keystore
                ];

                users.groups.holochain = { };

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
              self.nixosModules.conductor
              self.nixosModules.lair-keystore
            ];
          };
      };
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      perSystem = { system, config, pkgs, ... }: {
        formatter = pkgs.nixpkgs-fmt;
        packages.holochain = holonix_0_4.packages.${system}.holochain;
        packages.lair-keystore = holonix_0_4.packages.${system}.lair-keystore;

        packages.vm = self.nixosConfigurations.test.config.system.build.vm;

        checks.test1 =
          let
            pkgs = import nixpkgs { inherit system; };
          in
          pkgs.testers.runNixOSTest (import ./test.nix { inherit self; });
      };
    });
}
