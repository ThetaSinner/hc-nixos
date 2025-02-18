{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    flake-parts.url = "github:hercules-ci/flake-parts";

    holonix-0_3 = {
      url = "github:holochain/holonix?ref=main-0.3";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };

    tryorama-0_3 = {
      url = "github:holochain/tryorama?ref=main-0.3";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    holonix-0_4 = {
      url = "github:holochain/holonix?ref=main-0.4";
      inputs = {
        holochain.url = "github:holochain/holochain?ref=holochain-0.4.1";
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };

    tryorama-0_4 = {
      url = "github:holochain/tryorama?ref=main-0.4";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    holonix-0_5 = {
      url = "github:holochain/holonix?ref=main";
      inputs = {
        holochain.url = "github:holochain/holochain?ref=holochain-0.5.0-dev.18";
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };

    tryorama-0_5 = {
      url = "github:holochain/tryorama?ref=main";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    holonix-0_3,
    tryorama-0_3,
    holonix-0_4,
    tryorama-0_4,
    holonix-0_5,
    tryorama-0_5,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} ({withSystem, ...}: {
      flake = {
        nixosModules = {
          hcCommon = {...}: {
            users.groups.holochain = {};

            users.users.conductor = {
              isSystemUser = true;
              group = "holochain";
            };

            users.users.trycp = {
              isSystemUser = true;
              group = "holochain";
            };
          };
          conductor-0_3 = {pkgs, ...}: {
            imports = [./modules/conductor-0_3.nix];
          };
          conductor-0_4 = {pkgs, ...}: {
            imports = [./modules/conductor-0_4.nix];
          };
          conductor-0_5 = {pkgs, ...}: {
            imports = [./modules/conductor-0_5.nix];
          };
          lair-keystore-for-0_3 = {pkgs, ...}: {
            imports = [./modules/lair-keystore-for-0_3.nix];
          };
          lair-keystore-for-0_4 = {pkgs, ...}: {
            imports = [./modules/lair-keystore-for-0_4.nix];
          };
          lair-keystore-for-0_5 = {pkgs, ...}: {
            imports = [./modules/lair-keystore-for-0_5.nix];
          };
          trycp-server = {pkgs, ...}: {
            imports = [./modules/trycp-server.nix];
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

            system.stateVersion = "24.11";

            # Configure networking
            networking.useDHCP = false;
            networking.interfaces.eth0.useDHCP = true;

            # Create user "test"
            services.getty.autologinUser = "test";
            users.users.test.isNormalUser = true;

            # Enable paswordless ‘sudo’ for the "test" user
            users.users.test.extraGroups = ["wheel"];
            security.sudo.wheelNeedsPassword = false;

            # Make it output to the terminal instead of separate window
            virtualisation.graphics = false;
          };
          mkModules-0_3 = {system}: [
            vmModule
            {
              services.lair-keystore-for-0_3 = {
                enable = true;
                id = "test";
                package = holonix-0_3.packages.${system}.lair-keystore;
                passphrase = "password";
              };

              services.conductor-0_3 = {
                enable = true;
                id = "test";
                lairId = "test";
                package = holonix-0_3.packages.${system}.holochain;
                keystorePassphrase = "password";
              };
            }
            self.nixosModules.hcCommon
            self.nixosModules.conductor-0_3
            self.nixosModules.lair-keystore-for-0_3
          ];
          mkModules-0_4 = {system}: [
            vmModule
            {
              environment.systemPackages = [
                holonix-0_4.packages.${system}.lair-keystore
                holonix-0_4.packages.${system}.holochain
              ];

              environment.etc."lair-test/device.bundle".text = builtins.readFile ./tests/sample-device-seed.bundle;

              services.lair-keystore-for-0_4 = {
                enable = true;
                id = "test";
                package = holonix-0_4.packages.${system}.lair-keystore;
                passphrase = "password";
                deviceSeed = "test";
                seedPassphrase = "pass";
              };

              services.conductor-0_4 = {
                enable = true;
                id = "test";
                lairId = "test";
                package = holonix-0_4.packages.${system}.holochain;
                keystorePassphrase = "password";
                deviceSeed = "test";
              };
            }
            self.nixosModules.hcCommon
            self.nixosModules.conductor-0_4
            self.nixosModules.lair-keystore-for-0_4
          ];
          mkModules-0_5 = {system}: [
            vmModule
            {
              environment.systemPackages = [
                holonix-0_5.packages.${system}.lair-keystore
                holonix-0_5.packages.${system}.holochain
              ];

              services.lair-keystore-for-0_4 = {
                enable = true;
                id = "test";
                package = holonix-0_5.packages.${system}.lair-keystore;
                passphrase = "password";
                deviceSeed = "test";
                seedPassphrase = "pass";
              };

              services.conductor-0_5 = {
                enable = true;
                id = "test";
                lairId = "test";
                package = holonix-0_5.packages.${system}.holochain;
                keystorePassphrase = "password";
              };
            }
            self.nixosModules.hcCommon
            self.nixosModules.conductor-0_5
            self.nixosModules.lair-keystore-for-0_4
          ];
        in {
          aarch64-darwin-test-0_3 = nixpkgs.lib.nixosSystem rec {
            system = "aarch64-linux";
            modules =
              mkModules-0_3 {inherit system;}
              ++ [
                {
                  virtualisation.host.pkgs = nixpkgs.legacyPackages.aarch64-darwin;
                }
              ];
          };
          aarch64-darwin-test-0_4 = nixpkgs.lib.nixosSystem rec {
            system = "aarch64-linux";
            modules =
              mkModules-0_4 {inherit system;}
              ++ [
                {
                  virtualisation.host.pkgs = nixpkgs.legacyPackages.aarch64-darwin;
                }
              ];
          };
          aarch64-darwin-test-0_5 = nixpkgs.lib.nixosSystem rec {
            system = "aarch64-linux";
            modules =
              mkModules-0_5 {inherit system;}
              ++ [
                {
                  virtualisation.host.pkgs = nixpkgs.legacyPackages.aarch64-darwin;
                }
              ];
          };
          aarch64-linux-test-0_3 = nixpkgs.lib.nixosSystem rec {
            system = "aarch64-linux";
            modules = mkModules-0_3 {inherit system;};
          };
          aarch64-linux-test-0_4 = nixpkgs.lib.nixosSystem rec {
            system = "aarch64-linux";
            modules = mkModules-0_4 {inherit system;};
          };
          aarch64-linux-test-0_5 = nixpkgs.lib.nixosSystem rec {
            system = "aarch64-linux";
            modules = mkModules-0_5 {inherit system;};
          };
          x86_64-linux-test-0_3 = nixpkgs.lib.nixosSystem rec {
            system = "x86_64-linux";
            modules = mkModules-0_4 {inherit system;};
          };
          x86_64-linux-test-0_4 = nixpkgs.lib.nixosSystem rec {
            system = "x86_64-linux";
            modules = mkModules-0_4 {inherit system;};
          };
          x86_64-linux-test-0_5 = nixpkgs.lib.nixosSystem rec {
            system = "x86_64-linux";
            modules = mkModules-0_5 {inherit system;};
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

        packages.vm-0_3 = self.nixosConfigurations."${system}-test-0_3".config.system.build.vm;
        packages.vm-0_4 = self.nixosConfigurations."${system}-test-0_4".config.system.build.vm;
        packages.vm-0_5 = self.nixosConfigurations."${system}-test-0_5".config.system.build.vm;

        devShells.default = pkgs.mkShell {
          packages =
            (with pkgs; [nodejs_22])
            ++ (with holonix-0_5.packages.${system}; [
              lair-keystore
              holochain
            ]);
        };

        checks = let
          pkgs = import nixpkgs {inherit system;};
        in {
          holochain-0_3-with-lair = pkgs.testers.runNixOSTest (import ./tests/holochain-0_3-with-lair.nix {
            inherit self system;
            holonix = holonix-0_3;
          });
          holochain-0_4-with-lair = pkgs.testers.runNixOSTest (import ./tests/holochain-0_4-with-lair.nix {
            inherit self system;
            holonix = holonix-0_4;
          });
          holochain-0_5-with-lair = pkgs.testers.runNixOSTest (import ./tests/holochain-0_5-with-lair.nix {
            inherit self system;
            holonix = holonix-0_5;
          });
          holochain-and-lair-side-by-side = pkgs.testers.runNixOSTest (import ./tests/holochain-and-lair-side-by-side.nix {
            inherit self system;
            holonix-0_3 = holonix-0_3;
            holonix-0_4 = holonix-0_4;
            holonix-0_5 = holonix-0_5;
          });
        };
      };
    });
}
