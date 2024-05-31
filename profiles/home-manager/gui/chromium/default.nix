{pkgs, ...}: {
  programs.chromium = {
    enable = true;
    extensions = [
      {
        id = "jinjaccalgkegednnccohejagnlnfdag"; # violentmonkey
        crxPath = ./extensions/Violentmonkey.crx;
        version = "2.19.0";
      }

      {
        id = "gjldcdngmdknpinoemndlidpcabkggco"; # Extensions Manager
        crxPath = ./extensions/Extension-Manager.crx;
        version = "9.5.2";
      }
    ];
  };
}
