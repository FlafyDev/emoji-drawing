self: {
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types mkIf;
  cfg = config.services.emojiDrawing;
  inherit (self.packages.${pkgs.stdenv.hostPlatform.system}) emoji-drawing-web emoji-drawing-server;
in {
  options.services.emojiDrawing = {
    enable = mkEnableOption "emojiDrawing";
    webPort = mkOption {
      type = types.int;
      default = 40002;
      description = "The port to run the emoji drawing website on";
    };
    serverPort = mkOption {
      type = types.int;
      default = 40003;
      description = "The port to run the emoji drawing server on";
    };
    dataDir = mkOption {
      type = types.str;
      default = "/var/lib/emoji-drawing";
      description = "The directory to store data in";
    };
    hostname = mkOption {
      type = types.str;
      default = "0.0.0.0";
      description = "The hostname to bind to";
    };
    user = mkOption {
      type = types.str;
      default = "emojidrawing";
      description = "User to run the service as";
    };
    createUser = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to create the user";
    };
  };

  config = mkIf cfg.enable {
    users = mkIf cfg.createUser {
      users.${cfg.user} = {
        description = "User for Emoji Drawing";
        createHome = true;
        isSystemUser = true;
        home = cfg.dataDir;
        group = cfg.user;
      };
      groups.${cfg.user} = {};
    };
    systemd.services.emoji-drawing = {
      after = ["network-online.target"];
      wantedBy = ["multi-user.target"];
      wants = ["network-online.target"];
      startLimitIntervalSec = 60;
      description = "Start Emoji Drawing";
      serviceConfig = {
        # username that systemd will look for; if it exists, it will start a service associated with that user
        User = cfg.user;
        # the command to execute when the service starts up
        ExecStart = pkgs.writeShellScript "emoji-drawing-exec-start" ''
          cd ${emoji-drawing-web}/
          ${pkgs.nodejs_20}/bin/npm run start -- -p ${toString cfg.webPort} --hostname ${cfg.hostname} &
          ${emoji-drawing-server}/bin/emoji-drawing-server -p ${toString cfg.serverPort} --data-dir ${cfg.dataDir} --host ${cfg.hostname}
        '';

        Environment = [
          "PATH=${lib.makeBinPath (with pkgs; [
            coreutils
            bashInteractive
            systemd
          ])}"
        ];
      };
    };
  };
}
