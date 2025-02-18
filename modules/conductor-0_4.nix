{
  lib,
  config,
  pkgs,
  ...
}:
with lib; let
  # The input config for this service
  cfg = config.services.conductor-0_4;
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

    deviceSeed = mkOption {type = types.str;};

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
      after = [
        "network.target"
        "lair-keystore-0_5.service"
      ]; # Waits for network and lair started
      bindsTo = ["lair-keystore-0_5.service"]; # Requires Lair, stop if Lair stops
      description = "Holochain conductor";
      path = [cfg.package pkgs.yq];
      restartIfChanged = true;

      environment = {
        RUST_LOG = "info,wasmer_compiler_cranelift=warn";
        RUST_BACKTRACE = "1";
        # HOLOCHAIN_MIGRATE_UNENCRYPTED="true";
      };

      # TODO should be able to pass this to Holochain as an arg rather than needing to modify the file
      preStart = ''
        lair_connection_url=$(yq -r .connectionUrl /var/lib/lair-${cfg.lairId}/lair-keystore-config.yaml)
        yq -y "(.keystore.connection_url) = \"$lair_connection_url\"" /etc/holochain-${cfg.id}/conductor.yaml > /var/lib/conductor-${cfg.id}/conductor.yaml
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
        device_seed_lair_tag = cfg.deviceSeed;
        dpki = {
          no_dpki = true;
          network_seed = "deepkey-main";
        };
      }
      // cfg.config
      // {
        keystore.type = "lair_server";
      });
  };
}
