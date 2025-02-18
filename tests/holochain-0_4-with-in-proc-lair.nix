{
  self,
  system,
  holonix,
  ...
}: {
  name = "Holochain 0.4 With Lair";

  nodes = {
    machine = {pkgs, ...}: {
      imports = [
        self.outputs.nixosModules.hcCommon
        self.outputs.nixosModules.lair-keystore-for-0_4
        self.outputs.nixosModules.conductor-0_4
      ];

      services.conductor-0_4 = {
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
  testScript = builtins.readFile ./holochain-0_4-with-in-proc-lair.py;
}
