{
  lib,
  config,
  pkgs,
  trycp-server,
  holochain,
  lair-keystore,
  ...
}:
with lib; let
  # The input config for this service
  cfg = config.services.trycp-server;
in {
  options.services.trycp-server = {
    enable = mkEnableOption "TryCP Server";

    port = mkOption {
      type = types.int;
      default = 9000;
      description = "The port the TryCP server will listen on";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.trycp-server = {
      wantedBy = ["multi-user.target"]; # Start on boot
      description = "TryCP Server";
      path = [trycp-server holochain lair-keystore];
      restartIfChanged = true;

      environment = {RUST_LOG = "warn";};

      serviceConfig = {
        User = "trycp";
        Group = "holochain";
        StateDirectory = "trycp";
        StateDirectoryMode = "0755";
        ExecStart = ''
          ${trycp-server}/bin/trycp_server --port ${toString cfg.port}
        '';
      };
    };
  };
}
