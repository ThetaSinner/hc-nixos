### Linux builder for MacOS users

Make sure you have permissions by adding to `/etc/nix/nix.conf`:

```shell
extra-trusted-users = root <your username goes here>
```

Start a bootstrap builder

```shell
nix run nixpkgs#darwin.linux-builder
```

Configure your Nix client to use the builder by adding to `~/.config/nix/nix.conf`:

```shell
# - Replace ${ARCH} with either aarch64 or x86_64 to match your host machine
# - Replace ${MAX_JOBS} with the maximum number of builds (pick 4 if you're not sure)
builders = ssh-ng://builder@linux-builder ${ARCH}-linux /etc/nix/builder_ed25519 ${MAX_JOBS} - - - c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUpCV2N4Yi9CbGFxdDFhdU90RStGOFFVV3JVb3RpQzVxQkorVXVFV2RWQ2Igcm9vdEBuaXhvcwo=

# Not strictly necessary, but this will reduce your disk utilization
builders-use-substitutes = true
```

Make SSH easy by adding to `/etc/ssh/ssh_config.d/100-linux-builder.conf`:

```text
Host linux-builder
  Hostname localhost
  HostKeyAlias linux-builder
  Port 31022
```

Reconfigure your Nix daemon:

```shell
sudo launchctl kickstart -k system/org.nixos.nix-daemon
```

That's the bootstrap prepared, Now you can set up your system with the flake.

Make sure your user is listed in the `flake.nix`:

```nix
# ...
{
  nix.settings.trusted-users = [ "root" "thetasinner" ];
}
# ...
```

Comment out the `virtualisation.darwin-builder.*` settings in `flake.nix` following the comments provided:

```nix
# ...
{
  # darwin-builder.diskSize = 5120;
  # darwin-builder.memorySize = 4 * 1024;
}
# ...
```

Now you can run the flake to configure your system:

```shell
nix run nix-darwin -- switch --flake .#builder
```

Then this configures a different port, so update `/etc/ssh/ssh_config.d/100-linux-builder.conf`:

```text
Host linux-builder
  Hostname localhost
  HostKeyAlias linux-builder
  Port 22
```

Comment back in the `virtualisation.darwin-builder.*` settings in `flake.nix`:

```nix
# ...
{
  darwin-builder.diskSize = 5120;
  darwin-builder.memorySize = 4 * 1024;
}
# ...
```

Finally, use the builder to update itself with the new settings:

```shell
nix run nix-darwin -- switch --flake .#builder
```
