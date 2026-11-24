{pkgs}: let
  nodejs = pkgs.nodejs_24;
  pnpm = pkgs.pnpm_11.override {
    version = "11.22.0";
    hash = "sha256-V6l+byOj+v/AMVOk74x3CgVSYSuGQK6+Ob/dV1TQ69w=";
    nodejs-slim = nodejs;
  };
in {
  inherit nodejs pnpm;
}
