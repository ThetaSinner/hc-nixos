{ lib, config, pkgs, ... }:

with lib;

let
  # The input config for this service
  cfg = config.services.lair-keystore;
in
{
  options.services.lair-keystore = {
    enable = mkEnableOption "Lair keystore";

    package = lib.mkOption {
      description = "lair-keystore package to use";
      type = lib.types.package;
    };

    passphrase = mkOption { type = types.str; };
  };

  config = mkIf cfg.enable {
    systemd.services.lair-keystore = {
      wantedBy = [ "multi-user.target" ]; # Start on boot
      description = "Lair keystore";
      path = [ cfg.package ];
      restartIfChanged = true;

      environment = {
        LAIR_ROOT = "/var/lib/lair/";
        # LAIR_MIGRATE_UNENCRYPTED="true";
      };

      preStart = ''
        if test -f "''${LAIR_ROOT}lair-keystore-config.yaml"; then
          echo "Lair is already initialised, skipping init"
          exit 0
        fi

        mkdir -p "$LAIR_ROOT"
        echo -n "${cfg.passphrase}" | lair-keystore --lair-root $LAIR_ROOT init --piped

        if ! test -f "\$\{LAIR_ROOT\}lair-keystore-config.yaml"; then
          echo "Either lair failed to initialise or has changed its config file name"
          ls -al $LAIR_ROOT
          exit 1
        fi
      '';

      script = ''
        lair-keystore --version
        echo -n "${cfg.passphrase}" | lair-keystore --lair-root $LAIR_ROOT server --piped
      '';

      serviceConfig = {
        User = "conductor";
        Group = "holochain";
        StateDirectory = "lair";
        StateDirectoryMode = "0755";
      };
    };
  };
}
