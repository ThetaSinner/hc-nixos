{
  self,
  system,
  kitsune2-0_6,
  ...
}: {
  name = "Kitsune2 server for 0.6";

  nodes = {
    machine = {pkgs, ...}: {
      imports = [
        self.outputs.nixosModules.hcCommon
        self.outputs.nixosModules.k2-server-0_6
      ];

      services.k2-server-0_6 = {
        enable = true;
        package = kitsune2-0_6.packages.${system}.bootstrap-srv;
        config = {
          port = 8000;
        };
      };

      system.stateVersion = "25.05";
    };
  };

  # https://nixos.org/manual/nixos/stable/index.html#ssec-machine-objects
  testScript = builtins.readFile ./k2-server-0_6.py;
}
