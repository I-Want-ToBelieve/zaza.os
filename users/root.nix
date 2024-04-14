{pkgs, ...}:
# recommend using `hashedPassword`
{
  users.users.root = {
    shell = pkgs.fish;
    initialPassword = "nixos";
  };
}
