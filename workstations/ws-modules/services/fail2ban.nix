{ config, pkgs, ... }:
{
services = {
  fail2ban = {
    enable = true;
    ignoreIP = [ "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16" ];
    bantime = "24h";
    bantime-increment = {
      enable = true;
      formula = "ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)";
      maxtime = "1680h";
      overalljails = true;
    };
  };

};
}