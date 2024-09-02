{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-24.05-darwin";
    darwin.url = "github:lnl7/nix-darwin/master";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    darwin,
    nixpkgs,
    ...
  } @ inputs: let
    inherit (darwin.lib) darwinSystem;
    system = "aarch64-darwin";
    pkgs = nixpkgs.legacyPackages."${system}";
    linuxSystem = builtins.replaceStrings ["darwin"] ["linux"] system;

    darwin-builder = nixpkgs.lib.nixosSystem {
      system = linuxSystem;
      modules = [
        "${nixpkgs}/nixos/modules/profiles/macos-builder.nix"
        {
          virtualisation = {
            host.pkgs = pkgs;
            darwin-builder.workingDirectory = "/var/lib/darwin-builder";
            darwin-builder.hostPort = 22;

            # Exclude on first build to bootstrap from cache
            darwin-builder.diskSize = 50 * 1024;
            darwin-builder.memorySize = 20 * 1024;
            cores = 4;
          };
        }
      ];
    };
  in {
    darwinConfigurations = {
      builder = darwinSystem {
        inherit system;
        modules = [
          {
            nix.distributedBuilds = true;
            nix.buildMachines = [
              {
                hostName = "localhost";
                sshUser = "builder";
                sshKey = "/etc/nix/builder_ed25519";
                system = linuxSystem;
                maxJobs = 4;
                supportedFeatures = ["kvm" "benchmark" "big-parallel"];
              }
            ];
            nix.useDaemon = true;
            nix.settings.trusted-users = ["root" "thetasinner"];

            launchd.daemons.darwin-builder = {
              command = "${darwin-builder.config.system.build.macos-builder-installer}/bin/create-builder";
              serviceConfig = {
                KeepAlive = true;
                RunAtLoad = true;
                StandardOutPath = "/var/log/darwin-builder.log";
                StandardErrorPath = "/var/log/darwin-builder.log";
              };
            };
          }
        ];
      };
    };
  };
}
