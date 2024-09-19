# Holochain for NixOS

## To-Do List

1. ~~Separate my settings from other settings in `configuration.nix`.~~
2. Allow Holochain to take the Lair URL as a CLI flag so the conductor configuration can be static.

### Consume the NixOS modules exported by this flake

You'll need to configure your NixOS installation to use flakes, if you haven't already. Then you can add this flake
as an input. Something like:

```nix
{
    inputs = {
        # ...
        hc-nixos.url = "github:ThetaSinner/hc-nixos";
        # ...
    };
}
```

This flake attempts to provide Holochain for its upcoming and stable releases. Currently, this would be the 0.4 
development versions and the stable 0.3 version.

There isn't necessarily a migration path between minor versions of Holochain, so please refer to Holochain documentation
when upgrading. Just changing the version that you are consuming from this flake is unlikely to work.

For Holochain 0.4 onwards, before you can get started, you will need a seed bundle for DPKI. You can use the CLI provided
by this project to generate one. For example:

```shell
nix develop -c node ./seed-tool/index.js generate --out root.bundle
# Provide a password

nix develop -c node ./seed-tool/index.js derive --root root.bundle --out mymachine.bundle
# Provide the password from step 1 again
# Provide a password for this device bundle
````

Keep the `root.bundle` safe. It's the device bundle that you will need to deploy.

The following is a very rough, sample flake. It will get you up and running but you likely want to make improvements.

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=24.05";
    hc-nixos = {
      url = "github:ThetaSinner/hc-nixos?ref=rework";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, hc-nixos }: {
    nixosConfigurations.nuc = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        hc-nixos.nixosModules.hcCommon # Adds groups and users
        hc-nixos.nixosModules.lair-keystore-0_5 # Define the Lair service
        hc-nixos.nixosModules.conductor-0_4 # Define the Conductor service
        ({ pkgs, ... }: {
          environment.etc."lair-myMachine/device.bundle".text = "<contents of mymachine.bundle>";

          services.lair-keystore-0_5 = {
            enable = true;
            id = "lair-05";
            package = hc-nixos.inputs.holonix-0_4.packages.x86_64-linux.lair-keystore;
            passphrase = "pass"; # Secret, conductor must launch with the same phrase
            deviceSeed = "myMachine-seed"; # Not secret, just a name
            seedPassphrase = "<chosen in step 2 above>"; # Secret
          };

          services.conductor-0_4 = {
            enable = true;
            id = "conductor-04";
            lairId = "lair-05";
            package = hc-nixos.inputs.holonix-0_4.packages.x86_64-linux.holochain;
            keystorePassphrase = "pass"; # Secret, see Lair
            deviceSeed = "myMachine-seed"; # Not secret, see Lair
          };

          # Include the Holochain tools and sqlcipher which can be useful for debugging or fixing corrupted sqlite databases etc.
          environment.systemPackages = [
            hc-nixos.inputs.holonix-0_4.packages.x86_64-linux.holochain
          ] ++ (with pkgs; [
            sqlcipher
          ]);
        })
      ];
    };
};
}
```

You shouldn't need to make any changes in your `configuration.nix` file. At this point you should be able to test with

```shell
sudo nixos-rebuild switch test
```

If both the Lair and Conductor services come up without errors then you can test with:

```
hc sandbox -f 8000 call list-cells
```

This should print out a single line which contains a DnaHash and AgentPubKey for DPKI. If all is well, you can switch 
to the new configuration:

```shell
sudo nixos-rebuild switch
```

### Other ways of running Holochain

You are free to override the configuration, run with an embedded Lair keystore or even run multiple Holochain versions
side by side. I've started adding NixOS tests to demonstrate some different ways of running Holochain and showing how
to configure it. You may use the tests under `tests` as a reference if you want some hints on how to do this.

Please note that the tests are not intended to be secure or production ready. They are just a way to demonstrate how
to configure Holochain in different ways. It's left to you to ensure that your Holochain configuration is appropriate
for your use case.

### Testing interactively with a VM

To boot up a VM and see Holochain running, you can use the following command:

```shell
nix run .#vm-0_4
```

Then you will be able to check the state of the system. For example:

```shell
systemctl status conductor-0_4
```

### Run the tests

```shell
nix flake check --all-systems
```
