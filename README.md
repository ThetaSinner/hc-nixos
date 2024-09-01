# Holochain for NixOS

## To-Do List

1. Separate my settings from other settings in `configuration.nix`.
2. Allow Holochain to take the Lair URL as a CLI flag so the conductor configuration can be static.

### Testing interactively with a VM

```shell
nix run .#vm
```

Then you will be able to check the state of the system. For example:

```shell
systemctl status conductor
```

### Run the tests

```shell
nix flake check --all-systems
```
