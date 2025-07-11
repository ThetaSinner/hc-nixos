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
  cfg = config.services.conductor-0_4;

  keystore_type = (cfg.config.keystore or {}).type or "lair_server";
in {
  options.services.conductor-0_4 = {
    enable = mkEnableOption "Holochain conductor";

    id = mkOption {
      description = "The ID of the conductor, keeping it separate from other conductors";
      type = types.str;
    };

    lairId = mkOption {
      description = "The ID of the lair-keystore service to use";
      type = types.str;
    };

    package = lib.mkOption {
      description = "conductor package to use";
      type = lib.types.package;
    };

    keystorePassphrase = mkOption {
      description = "The passphrase for Lair";
      type = types.str;
    };

    config = mkOption {
      type = types.anything;
      default = {};
    };
  };

  config = mkIf cfg.enable {
    systemd.services.conductor-0_4 = {
      wantedBy = ["multi-user.target"]; # Start on boot
      after =
        [
          # Wait for the network to be ready before starting this service
          "network.target"
        ]
        ++ (
          if keystore_type == "lair_server"
          then [
            # When Lair is running as a separate service, wait for it to start
            "lair-keystore-for-0_4.service"
          ]
          else []
        );
      bindsTo =
        if keystore_type == "lair_server"
        then [
          # When Lair us running as a separate service, require Lair to be running, stop if Lair stops
          "lair-keystore-for-0_4.service"
        ]
        else [];
      description = "Holochain conductor";
      path = [cfg.package pkgs.yq];
      restartIfChanged = true;

      environment = {
        RUST_LOG = "info,wasmer_compiler_cranelift=warn";
        RUST_BACKTRACE = "1";
        # HOLOCHAIN_MIGRATE_UNENCRYPTED="true";
      };

      # TODO should be able to pass this to Holochain as an arg rather than needing to modify the file
      preStart =
        if keystore_type == "lair_server"
        then ''
          lair_connection_url=$(yq -r .connectionUrl /var/lib/lair-${cfg.lairId}/lair-keystore-config.yaml)
          yq -y "(.keystore.connection_url) = \"$lair_connection_url\"" /etc/holochain-${cfg.id}/conductor.yaml > /var/lib/conductor-${cfg.id}/conductor.yaml
        ''
        else ''
          if test -f "/var/lib/conductor-${cfg.id}/conductor.yaml"; then
            chmod 0644 /var/lib/conductor-${cfg.id}/conductor.yaml
          fi
          cp /etc/holochain-${cfg.id}/conductor.yaml /var/lib/conductor-${cfg.id}/conductor.yaml
        '';

      script = ''
        echo -n "${cfg.keystorePassphrase}" | holochain -c /var/lib/conductor-${cfg.id}/conductor.yaml --piped
      '';

      serviceConfig = {
        User = "conductor";
        Group = "holochain";
        StateDirectory = "conductor-${cfg.id}";
        StateDirectoryMode = "0755";
        Restart = "always";
        RestartSec = 1;
        Type = "notify"; # The conductor sends a notify signal to systemd when it is ready
        NotifyAccess = "all";
      };
    };

    environment.etc."holochain-${cfg.id}/conductor.yaml".source = (pkgs.formats.yaml {}).generate "conductor.yaml" ({
        data_root_path = "/var/lib/conductor-${cfg.id}";
        db_sync_strategy = "Resilient";
        admin_interfaces = [
          {
            driver = {
              type = "websocket";
              port = 8000;
              allowed_origins = "*";
            };
          }
        ];
        network = {
          network_type = "quic_bootstrap";
          bootstrap_service = "https://bootstrap.holo.host";
          transport_pool = [
            {
              type = "webrtc";
              signal_url = "wss://sbd.holo.host";
            }
          ];
          tuning_params = {
            gossip_strategy = "sharded-gossip";
            arc_clamping = "full";
          };
        };
        dpki = {
          no_dpki = true;
          network_seed = "deepkey-main";
        };
        keystore =
          {
            type = keystore_type;
          }
          // (
            if keystore_type == "lair_server_in_proc"
            then {
              lair_root = "/var/lib/conductor-${cfg.id}/keystore/";
            }
            else {}
          );
      }
      // cfg.config);
  };
}
