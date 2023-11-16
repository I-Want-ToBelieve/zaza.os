final: prev: {
  skhd =
    prev.skhd.overrideAttrs (finalAttrs: previousAttrs: {
    });
  yabai = prev.yabai.overrideAttrs (finalAttrs: previousAttrs: rec {
    version = "master";

    src = prev.fetchFromGitHub {
      owner = "koekeishiya";
      repo = "yabai";
      rev = version;
      hash = "sha256-P7edDnGBWHfmdC7TO0K4r8ySwpgeNXP5iIX1ifVHFfo=";
    };
  });
}
