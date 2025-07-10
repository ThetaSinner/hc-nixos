{
  self,
  system,
  holonix-0_4,
  holonix-0_5,
  holonix-0_6,
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
        self.outputs.nixosModules.lair-keystore-for-0_4
        self.outputs.nixosModules.lair-keystore-for-0_5
        self.outputs.nixosModules.lair-keystore-for-0_6
        self.outputs.nixosModules.conductor-0_4
        self.outputs.nixosModules.conductor-0_5
        self.outputs.nixosModules.conductor-0_6
      ];

      services.lair-keystore-for-0_4 = {
        enable = true;
        id = "testB";
        package = holonix-0_4.packages.${system}.lair-keystore;
        passphrase = "passwordB";
      };

      services.conductor-0_4 = {
        enable = true;
        id = "testB";
        lairId = "testB";
        package = holonix-0_4.packages.${system}.holochain;
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

      services.lair-keystore-for-0_5 = {
        enable = true;
        id = "testC";
        package = holonix-0_5.packages.${system}.lair-keystore;
        passphrase = "passwordC";
      };

      services.conductor-0_5 = {
        enable = true;
        id = "testC";
        lairId = "testC";
        package = holonix-0_5.packages.${system}.holochain;
        keystorePassphrase = "passwordC";
        config = {
          admin_interfaces = [
            {
              driver = {
                type = "websocket";
                port = 8003;
                allowed_origins = "*";
              };
            }
          ];
        };
      };

      services.lair-keystore-for-0_6 = {
        enable = true;
        id = "testD";
        package = holonix-0_6.packages.${system}.lair-keystore;
        passphrase = "passwordD";
      };

      services.conductor-0_6 = {
        enable = true;
        id = "testD";
        lairId = "testD";
        package = holonix-0_6.packages.${system}.holochain;
        keystorePassphrase = "passwordD";
        config = {
          admin_interfaces = [
            {
              driver = {
                type = "websocket";
                port = 8004;
                allowed_origins = "*";
              };
            }
          ];
        };
      };

      system.stateVersion = "25.05";
    };
  };

  # https://nixos.org/manual/nixos/stable/index.html#ssec-machine-objects
  testScript = builtins.readFile ./holochain-and-lair-side-by-side.py;
}
