{
  callPackage,
  mactahoeKdeSrc,
  mactahoeGtkSrc,
  mactahoeIconsSrc,
}: {
  kde = callPackage ./kde.nix {inherit mactahoeKdeSrc;};
  gtk = callPackage ./gtk.nix {inherit mactahoeGtkSrc;};
  icons = callPackage ./icons.nix {inherit mactahoeIconsSrc;};
}
