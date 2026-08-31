_final: prev: let
  # nvfetcher 生成的源集合。
  #
  # 绝不能把它作为 `sources` 暴露在 nixpkgs 顶层：callPackage 会按名字自动注入，
  # 于是任何带 `sources` 参数的上游包都会拿到这一份，顶替掉它自己的 ./sources.nix。
  # 实测 pkgs.dart 就是这样被打破的（dart/default.nix 的 `sources ? import ./sources.nix`
  # 被顶替后报 "attribute 'versionUsed' missing"）。在裸 nixpkgs 上 dart 正常。
  # 所以这里只作为 let 绑定，显式传给需要它的本地包。
  sources = prev.callPackage (import ./_sources/generated.nix) {};
in {
  mpv-iptvplus =
    prev.callPackage ./applications/video/mpv/scripts/mpv-iptvplus.nix {inherit sources;};

  gtk3-nocsd = prev.callPackage ./development/libraries/gtk3-nocsd.nix {inherit sources;};
}
