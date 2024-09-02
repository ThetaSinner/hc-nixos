{self, ...}: {
  name = "Holochain with Lair";

  nodes = {
    machine = {pkgs, ...}: {
      imports = [
        self.outputs.nixosModules.hcCommon
        self.outputs.nixosModules.conductor
        self.outputs.nixosModules.lair-keystore
      ];

      services.conductor = {
        enable = true;
        deviceSeed = "test";
        keystorePassphrase = "password";
      };

      services.lair-keystore = {
        enable = true;
        passphrase = "password";
      };

      system.stateVersion = "24.04";
    };
  };

  # https://nixos.org/manual/nixos/stable/index.html#ssec-machine-objects
  testScript = builtins.readFile ./holochain-with-lair.py;
}
