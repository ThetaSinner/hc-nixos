{ self, ... }: {
  name = "Startup test";

  nodes = {
    machine = { pkgs, ... }: {
      imports = [
        self.outputs.nixosModules.conductor
      ];

      services.conductor = {
        enable = true;
        keystorePassphrase = "password";
      };

      system.stateVersion = "24.04";
    };
  };

  # https://nixos.org/manual/nixos/stable/index.html#ssec-machine-objects
  testScript = ''
    machine.wait_for_unit("default.target")
    machine.succeed("systemctl status conductor | grep 'Status: \"Running\"'")
  '';
}
