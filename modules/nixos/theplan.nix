{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  options = {
    services.theplan = {
      studentEnable = options.mkEnableOption "the plan student service";
      effectorEnalbe = options.mkEnableOption "the plan effector service";
    };
  };

  config = mkIf config.services.theplan.studentEnable {
    environment.systemPackages = [];

    systemd.services.theplan-student = {
      unitConfig = {
        Description = "theplan-student service";
        Documentation = "";
        After = [
        ];
        Wants = ["network.target"];
      };

      serviceConfig = {
        User = "root";
        ExecStart = "${getExe pkgs.nodejs_20} --log-disable-timestamp";
        Environment = ["V2RAYA_LOG_FILE=/var/log/v2raya/v2raya.log"];
        LimitNPROC = 500;
        LimitNOFILE = 1000000;
        Restart = "on-failure";
        Type = "simple";
      };

      wantedBy = ["multi-user.target"];
      path = with pkgs; [iptables bash iproute2] ++ lib.optionals nftablesEnabled [nftables]; # required by v2rayA TProxy functionality
    };
  };

  meta.maintainers = with maintainers; [elliot];
}
