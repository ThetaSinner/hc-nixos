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
  cfg = config.services.k2-server-0_6;
in {
  options.services.k2-server-0_6 = {
    enable = mkEnableOption "Kitsune2 bootstrap/signal server";

    package = lib.mkOption {
      description = "kitsune2 server package to use";
      type = lib.types.package;
    };

    config = mkOption {
      type = types.anything;
      default = {};
    };
  };

  config = mkIf cfg.enable {
    systemd.services.k2-server-0_6 = {
      wantedBy = ["multi-user.target"]; # Start on boot
      after = [
        # Wait for the network to be ready before starting this service
        "network.target"
      ];
      description = "Kitsune2 bootstrap/signal server";
      path = [cfg.package];
      restartIfChanged = true;

      environment = {
        RUST_LOG = "info";
        RUST_BACKTRACE = "1";
      };

      script = ''
        kitsune2-bootstrap-srv \
          --production \
          --listen \
          "[::]:${toString cfg.config.port}" \
      '';

      serviceConfig = {
        User = "k2server";
        Group = "holochain";
        Restart = "always";
        RestartSec = 1;
      };
    };
  };
}
