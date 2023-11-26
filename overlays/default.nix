final: prev: {
  skhd =
    prev.skhd.overrideAttrs (finalAttrs: previousAttrs: {
    });
  # yabai = prev.yabai.overrideAttrs (finalAttrs: previousAttrs: rec {
  #   version = "master";

  #   src = prev.fetchFromGitHub {
  #     owner = "koekeishiya";
  #     repo = "yabai";
  #     rev = version;
  #     hash = "sha256-G7yjxhKk5Yz6qLHy8I8MMmZdVYUggGVvIW0j5kdkwlo=";
  #   };
  # });
}
