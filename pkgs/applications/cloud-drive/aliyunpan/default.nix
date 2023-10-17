{ lib, buildGoModule, sources, }:
let inherit (sources.aliyunpan) pname src version;
in buildGoModule {
  inherit pname src version;

  vendorHash = "sha256-GHM0hjertif31T779/a1sTtailp9OyMtkayJy+ZCNgo=";

  proxyVendor = true;
  doCheck = false;

  tags = "-trimpath -buildmode=pie -mod=readonly -modcacherw";

  ldflags = [ "-s" "-w" "-X main.Version=${version}" ];

  meta = with lib; {
    description = "阿里云盘命令行客户端，支持webdav文件服务，支持JavaScript插件，支持同步备份功能。";
    homepage = "https://github.com/tickstep/aliyunpan";
    # @see https://github.com/NixOS/nixpkgs/blob/master/lib/licenses.nix
    license = licenses.asl20;
  };
}
