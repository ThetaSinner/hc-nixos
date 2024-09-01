{ lib, config, pkgs, ... }:

with lib;

let
  # The input config for this service
  cfg = config.services.conductor;
in
{
  options.services.conductor = {
    enable = mkEnableOption "Holochain conductor";

    package = lib.mkOption {
      description = "conductor package to use";
      type = lib.types.package;
    };

    deviceSeed = mkOption { type = types.str; };

    keystorePassphrase = mkOption { type = types.str; };

    config = mkOption {
      type = types.anything;
      default = { };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.conductor = {
      wantedBy = [ "multi-user.target" ]; # Start on boot
      after = [
        "network.target"
        "lair-keystore.service"
      ]; # Waits for if started at the same time
      bindsTo = [ "lair-keystore.service" ]; # Requires Lair, stop if Lair stops
      description = "Holochain conductor";
      path = [ cfg.package pkgs.yq ];
      restartIfChanged = true;

      environment = {
        RUST_LOG = "info,wasmer_compiler_cranelift=warn";
        RUST_BACKTRACE = "1";
        # HOLOCHAIN_MIGRATE_UNENCRYPTED="true";
      };

      # TODO should be able to pass this to Holochain as an arg rather than needing to modify the file
      preStart = ''
        lair_connection_url=$(yq -r .connectionUrl /var/lib/lair/lair-keystore-config.yaml)
        yq -y "(.keystore.connection_url) = \"$lair_connection_url\"" /etc/holochain/conductor.yaml > /var/lib/conductor/conductor.yaml
      '';

      script = ''
        echo -n "${cfg.keystorePassphrase}" | holochain -c /var/lib/conductor/conductor.yaml --piped
      '';

      serviceConfig = {
        User = "conductor";
        Group = "holochain";
        StateDirectory = "conductor";
        StateDirectoryMode = "0755";
        Restart = "always";
        RestartSec = 1;
        Type = "notify";
        NotifyAccess = "all";
      };
    };

    environment.etc."holochain/conductor.yaml".source =
      (pkgs.formats.yaml { }).generate "conductor.yaml" ({
        data_root_path = "/var/lib/conductor";
        db_sync_strategy = "Fast";
        admin_interfaces = [{
          driver = {
            type = "websocket";
            port = 8000;
            allowed_origins = "*";
          };
        }];
        network = {
          network_type = "quic_bootstrap";
          bootstrap_service = "https://bootstrap.holo.host";
          transport_pool = [{
            type = "webrtc";
            signal_url = "wss://sbd.holo.host";
          }];
          tuning_params = { gossip_strategy = "sharded-gossip"; };
        };
        dpki = {
          device_seed_lair_tag = cfg.deviceSeed;
          # no_dpki = true;
        };
      } // cfg.config // {
        keystore.type = "lair_server";
      });
  };
}
