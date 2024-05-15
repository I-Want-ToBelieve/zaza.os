{
  inputs,
  pkgs,
  ...
}: {
  home.file.".ssh/config".text = ''
    UserKnownHostsFile ~/.ssh/known_hosts

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
        HostName github.com
        PreferredAuthentications publickey
        IdentityFile ~/.ssh/github_id_rsa
    # gitee
    Host gitee.com
        HostName gitee.com
        PreferredAuthentications publickey
        IdentityFile ~/.ssh/gitee_id_rsa
    # Host github.com
    #     HostName github.com
    #     Port 8022
    #     PreferredAuthentications publickey
    #     IdentityFile ~/.ssh/xiaomi_lite_id_rsa
  '';
}
