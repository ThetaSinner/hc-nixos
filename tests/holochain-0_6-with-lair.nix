{
  self,
  system,
  holonix,
  ...
}: {
  name = "Holochain 0.6 With Lair";

  nodes = {
    machine = {pkgs, ...}: {
      imports = [
        self.outputs.nixosModules.hcCommon
        self.outputs.nixosModules.lair-keystore-for-0_6
        self.outputs.nixosModules.conductor-0_6
      ];

      services.lair-keystore-for-0_6 = {
        enable = true;
        id = "test";
        package = holonix.packages.${system}.lair-keystore;
        passphrase = "password";
      };

      services.conductor-0_6 = {
        enable = true;
        id = "test";
        lairId = "test";
        package = holonix.packages.${system}.holochain;
        keystorePassphrase = "password";
      };

      system.stateVersion = "25.05";
    };
  };

  # https://nixos.org/manual/nixos/stable/index.html#ssec-machine-objects
  testScript = builtins.readFile ./holochain-0_6-with-lair.py;
}
