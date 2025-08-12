{
  self,
  system,
  kitsune2-0_5,
  ...
}: {
  name = "Kitsune2 server for 0.5";

  nodes = {
    machine = {pkgs, ...}: {
      imports = [
        self.outputs.nixosModules.hcCommon
        self.outputs.nixosModules.k2-server-0_5
      ];

      services.k2-server-0_5 = {
        enable = true;
        package = kitsune2-0_5.packages.${system}.bootstrap-srv;
        config = {
          port = 8000;
        };
      };

      system.stateVersion = "25.05";
    };
  };

  # https://nixos.org/manual/nixos/stable/index.html#ssec-machine-objects
  testScript = builtins.readFile ./k2-server-0_5.py;
}
