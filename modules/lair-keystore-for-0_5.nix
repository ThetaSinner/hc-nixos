/*
* Copyright 2024 - 2025 ThetaSinner. All rights reserved.
*
* This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
* This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
* You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.
*/
{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  # The input config for this service
  cfg = config.services.lair-keystore-for-0_5;
in {
  options.services.lair-keystore-for-0_5 = {
    enable = mkEnableOption "Lair keystore";

    id = mkOption {
      description = "The ID of the keystore, keeping it separate from other keystores";
      type = types.str;
    };

    package = lib.mkOption {
      description = "lair-keystore package to use";
      type = lib.types.package;
    };

    passphrase = mkOption {type = types.str;};
  };

  config = mkIf cfg.enable {
    systemd.services.lair-keystore-for-0_5 = {
      wantedBy = ["multi-user.target"]; # Start on boot
      description = "Lair keystore for Holochain 0.5";
      path = [cfg.package];
      restartIfChanged = true;

      environment = {
        LAIR_ROOT = "/var/lib/lair-${cfg.id}/";
        # LAIR_MIGRATE_UNENCRYPTED="true";
      };

      preStart = ''
        if test -f "''${LAIR_ROOT}lair-keystore-config.yaml"; then
          echo "Lair is already initialised, skipping init"
          exit 0
        fi

        mkdir -p "''${LAIR_ROOT}"
        echo -n "${cfg.passphrase}" | lair-keystore --lair-root $LAIR_ROOT init --piped

        cat "''${LAIR_ROOT}lair-keystore-config.yaml"
        if ! test -f "''${LAIR_ROOT}lair-keystore-config.yaml"; then
          echo "Either lair failed to initialise or has changed its config file name"
          ls -al $LAIR_ROOT
          exit 1
        fi

        echo "Lair initialised"
      '';

      script = ''
        lair-keystore --version
        echo -n "${cfg.passphrase}" | lair-keystore --lair-root $LAIR_ROOT server --piped
      '';

      serviceConfig = {
        User = "conductor";
        Group = "holochain";
        StateDirectory = "lair-${cfg.id}";
        StateDirectoryMode = "0755";
      };
    };
  };
}
