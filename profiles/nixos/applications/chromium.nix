{
  pkgs,
  lib,
  ...
}: {
  programs.chromium = {
    enable = true;
    extensions = [
      # "jinjaccalgkegednnccohejagnlnfdag" # violentmonkey
      # "gjldcdngmdknpinoemndlidpcabkggco" # Extensions Manager
    ];
    # https://chromeenterprise.google/policies/
    extraOpts = {
      # homepage
      "HomepageLocation" = "https://www.makcoocode.com/";
      "HomepageIsNewTabPage" = false;

      # new page
      "NewTabPageLocation" = "https://cn.bing.com/";

      # bookmarks
      "ImportBookmarks" = false;
      "ManagedBookmarks" = [
        {
          "name" = "MakcooCode";
          "url" = "https://www.makcoocode.com/";
        }
        {
          "children" = [
            {
              "name" = "在线练习打字";
              "url" = "https://dazi.91xjr.com/";
            }
            {
              "name" = "Codeflow";
              "url" = "https://codeflow.biaoyansu.com/";
            }
            {
              "name" = "Qwerty";
              "url" = "https://qwerty.kaiyi.cool/";
            }
            {
              "name" = "Monkeytype";
              "url" = "https://monkeytype.com/";
            }
          ];
          "name" = "打字练习";
        }
      ];

      # password
      "PasswordManagerEnabled" = false;

      # onstartup
      # 5 = Open New Tab Page
      # 1 = Restore the last session
      # 4 = Open a list of URLs
      # 6 = Open a list of URLs and restore the last session
      "RestoreOnStartup" = 1;

      # search
      "DefaultSearchProviderName" = "bing";
      "DefaultSearchProviderSearchURL" = "https://cn.bing.com/search?q={searchTerms}";

      # sync

      "SyncDisabled" = true;
    };
  };
}
