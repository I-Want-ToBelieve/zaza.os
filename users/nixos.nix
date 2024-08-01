{
  pkgs,
  lib,
  ...
}:
# recommend using `hashedPassword`
{
  users.users.nixos = {
    shell = pkgs.fish;
    initialPassword = lib.mkForce "nixos";
    openssh.authorizedKeys.keys = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCRJ0EFYpSiXT9S6J22i1RnlaYehpHf8TtU7vp8ho3dse4hw8H8y0LcFscWkaKgjDrXTHZq2S553+2ve4cGoJuCBv2Kka4VqIw62yOShOPuZP/wTfRoXlAcF8XLcHWoVDv8quzLxF+lNP6DkJFUf4/rApFs0wIIOwfgSxU5p9AIR2h02M14hEeQcva8M7R3/fK6uQInkqICLnZYljYGozTmzG2HScasIXZ7qnrPLWDn3SrWvEMBkgtKt26/ivkPR7yiN56o1BUaiR9eP25JSKGT+XkoDBAkh6UFnfw6OvQ2sFcxJHInyZUqmZRM6opM2vnlucpG8A3dCU7s5C8YTQrhVL1iHFGp/v7k4RMQbR8jOBX+wCDSsiV6kMkV1EEKaAdYEvNhREXVIL2tem2IKq/Ix269hoTeVA8Bv+I7/0FChompnklCrDrBjHB0/9BeYWnKNRGVwTetIQq4dYQ9UpCkeC8SsBEeyOCfQGnvtaHU3mgxju1lSC+71fQG2eOfEkU= thinkpad-t420s-root"];
  };
}
