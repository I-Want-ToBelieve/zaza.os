{ pkgs, ... }: ''
  #! /usr/bin/env bash
  #> Syntax: bash

  # Send to host

  [ -f "$1" ] && op="cat"
  ''${op:-echo} "''${@:-$(cat -)}" \
      | ${pkgs.curl}/bin/curl -sF file='@-' 'http://0x0.st' \
      | tee /dev/stderr \
      | tr -d '\n'      \
      | ${pkgs.wl-clipboard}/bin/wl-copy
''
