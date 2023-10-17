{ rustPlatform, makeWrapper, pkg-config, udev, sources, }:
let inherit (sources.swhkd) pname src version cargoLock;
in rustPlatform.buildRustPackage {
  inherit pname src version;

  cargoLock = cargoLock."Cargo.lock";

  # @see https://github.com/waycrate/swhkd/blob/2e6f091817be5f6ebf837f8fc1cdf1e54f0b3526/flake.nix#L21
  nativeBuildInputs = [ makeWrapper pkg-config ];

  # @see https://discourse.nixos.org/t/solved-libudev-replaced-by-udev/18951/2
  buildInputs = [ udev ];

  postBuild = ''
    ./scripts/build-polkit-policy.sh \
    --policy-path=com.github.swhkd.pkexec.policy \
    --swhkd-path=/usr/bin/swhkd
  '';

  postInstall = ''
    install -D -m0444 -t "$out/share/polkit-1/actions" ./com.github.swhkd.pkexec.policy

    substituteInPlace "$out/share/polkit-1/actions/com.github.swhkd.pkexec.policy" \
      --replace /usr/bin/swhkd \
        "$out/bin/swhkd"
  '';
}
