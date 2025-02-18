{
  self,
  system,
  holonix,
  ...
}: {
  name = "Holochain 0.3 With In Process Lair";

  nodes = {
    machine = {pkgs, ...}: {
      imports = [
        self.outputs.nixosModules.hcCommon
        self.outputs.nixosModules.conductor-0_3
      ];

      services.conductor-0_3 = {
        enable = true;
        id = "test";
        lairId = "test";
        package = holonix.packages.${system}.holochain;
        keystorePassphrase = "password";
        config = {
          keystore = {
            type = "lair_server_in_proc";
          };
        };
      };

      system.stateVersion = "24.11";
    };
  };

  # https://nixos.org/manual/nixos/stable/index.html#ssec-machine-objects
  testScript = builtins.readFile ./holochain-0_3-with-in-proc-lair.py;
}
