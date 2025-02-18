{
  self,
  system,
  holonix-0_3,
  holonix-0_4,
  ...
}: {
  name = "Holochain With Lair Side By Side";

  nodes = {
    machine = {
      pkgs,
      lib,
      ...
    }: {
      imports = [
        self.outputs.nixosModules.hcCommon
        self.outputs.nixosModules.lair-keystore-0_4
        self.outputs.nixosModules.lair-keystore-0_5
        self.outputs.nixosModules.conductor-0_3
        self.outputs.nixosModules.conductor-0_4
      ];

      services.lair-keystore-0_4 = {
        enable = true;
        id = "testA";
        package = holonix-0_3.packages.${system}.lair-keystore;
        passphrase = "passwordA";
      };

      services.conductor-0_3 = {
        enable = true;
        id = "testA";
        lairId = "testA";
        package = holonix-0_3.packages.${system}.holochain;
        keystorePassphrase = "passwordA";
        config = {
          admin_interfaces = [
            {
              driver = {
                type = "websocket";
                port = 8001;
                allowed_origins = "*";
              };
            }
          ];
        };
      };

      environment.etc."lair-testB/device.bundle".text = builtins.readFile ./sample-device-seed.bundle;

      services.lair-keystore-0_5 = {
        enable = true;
        id = "testB";
        package = holonix-0_4.packages.${system}.lair-keystore;
        passphrase = "passwordB";
        deviceSeed = "test";
        seedPassphrase = "pass";
      };

      services.conductor-0_4 = {
        enable = true;
        id = "testB";
        lairId = "testB";
        package = holonix-0_4.packages.${system}.holochain;
        deviceSeed = "test";
        keystorePassphrase = "passwordB";
        config = {
          admin_interfaces = [
            {
              driver = {
                type = "websocket";
                port = 8002;
                allowed_origins = "*";
              };
            }
          ];
        };
      };

      system.stateVersion = "24.11";
    };
  };

  # https://nixos.org/manual/nixos/stable/index.html#ssec-machine-objects
  testScript = builtins.readFile ./holochain-0_4-with-lair.py;
}
