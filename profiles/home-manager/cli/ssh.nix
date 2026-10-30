{pkgs, ...}: {
  home.file.".ssh/config".text = ''
    UserKnownHostsFile ~/.ssh/known_hosts
    StrictHostKeyChecking accept-new

    # gitlab localhost
    Host 127.0.0.1
        HostName 127.0.0.1
        Port 10022
        PreferredAuthentications publickey
        IdentityFile ~/.ssh/id_rsa_gitlab_localhost
    # gitlab
    Host gitlab.com
        HostName gitlab.com
        PreferredAuthentications publickey
        IdentityFile ~/.ssh/id_rsa_gitlab
    # gitlab private
    Host gitlab.maodouling.com
        HostName gitlab.maodouling.com
        Port 2224
        PreferredAuthentications publickey
        IdentityFile ~/.ssh/id_rsa
    # github
    Host github.com
        Hostname ssh.github.com
        Port 443
        PreferredAuthentications publickey
        IdentityFile ~/.ssh/github_id_rsa
    # gitee
    Host gitee.com
        HostName gitee.com
        PreferredAuthentications publickey
        IdentityFile ~/.ssh/gitee_id_rsa
    # 001macos
    Host 001macos
        Hostname 192.168.192.140
        Port 22
    # 001 生产服务器（AWS 新加坡）—— 公司规定必须走 socks5 192.168.6.9:1089（日常开发走 1084）
    # 连 192.168.6.9 本身属于局域网，Clash 规则里是 DIRECT，开着 TUN 也不会被再套一层 1084
    Host 13.250.26.87 52.220.141.164 sg-web-1 sg-web-2
        User ec2-user
        IdentityFile ~/.ssh/001-sg-web.pem
        IdentitiesOnly yes
        ProxyCommand ${pkgs.netcat}/bin/nc -X 5 -x 192.168.6.9:1089 %h %p
        ServerAliveInterval 30
    Host sg-web-1
        HostName 13.250.26.87
        HostKeyAlias 13.250.26.87
    Host sg-web-2
        HostName 52.220.141.164
        HostKeyAlias 52.220.141.164
    # Host github.com
    #     HostName github.com
    #     Port 8022
    #     PreferredAuthentications publickey
    #     IdentityFile ~/.ssh/xiaomi_lite_id_rsa
  '';
}
