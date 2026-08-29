# clan vars 骨架 —— 取代本仓库至今为止「等于没有」的密钥管理。
#
# 现状（Phase 6 之前）：agenix 的 module 与 overlay 被 8 台主机全部导入，但
# secrets/secrets.nix 是公钥为空字符串的未填模板，仓库里没有任何 .age 文件，
# 每一处 age.secrets 用法都被注释掉了。真正在生效的是三个明文口令：
#   users/root.nix              initialPassword = lib.mkForce "nixos"
#   users/nixos.nix             initialPassword = lib.mkForce "nixos"
#   users/i.want.to.believe.nix initialPassword = "nixos"
#
# 下面的 generator 声明是**惰性**的：它们本身可以求值（已实测），但在你运行
# `clan vars generate` 之前不会产生任何文件。所以这个文件现在落地是安全的。
#
# 消费侧（hashedPasswordFile）刻意保持注释：在密钥生成之前打开它会让
# 用户无法登录。启用步骤见文件末尾。
{pkgs, ...}: let
  # 生成一个随机口令，并把它的 yescrypt 哈希一并产出。
  # share = false（默认）意味着每台机器拿到不同的口令 —— 这正是把十台教室机
  # 建成十个独立 clan machine 的意义之一。
  mkPasswordGenerator = user: {
    files."${user}-password" = {
      secret = true;
      deploy = false; # 明文口令只留在你的机器上，不下发到目标机
    };
    files."${user}-password-hash".secret = true;

    runtimeInputs = [pkgs.coreutils pkgs.mkpasswd];

    script = ''
      head -c 18 /dev/urandom | base64 | tr -d '\n' > "$out"/${user}-password
      mkpasswd -s -m yescrypt < "$out"/${user}-password > "$out"/${user}-password-hash
    '';
  };
in {
  clan.core.vars.generators = {
    user-password-root = mkPasswordGenerator "root";
    user-password-iwtb = mkPasswordGenerator "i.want.to.believe";
  };

  # ---------------------------------------------------------------------------
  # 启用步骤（需要你本人在场，我不接触私钥）
  #
  #   1. 一次性：生成你的 age 密钥，clan 会把它放进 ~/.config/sops/age/keys.txt
  #        clan vars keygen
  #
  #   2. 先只对一台机器生成，确认形状正确：
  #        clan vars generate k99-lite
  #        clan vars list k99-lite
  #        clan vars get  k99-lite user-password-root/root-password
  #
  #   3. clan 只认 git 已跟踪的文件，所以要把生成物加进索引：
  #        git add sops/ vars/
  #
  #   4. 确认无误后再对其余机器生成。
  #
  #   5. 最后才打开消费侧 —— 把下面两行取消注释，并删掉
  #      users/root.nix 与 users/i.want.to.believe.nix 里的 initialPassword：
  #
  #        users.users.root.hashedPasswordFile =
  #          config.clan.core.vars.generators.user-password-root.files."root-password-hash".path;
  #        users.users."i.want.to.believe".hashedPasswordFile =
  #          config.clan.core.vars.generators.user-password-iwtb.files."i.want.to.believe-password-hash".path;
  #
  #      注意 users.mutableUsers = true（users/i.want.to.believe.nix）与
  #      hashedPasswordFile 同时存在时，每次 rebuild 都会把口令改回文件里的值，
  #      本机上手工改的密码会被覆盖。对教室机这是想要的行为，对个人机未必。
  #
  # 未纳入的一项，且**不能**用 vars 修：
  #   services.rkvm.client.settings.password 的类型是 types.str，没有
  #   passwordFile 对应项，所以任何值都会被渲染进全局可读的 nix store。
  #   指向 vars 也解决不了。当前三处明文 "0123456789" 在
  #   hosts/nixos/xiaoxin-pro{14,16}-2021.nix，属于个人机问题，
  #   不阻塞机群迁移。真正的解法是弃用 rkvm。
  # ---------------------------------------------------------------------------
}
