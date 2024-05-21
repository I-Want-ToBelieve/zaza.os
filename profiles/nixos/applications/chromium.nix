{
  pkgs,
  lib,
  ...
}: {
  programs.chromium = {
    enable = true;
    extensions = [
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
          "toplevel_name" = "My managed bookmarks folder";
        }
        {
          "name" = "Google";
          "url" = "google.com";
        }
        {
          "name" = "Youtube";
          "url" = "youtube.com";
        }
        {
          "children" = [
            {
              "name" = "Chromium";
              "url" = "chromium.org";
            }
            {
              "name" = "Chromium Developers";
              "url" = "dev.chromium.org";
            }
          ];
          "name" = "Chrome links";
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
