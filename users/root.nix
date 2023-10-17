{ pkgs, ... }:
# recommend using `hashedPassword`
{
  users.users.root = {
    shell = pkgs.fish;
    hashedPassword =
      "$y$j9T$7aFeajtXgLfIBe98JlZ57.$f3MvxM4JdrSjGUV3Bbobe2pRQoPY5taFO1w8/JgoRH9";
    initialPassword = "nixos";
  };
}
