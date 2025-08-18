/*
* Copyright 2024 - 2025 ThetaSinner. All rights reserved.
*
* This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
* This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
* You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
*/
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
    flake-parts.url = "github:hercules-ci/flake-parts";

    holonix-0_3 = {
      url = "github:holochain/holonix?ref=main-0.3";
    };

    holonix-0_4 = {
      url = "github:holochain/holonix?ref=main-0.4";
      inputs = {
        holochain.url = "github:holochain/holochain?ref=holochain-0.4.4";
      };
    };

    holonix-0_5 = {
      url = "github:holochain/holonix?ref=main-0.5";
      inputs = {
        holochain.url = "github:holochain/holochain?ref=holochain-0.5.5-rc.2";
      };
    };

    kitsune2-0_5 = {
      url = "github:holochain/kitsune2?ref=v0.1.14";
    };

    holonix-0_6 = {
      url = "github:holochain/holonix?ref=main";
      inputs = {
        holochain.url = "github:holochain/holochain?ref=holochain-0.6.0-dev.17";
      };
    };

    kitsune2-0_6 = {
      url = "github:holochain/kitsune2?ref=v0.2.14";
    };

    # Works with Holochain 0.4
    hc-ops-0_1 = {
      url = "github:ThetaSinner/hc-ops?ref=release-0.1";
    };

    # Works with Holochain 0.5
    hc-ops-0_2 = {
      url = "github:ThetaSinner/hc-ops?ref=main";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    holonix-0_3,
    holonix-0_4,
    holonix-0_5,
    holonix-0_6,
    kitsune2-0_5,
    kitsune2-0_6,
    hc-ops-0_1,
    hc-ops-0_2,
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

            users.users.k2server = {
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
          conductor-0_6 = {pkgs, ...}: {
            imports = [./modules/conductor-0_6.nix];
          };
          k2-server-0_5 = {pkgs, ...}: {
            imports = [./modules/k2-server-0_5.nix];
          };
          k2-server-0_6 = {pkgs, ...}: {
            imports = [./modules/k2-server-0_6.nix];
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
          lair-keystore-for-0_6 = {pkgs, ...}: {
            imports = [./modules/lair-keystore-for-0_6.nix];
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

            system.stateVersion = "25.05";

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

              services.lair-keystore-for-0_4 = {
                enable = true;
                id = "test";
                package = holonix-0_4.packages.${system}.lair-keystore;
                passphrase = "password";
              };

              services.conductor-0_4 = {
                enable = true;
                id = "test";
                lairId = "test";
                package = holonix-0_4.packages.${system}.holochain;
                keystorePassphrase = "password";
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

              services.lair-keystore-for-0_5 = {
                enable = true;
                id = "test";
                package = holonix-0_5.packages.${system}.lair-keystore;
                passphrase = "password";
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
            self.nixosModules.lair-keystore-for-0_5
          ];
          mkModules-0_6 = {system}: [
            vmModule
            {
              environment.systemPackages = [
                holonix-0_6.packages.${system}.lair-keystore
                holonix-0_6.packages.${system}.holochain
              ];

              services.lair-keystore-for-0_6 = {
                enable = true;
                id = "test";
                package = holonix-0_6.packages.${system}.lair-keystore;
                passphrase = "password";
              };

              services.conductor-0_6 = {
                enable = true;
                id = "test";
                lairId = "test";
                package = holonix-0_6.packages.${system}.holochain;
                keystorePassphrase = "password";
              };
            }
            self.nixosModules.hcCommon
            self.nixosModules.conductor-0_6
            self.nixosModules.lair-keystore-for-0_6
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
          aarch64-darwin-test-0_6 = nixpkgs.lib.nixosSystem rec {
            system = "aarch64-linux";
            modules =
              mkModules-0_6 {inherit system;}
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
          aarch64-linux-test-0_6 = nixpkgs.lib.nixosSystem rec {
            system = "aarch64-linux";
            modules = mkModules-0_6 {inherit system;};
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
          x86_64-linux-test-0_6 = nixpkgs.lib.nixosSystem rec {
            system = "x86_64-linux";
            modules = mkModules-0_6 {inherit system;};
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
        packages.vm-0_6 = self.nixosConfigurations."${system}-test-0_6".config.system.build.vm;
        # Provided for compatibility with older versions
        packages.hc-ops = hc-ops-0_1.packages.${system}.hc-ops;
        packages.hc-ops-0_1 = hc-ops-0_1.packages.${system}.hc-ops;
        packages.hc-ops-0_2 = hc-ops-0_2.packages.${system}.hc-ops;

        devShells.default = pkgs.mkShell {
          packages =
            (with pkgs; [nodejs_22])
            ++ (with holonix-0_5.packages.${system};
              [
                lair-keystore
                holochain
              ]
              ++ [
                hc-ops-0_2.packages.${system}.hc-ops
              ]);
        };

        checks = let
          pkgs = import nixpkgs {inherit system;};
        in {
          holochain-0_3-with-lair = pkgs.testers.runNixOSTest (import ./tests/holochain-0_3-with-lair.nix {
            inherit self system;
            holonix = holonix-0_3;
          });
          holochain-0_3-with-in-proc-lair = pkgs.testers.runNixOSTest (import ./tests/holochain-0_3-with-in-proc-lair.nix {
            inherit self system;
            holonix = holonix-0_3;
          });
          holochain-0_4-with-lair = pkgs.testers.runNixOSTest (import ./tests/holochain-0_4-with-lair.nix {
            inherit self system;
            holonix = holonix-0_4;
          });
          holochain-0_4-with-in-proc-lair = pkgs.testers.runNixOSTest (import ./tests/holochain-0_4-with-in-proc-lair.nix {
            inherit self system;
            holonix = holonix-0_4;
          });
          holochain-0_5-with-lair = pkgs.testers.runNixOSTest (import ./tests/holochain-0_5-with-lair.nix {
            inherit self system;
            holonix = holonix-0_5;
          });
          holochain-0_5-with-in-proc-lair = pkgs.testers.runNixOSTest (import ./tests/holochain-0_5-with-in-proc-lair.nix {
            inherit self system;
            holonix = holonix-0_5;
          });
          holochain-0_6-with-lair = pkgs.testers.runNixOSTest (import ./tests/holochain-0_6-with-lair.nix {
            inherit self system;
            holonix = holonix-0_6;
          });
          holochain-0_6-with-in-proc-lair = pkgs.testers.runNixOSTest (import ./tests/holochain-0_6-with-in-proc-lair.nix {
            inherit self system;
            holonix = holonix-0_6;
          });
          holochain-and-lair-side-by-side = pkgs.testers.runNixOSTest (import ./tests/holochain-and-lair-side-by-side.nix {
            inherit self system;
            holonix-0_4 = holonix-0_4;
            holonix-0_5 = holonix-0_5;
            holonix-0_6 = holonix-0_6;
          });
          kitsune2-0_5-server = pkgs.testers.runNixOSTest (import ./tests/k2-server-0_5.nix {
            inherit self system kitsune2-0_5;
          });
          kitsune2-0_6-server = pkgs.testers.runNixOSTest (import ./tests/k2-server-0_6.nix {
            inherit self system kitsune2-0_6;
          });
        };
      };
    });
}
