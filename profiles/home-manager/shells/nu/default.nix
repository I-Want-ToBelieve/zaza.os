{ ... }: {
  programs.nushell = {
    enable = true;
    configFile = { source = ./config.nu; };
    envFile = { source = ./env.nu; };
    loginFile = { source = ./login.nu; };
    extraConfig = "";
    extraEnv = "";
    extraLogin = "";
    shellAliases = { };
    environmentVariables = { };
  };
}
