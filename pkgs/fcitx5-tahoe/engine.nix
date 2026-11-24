{fcitx5}:
fcitx5.overrideAttrs (old: {
  patches = (old.patches or []) ++ [./candidate-grid.patch];
  passthru = (old.passthru or {}) // {tahoeCandidateGrid = true;};
})
